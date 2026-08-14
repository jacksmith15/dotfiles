/**
 * Compact Bash Tool - renders each bash tool call as a single line:
 *
 *   $ git status --short  0.3s
 *
 * Features:
 * - Live ticking timer while the command runs (`0.3s`), frozen on completion.
 * - Exit code in red on failure, `[truncated]` marker when output was cut.
 * - Full output available on demand with ctrl+o (`app.tools.expand`); the
 *   single line stays on top and the output is shown beneath it.
 * - renderShell: "self" drops pi's boxed shell (background box, vertical
 *   padding rows and the "N earlier lines" footer), so a call reads as one
 *   line instead of ~12.
 *
 * How the single line works: pi stacks the renderCall component and the
 * renderResult component. We render the line inside the renderCall component,
 * and in renderResult we reach back through the shared per-execution
 * `context.state`, rewrite that same Text instance with the final duration +
 * status, and return an empty component (Text with "" renders zero lines).
 *
 * Install: place in ~/.pi/agent/extensions/ (auto-discovered, /reload-able)
 * or run: pi -e ./compact-bash.ts
 */

import { watch, type FSWatcher } from "node:fs";
import { join } from "node:path";
import type { BashToolDetails, ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import {
	CONFIG_DIR_NAME,
	createBashToolDefinition,
	getAgentDir,
	SettingsManager,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

interface BashCallArgs {
	command?: string;
	timeout?: number;
}

interface BashRenderState {
	startedAt?: number;
	ticker?: ReturnType<typeof setInterval>;
	line?: Text;
}

function formatDuration(ms: number): string {
	if (ms < 1000) return `${(ms / 1000).toFixed(1)}s`;
	const s = ms / 1000;
	if (s < 60) return `${s.toFixed(1)}s`;
	const m = Math.floor(s / 60);
	return `${m}m${Math.round(s % 60)}s`;
}

/** Collapsed-view preview: collapse the command to one line and truncate. */
function commandDisplay(cmd: string): string {
	const oneLine = cmd.replace(/\s+/g, " ").trim();
	if (oneLine.length <= 100) return oneLine;
	return oneLine.slice(0, 97) + "...";
}

function firstText(content: readonly unknown[]): string {
	for (const block of content) {
		if (block && typeof block === "object" && "type" in block && block.type === "text") {
			const text = (block as { text?: string }).text;
			if (text) return text;
		}
	}
	return "";
}

function parseExit(output: string): number | null {
	const m = output.match(/exit code: (\d+)/);
	if (m) return parseInt(m[1], 10);
	return null;
}

function plainLine(args: BashCallArgs, elapsed: number, theme: Theme): string {
	const timeout = args.timeout ? ` (timeout ${args.timeout}s)` : "";
	return `${theme.bold("bash")} ${commandDisplay(args.command ?? "...")}${timeout}  ${formatDuration(elapsed)}`;
}

/**
 * Collapsed: the entire line is muted (easy to skim past; error exit codes
 * still get their own color via the status markers below). Expanded: richer
 * per-element colors.
 */
function baseLine(args: BashCallArgs, elapsed: number, theme: Theme, expanded: boolean): string {
	const text = plainLine(args, elapsed, theme);
	if (!expanded) return theme.fg("muted", text);
	// Expanded: full command, verbatim (multi-line scripts keep their shape).
	const cmd = (args.command ?? "...").trim();
	let colored = theme.fg("toolTitle", theme.bold("bash "));
	colored += theme.fg("accent", cmd);
	if (args.timeout) colored += theme.fg("dim", ` (timeout ${args.timeout}s)`);
	colored += theme.fg("dim", `  ${formatDuration(elapsed)}`);
	return colored;
}

/**
 * Background applied to the expanded block, matching pi's tool box states:
 * pending while streaming, success once done, error on failure.
 */
function toolBackground(theme: Theme, isPartial: boolean, isError: boolean): (text: string) => string {
	const token = isPartial ? "toolPendingBg" : isError ? "toolErrorBg" : "toolSuccessBg";
	return (text: string) => theme.bg(token, text);
}

interface ShellSettings {
	shellPath?: string;
	commandPrefix?: string;
}

function readShellSettings(settings: SettingsManager): ShellSettings {
	return {
		shellPath: settings.getShellPath(),
		commandPrefix: settings.getShellCommandPrefix(),
	};
}

/**
 * Track settings for the life of the session. Read `.value` freely — no I/O.
 *
 * Call before registering your own `session_start` handler: handlers fire in
 * registration order, and this one populates `.value`.
 *
 * Note: `.value` is only populated once `session_start` fires, which is after
 * the extension factory runs — so don't read it at module/factory top level.
 */
function watchSettings<T>(
	pi: ExtensionAPI,
	read: (settings: SettingsManager) => T,
	fallback: T,
): { readonly value: T } {
	const state = { value: fallback };
	const watchers: FSWatcher[] = [];
	let manager: SettingsManager | undefined;

	const close = () => {
		for (const w of watchers) w.close();
		watchers.length = 0;
	};

	pi.on("session_start", (_event, ctx) => {
		close();
		// Rebuild per session: /resume can enter a different cwd, and
		// projectTrusted is fixed at construction so reload() can't pick it up.
		manager = SettingsManager.create(ctx.cwd, getAgentDir(), {
			projectTrusted: ctx.isProjectTrusted(),
		});
		state.value = read(manager);

		for (const dir of [getAgentDir(), join(ctx.cwd, CONFIG_DIR_NAME)]) {
			try {
				// Watch the directory: `.pi/` is created lazily, and a directory
				// watch survives editors that write via rename.
				watchers.push(
					watch(dir, { persistent: false }, async (_event, filename) => {
						// proper-lockfile drops `settings.json.lock` beside the file
						// on every write; only the file itself should trigger a reload.
						if (filename !== "settings.json" || !manager) return;
						try {
							await manager.reload();
							state.value = read(manager);
						} catch {
							// Transient read/parse error: keep the previous value.
						}
					}),
				);
			} catch {
				// Directory doesn't exist yet.
			}
		}
	});

	pi.on("session_shutdown", close);

	return state;
}

export default function (pi: ExtensionAPI) {
	// Settings: populated on session_start, refreshed live on file changes.
	const settings = watchSettings(pi, readShellSettings, {});

	// Build the backing bash tool lazily, keyed on the settings that pi
	// would otherwise pass in at startup. Also handles /resume into a new cwd.
	// Using the ToolDefinition (not the AgentTool wrapper) keeps the full
	// execute signature so we can forward ctx for PI_* session env vars.
	type BashToolDef = ReturnType<typeof createBashToolDefinition>;
	let cached: { key: string; tool: BashToolDef } | undefined;
	const getBashTool = (cwd: string): BashToolDef => {
		const s = settings.value;
		const key = `${cwd}\u0000${s.shellPath ?? ""}\u0000${s.commandPrefix ?? ""}`;
		if (!cached || cached.key !== key) {
			cached = {
				key,
				tool: createBashToolDefinition(cwd, { shellPath: s.shellPath, commandPrefix: s.commandPrefix }),
			};
		}
		return cached.tool;
	};

	// Static description/parameters mirror pi's own bash definition.
	const template = createBashToolDefinition(process.cwd());

	pi.registerTool({
		name: "bash",
		label: "bash",
		description: template.description,
		parameters: template.parameters,
		renderShell: "self",

		async execute(toolCallId, params, signal, onUpdate, ctx) {
			// Forward ctx: the built-in bash uses it for PI_* session env vars.
			return getBashTool(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx);
		},

		renderCall(args, theme, context) {
			const state = (context.state ??= {}) as BashRenderState;
			const line = state.line ?? new Text("", 1, 0);
			state.line = line;

			if (state.startedAt === undefined) state.startedAt = Date.now();

			// Tick the timer while the call is pending. Brave the one edge
			// case: renderCall re-runs after a theme change post-completion,
			// so don't (re)start a ticker once the result is final.
			if (state.ticker === undefined && context.isPartial !== false) {
				state.ticker = setInterval(() => context.invalidate(), 100);
			}

			// renderCall re-runs on completion too (before renderResult), so
			// pass context.expanded for consistent styling.
			line.setText(baseLine(args, Date.now() - state.startedAt, theme, context.expanded));
			line.setCustomBgFn(
				context.expanded
					? toolBackground(theme, context.isPartial, context.isError)
					: undefined,
			);
			return line;
		},

		renderResult(result, { expanded, isPartial }, theme, context) {
			const state = (context.state ??= {}) as BashRenderState;
			if (state.startedAt === undefined) state.startedAt = Date.now();
			if (state.ticker !== undefined) {
				clearInterval(state.ticker);
				state.ticker = undefined;
			}

			const args = context.args as BashCallArgs;
			const line = state.line ?? new Text("", 1, 0);
			state.line = line;

			const elapsed = Date.now() - state.startedAt;
			const details = result.details as BashToolDetails | undefined;
			const output = firstText(result.content);
			const exit = parseExit(output);

			let text = baseLine(args, elapsed, theme, expanded);
			if (exit !== null && exit !== 0) {
				text += theme.fg("error", ` exit ${exit}`);
			} else if (context.isError) {
				text += theme.fg("error", " error");
			} else if (output.includes("killed")) {
				text += theme.fg("error", " killed");
			}
			if (details?.truncation?.truncated) {
				text += theme.fg("warning", " [truncated]");
			}

			if (expanded && output) {
				const lines = output.split("\n");
				const shown = lines.slice(0, 50);
				text += "\n" + shown.map((l) => theme.fg("muted", l)).join("\n");
				if (lines.length > 50) {
					text += theme.fg("muted", `\n... ${lines.length - 50} more lines`);
				}
			}

			line.setCustomBgFn(
				expanded ? toolBackground(theme, isPartial, context.isError) : undefined,
			);
			line.setText(text);
			// Empty component: the call line above already carries everything.
			return new Text("", 0, 0);
		},
	});
}
