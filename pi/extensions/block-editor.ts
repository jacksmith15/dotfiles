/**
 * Block Editor - renders the input bar as a solid block of background color
 * with no border, and half-height padding above/below the text.
 *
 * The built-in Editor draws a `─` row above and below the content and colors
 * them via the theme's border/thinking/bash tokens. Themes can only recolor
 * those rows, not remove them. This extension replaces the editor component
 * with a CustomEditor subclass that:
 *   - replaces the top `─` row with a row of `▄` (lower-half block) painted
 *     in the prompt bg, so only the BOTTOM half of that row is prompt bg
 *     (merging into the content) and the top half is the terminal default bg
 *     (merging into the messages area above).
 *   - replaces the bottom `─` row with `▀` (upper-half block) painted in the
 *     prompt bg, so only the TOP half is prompt bg (merging into content) and
 *     the bottom half is default (merging into the footer below).
 * The net effect: the prompt block visually extends only half a row above and
 * below the text instead of a full blank row each side — the padding reads as
 * half character height, and the whole bar is ~1 row shorter.
 *
 * Half-block glyphs take their fill color from the glyph FOREGROUND, but the
 * prompt color is a background theme token. We get the raw bg SGR via
 * Theme.getBgAnsi() and swap `48`->`38` (and `49`->`39`) to reuse it as fg.
 *
 * Trade-offs:
 *   - The border doubles as a thinking-level / bash-mode indicator (borderColor
 *     changes per thinking level and `!` prefix). Removing it loses that cue.
 *     If you want it back, tint BG_TOKEN by thinking level in render().
 *   - The editor cursor uses `\x1b[7m` (reverse video). Because content rows
 *     carry prompt bg, the inverted cursor cell resolves to default bg,
 *     producing a 1-cell "notch" in the block at the cursor. Pre-existing in
 *     the full-row version; more noticeable with tighter padding. Fix: rewrite
 *     the `\x1b[7m..\x1b[0m` segment to explicit cursor colors. Not done here.
 *   - Half-height padding only applies when NOT scrolled. When content
 *     overflows, the `↑/↓ N more` hint is shown on a full-bg row (readable).
 *
 * Manual testing (project-local, not wired to ~/.pi):
 *   pi --extension pi/extensions/block-editor.ts
 * or, once trusted/symlinked, drop into ~/.pi/agent/extensions/ and it
 * auto-loads (hot-reloadable via /reload).
 *
 * Tweakables:
 *   BG_TOKEN        - theme background token used for the block
 *   SCROLL_TOKEN    - theme fg token for the ↑/↓ scroll hint
 *   HALF_HEIGHT     - when true, pad with `▄`/`▀` half-blocks (half-row gap);
 *                     when false, pad with full blank bg rows (v1 behavior)
 */

import { CustomEditor, type ExtensionAPI, type Theme } from "@earendil-works/pi-coding-agent";
import { stripTerminalSequences, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// A theme BACKGROUND token (e.g. "userMessageBg"). Derived from Theme.getBgAnsi
// since ThemeBg isn't re-exported from the package root.
type BgToken = Parameters<Theme["getBgAnsi"]>[0];

// Theme tokens. Change these to recolor the block without editing logic.
const BG_TOKEN = "userMessageBg";
const SCROLL_TOKEN = "muted";
// Half-height padding via `▄` (top) / `▀` (bottom) half-blocks. Set false to
// fall back to full blank bg rows (the original solid-block behavior).
const HALF_HEIGHT = true;

// Extract the raw SGR prefix from a theme color function (e.g. theme.bg) by
// wrapping a sentinel and taking everything before it. Same trick the
// Markdown component uses for style prefixes.
function colorPrefix(colorFn: (text: string) => string): string {
  const sentinel = "\u0000";
  const wrapped = colorFn(sentinel);
  const idx = wrapped.indexOf(sentinel);
  return idx >= 0 ? wrapped.slice(0, idx) : "";
}

// Reuse a theme BACKGROUND token as a FOREGROUND SGR prefix. Half-block glyphs
// (`▄`/`▀`) draw their fill from the glyph foreground, but prompt bg is a bg
// token. Theme.getBgAnsi() returns e.g. `\x1b[48;2;r;g;bm` (or `\x1b[49m` for
// default); swapping 48->38 and 49->39 yields the same color as a fg SGR.
function bgAsFgPrefix(theme: Theme, token: BgToken): string {
  return theme
    .getBgAnsi(token)
    .replace(/\x1b\[48;/g, "\x1b[38;")
    .replace(/\x1b\[49m/g, "\x1b[39m");
}

// A full-width row of a half-block glyph painted in promptBg-as-fg, with the
// cell background left at default so the unfilled half shows the page bg.
// `ch` is `▄` for the top row (fill bottom half) or `▀` for the bottom (fill top).
function halfBlockRow(ch: string, width: number, fgPrefix: string): string {
  const n = Math.max(0, width);
  return `${fgPrefix}${ch.repeat(n)}\x1b[39m`;
}

// Does a rendered line look like one of the editor's horizontal border rows?
// Matches a plain `─` row and the `─── ↑ N more ────` scroll-indicator row.
// Content lines and SelectList (autocomplete) lines contain alphanumerics or
// punctuation like `()` / `>`, so they won't match.
function isBorderLine(stripped: string): boolean {
  if (/^─+\s*$/.test(stripped)) return true;
  if (/^───\s+[↑↓]\s+\d+\s+more[\s─]*$/.test(stripped)) return true;
  return false;
}

// Paint a line with a solid background, padding it to full width and
// re-applying the bg SGR after every full reset (`\x1b[0m` / `\x1b[m`) so the
// background survives inner resets (e.g. the reverse-video cursor cell).
function paintBg(line: string, width: number, bgPrefix: string): string {
  const pad = " ".repeat(Math.max(0, width - visibleWidth(line)));
  const reApplied = line.replace(/\x1b\[0?m/g, `\x1b[0m${bgPrefix}`);
  return `${bgPrefix}${reApplied}${pad}\x1b[0m`;
}

// Render the ↑/↓ scroll hint on the block background (no dashes).
function scrollHintLine(stripped: string, width: number, bgPrefix: string, fgPrefix: string): string {
  // `─── ↑ 3 more ──` -> `↑ 3 more`
  const match = /^───\s+([↑↓])\s+(\d+)\s+more/.exec(stripped);
  const hint = match ? `${match[1]} ${match[2]} more` : "";
  const padded = ` ${hint}`; // small left margin inside the block
  const visible = `${fgPrefix}${padded}`;
  return paintBg(visible, width, bgPrefix);
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    // Class is declared inside the handler so it closes over `ctx` and can
    // read the live theme (`ctx.ui.theme`) on every render for hot-reload.
    class BlockEditor extends CustomEditor {
      render(width: number): string[] {
        const lines = super.render(width);
        if (lines.length < 2) return lines;

        const theme = ctx.ui.theme;
        const bgPrefix = colorPrefix((s: string) => theme.bg(BG_TOKEN, s));
        const halfFgPrefix = bgAsFgPrefix(theme, BG_TOKEN);
        const fgPrefix = colorPrefix((s: string) => theme.fg(SCROLL_TOKEN, s));

        // Top border (index 0) -> half-block row (lower half filled), or
        // scroll hint on a full bg row if scrolled up.
        const topStripped = stripTerminalSequences(lines[0]!);
        if (isBorderLine(topStripped)) {
          lines[0] = /↑/.test(topStripped)
            ? scrollHintLine(topStripped, width, bgPrefix, fgPrefix)
            : HALF_HEIGHT
              ? halfBlockRow("▄", width, halfFgPrefix)
              : paintBg("", width, bgPrefix);
        }

        // Bottom border -> last border-pattern line in the array. Autocomplete
        // lines (if present) come after it and are non-border, so the last
        // border-pattern line is always the real bottom border.
        let bottomIdx = -1;
        for (let i = lines.length - 1; i >= 1; i--) {
          if (isBorderLine(stripTerminalSequences(lines[i]!))) {
            bottomIdx = i;
            break;
          }
        }
        if (bottomIdx !== -1) {
          const bStripped = stripTerminalSequences(lines[bottomIdx]!);
          lines[bottomIdx] = /↓/.test(bStripped)
            ? scrollHintLine(bStripped, width, bgPrefix, fgPrefix)
            : HALF_HEIGHT
              ? halfBlockRow("▀", width, halfFgPrefix)
              : paintBg("", width, bgPrefix);
        }

        // Paint the content lines (between top and bottom border) with the
        // block background. Autocomplete lines, if any, are left untouched so
        // their own selected-item styling is preserved.
        const start = 1;
        const end = bottomIdx !== -1 ? bottomIdx : lines.length;
        for (let i = start; i < end; i++) {
          lines[i] = paintBg(lines[i]!, width, bgPrefix);
        }

        // Guard: keep every line within the width budget.
        for (let i = 0; i < lines.length; i++) {
          if (visibleWidth(lines[i]!) > width) {
            lines[i] = truncateToWidth(lines[i]!, width, "");
          }
        }

        return lines;
      }
    }

    ctx.ui.setEditorComponent((tui, theme, kb) => new BlockEditor(tui, theme, kb));
  });
}
