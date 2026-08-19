/**
 * Explore Tool - delegates a read-only research task to a subagent that runs
 * *in this process*, so a broad sweep of greps/reads/bash calls costs the
 * parent session one tool result instead of twenty.
 *
 * Equivalent in spirit to Claude Code's / Cursor's `Explore`: the parent model
 * asks a question, the subagent fans out across the repo, and only its written
 * answer comes back into the parent context.
 *
 * How it works: `createAgentSession()` (the pi SDK, exported from the package
 * root) builds a second, fully independent AgentSession — own context window,
 * own model, own tool set — which we drive with a single `prompt()` call and
 * then throw away. That is the whole "subagent system": no process spawning, no
 * agent registry, no session plumbing.
 *
 * Isolation is deliberate and layered:
 *   - `SessionManager.inMemory()`  - nothing is written to ~/.pi/agent/sessions
 *   - `noExtensions` on the loader - your other extensions (including THIS one)
 *                                    are not loaded into the subagent
 *   - `tools` allowlist            - read-only built-ins only; also the reason
 *                                    the subagent cannot recurse into `explore`
 *   - soft time/call budgets      - bound a cheap model that gets stuck in a
 *                                    loop (see `EXPLORE_SOFT_TIMEOUT_MS`)
 *
 * Trade-offs worth knowing:
 *   - The subagent's tokens/cost do NOT appear in pi's footer (that only sums
 *     the parent session's entries). They are shown on the tool's own result
 *     line instead.
 *   - The budgets are soft. Hitting either the time or the call limit ends the
 *     *sweep*, then buys one tool-free turn for the subagent to write up what it
 *     already found - so a run that runs long still returns findings, flagged as
 *     incomplete, rather than nothing at all.
 *   - Compaction inside the subagent is handled by AgentSession itself; a run
 *     that overflows will compact rather than fail.
 *
 * Install: place in ~/.pi/agent/extensions/ (auto-discovered, /reload-able)
 * or run: pi -e ./explore.ts
 */

import type { AgentToolResult, ThinkingLevel } from "@earendil-works/pi-agent-core";
import {
  createAgentSession,
  DefaultResourceLoader,
  type ExtensionAPI,
  type ExtensionContext,
  getAgentDir,
  getMarkdownTheme,
  ModelRuntime,
  SessionManager,
  SettingsManager,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

// ---------------------------------------------------------------------------
// Tunables
// ---------------------------------------------------------------------------

/**
 * Model the subagent runs on. Set to `undefined` to inherit the parent
 * session's model. Falls back to the parent's model if this one is not in the
 * catalogue or has no configured auth.
 */
const EXPLORE_MODEL: { provider: string; id: string } | undefined = {
  provider: "openrouter",
  id: "deepseek/deepseek-v4-flash-0731",
};

/**
 * Thinking level for the subagent.
 *
 * Careful: this is clamped to the model's supported levels, and the clamp
 * searches UPWARDS first. The deepseek v4 family only supports off/high/xhigh,
 * so asking for "low" there silently gets you "high" - the opposite of cheap.
 * "off" is the only level that means "off" on every model.
 */
const EXPLORE_THINKING: ThinkingLevel = "medium";

/**
 * Tool allowlist for the subagent. Read-only by construction: no `edit`, no
 * `write`, and no `explore` (which is what prevents recursion).
 */
const EXPLORE_TOOLS = ["read", "grep", "find", "ls", "bash"];

/**
 * Budgets for the sweep. These are *soft*: on hitting either, the sweep is
 * aborted and the subagent gets one tool-free turn to write up what it already
 * found. That is worth far more than killing it outright, which discards a
 * context full of findings and hands the parent nothing.
 */
const EXPLORE_SOFT_TIMEOUT_MS = 90 * 1000;
const EXPLORE_MAX_CALLS = 12;

/**
 * Backstop for the wrap-up turn itself. Generous, because a wrap-up truncated
 * mid-sentence is the one outcome this whole mechanism exists to avoid - 45s was
 * measurably too tight on an exhaustive sweep.
 */
const EXPLORE_WRAP_UP_TIMEOUT_MS = 75 * 1000;

/** Include AGENTS.md / CLAUDE.md project context files in the subagent's prompt. */
const INCLUDE_CONTEXT_FILES = true;

/** Recent tool calls shown in the collapsed view while the subagent is working. */
const COLLAPSED_CALL_COUNT = 6;

/** Appended to pi's default system prompt for the subagent. */
const EXPLORE_SYSTEM_PROMPT = `
You are an exploration subagent. Another agent has given you a research question
about this codebase and cannot ask you follow-ups, so your final message is the
entire deliverable.

Searching:
- Start broad, then narrow. Stop as soon as you can answer: a good exploration is
  usually 3-8 tool calls, not 20, unless the question asks for an exhaustive sweep.
- You have a budget of about ${EXPLORE_MAX_CALLS} tool calls. As you approach it,
  stop searching and write up what you have. A partial answer that names its gaps
  is useful; being cut off mid-search is not.
- Read excerpts, not whole files. You are locating code, not reviewing it.
- grep and find skip anything in .gitignore, so they cannot see node_modules,
  build output or vendored code. Use bash (rg --no-ignore, or a direct path) when
  the answer may live there.
- Use bash for what the search tools cannot do: git history (git log, git log -S
  <symbol>, git blame, git show), counting (| wc -l, | sort | uniq -c), and
  symlink targets (readlink -f). rg, git and jq are available; fd is not.
- Never modify anything: no writes or output redirection, no rm, no package
  installs, and no git command that changes state (checkout, stash, reset,
  commit). Read-only inspection only.

Answering:
- Write for an agent that has none of your context and will never see your tool
  output. If it is not in your final message, it does not exist.
- Your first sentence must be the answer itself: no commentary about your own
  process ("I now have everything", "Let me compile the findings"), no preamble,
  no restating the question. If the honest answer is "it depends", say what it
  depends on in that first sentence.
- Give the answer once. Do not restate it as a summary section.
- Order: the direct answer, then the file:line locations supporting it, then
  anything surprising, contradictory or missing.
- Cite only what you actually read. If you are inferring from a name or a path
  rather than from code you saw, say so.
- Say plainly what you could not find and where you looked. A short answer that
  admits a gap beats a padded one.
- If the question has more than one reasonable reading, answer the most likely
  one and note the other in a line.
`.trim();

/**
 * Sent as a second turn when the sweep is cut short. The subagent's tools are
 * stripped before this runs, so it cannot resume searching however much it wants
 * to - which is what stops the wrap-up allowance being spent on another grep.
 */
const WRAP_UP_PROMPT = `
Stop searching - your search budget is spent and your tools have been removed.

Write your findings now, using only what you have already seen. Follow the
answering rules: the answer itself in the first sentence, then the file:line
locations, then what is missing. Be explicit about which parts of the question
you did not get to, so the caller knows what to re-ask.

Keep this short - a few hundred words. You are out of budget, so prioritise the
direct answer over completeness; an exhaustive listing that gets truncated
mid-sentence is worse than a brief one that lands.
`.trim();

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  return `${(count / 1000000).toFixed(1)}M`;
}

function formatDuration(ms: number): string {
  const s = ms / 1000;
  if (s < 60) return `${s.toFixed(1)}s`;
  const m = Math.floor(s / 60);
  return `${m}m${Math.round(s % 60)}s`;
}

function truncate(text: string, max: number): string {
  const oneLine = text.replace(/\s+/g, " ").trim();
  return oneLine.length <= max ? oneLine : `${oneLine.slice(0, max - 3)}...`;
}

/** One-line rendering of a subagent tool call, mirroring pi's built-in tools. */
function formatToolCall(name: string, args: Record<string, unknown>, theme: Theme): string {
  const path = (args.file_path ?? args.path ?? ".") as string;
  switch (name) {
    case "bash":
      return theme.fg("muted", "$ ") + theme.fg("toolOutput", truncate((args.command as string) ?? "...", 70));
    case "read":
      return theme.fg("muted", "read ") + theme.fg("accent", path);
    case "grep":
      return (
        theme.fg("muted", "grep ") +
        theme.fg("accent", `/${(args.pattern as string) ?? ""}/`) +
        theme.fg("dim", ` in ${path}`)
      );
    case "find":
      return (
        theme.fg("muted", "find ") +
        theme.fg("accent", (args.pattern as string) ?? "*") +
        theme.fg("dim", ` in ${path}`)
      );
    case "ls":
      return theme.fg("muted", "ls ") + theme.fg("accent", path);
    default:
      return theme.fg("accent", name) + theme.fg("dim", ` ${truncate(JSON.stringify(args), 50)}`);
  }
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ExploreCall {
  name: string;
  args: Record<string, unknown>;
}

interface ExploreUsage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  turns: number;
}

/**
 * "cut-short" means a soft budget fired and the findings below came from the
 * wrap-up turn; "timeout" means even that did not finish.
 */
type ExploreStatus = "running" | "wrapping-up" | "done" | "cut-short" | "timeout";

interface ExploreDetails {
  task: string;
  model: string | undefined;
  status: ExploreStatus;
  calls: ExploreCall[];
  usage: ExploreUsage;
  output: string;
}

interface ExploreRenderState {
  startedAt?: number;
  endedAt?: number;
  ticker?: ReturnType<typeof setInterval>;
}

const ExploreParams = Type.Object({
  task: Type.String({
    description:
      "The research question, written for an agent with no shared context. State what to find, where to look if you know, and what the answer should contain.",
  }),
});

function emptyUsage(): ExploreUsage {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
}

function formatUsage(usage: ExploreUsage, model: string | undefined): string {
  const parts: string[] = [];
  if (usage.turns) parts.push(`${usage.turns} turn${usage.turns > 1 ? "s" : ""}`);
  if (usage.input) parts.push(`↑${formatTokens(usage.input)}`);
  if (usage.output) parts.push(`↓${formatTokens(usage.output)}`);
  if (usage.cacheRead) parts.push(`R${formatTokens(usage.cacheRead)}`);
  if (usage.cacheWrite) parts.push(`W${formatTokens(usage.cacheWrite)}`);
  if (usage.cost) parts.push(`$${usage.cost.toFixed(4)}`);
  if (model) parts.push(model);
  return parts.join(" ");
}

// ---------------------------------------------------------------------------
// Subagent
// ---------------------------------------------------------------------------

/**
 * One ModelRuntime for the life of the process. `createAgentSession()` would
 * otherwise build (and re-read auth.json for) a fresh one on every call.
 */
let runtimePromise: Promise<ModelRuntime> | undefined;

function getModelRuntime(): Promise<ModelRuntime> {
  runtimePromise ??= ModelRuntime.create();
  return runtimePromise;
}

/** Configured explore model if usable, else the parent session's model. */
function resolveModel(runtime: ModelRuntime, ctx: ExtensionContext) {
  if (!EXPLORE_MODEL) return ctx.model;
  const model = runtime.getModel(EXPLORE_MODEL.provider, EXPLORE_MODEL.id);
  if (model && runtime.hasConfiguredAuth(EXPLORE_MODEL.provider)) return model;
  return ctx.model;
}

/** Last text block of the last assistant message - the subagent's answer. */
function finalOutput(messages: readonly { role: string; content: unknown }[]): string {
  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i];
    if (message.role !== "assistant" || !Array.isArray(message.content)) continue;
    for (const part of message.content) {
      if (part && typeof part === "object" && (part as { type?: string }).type === "text") {
        const text = (part as { text?: string }).text;
        if (text?.trim()) return text;
      }
    }
  }
  return "";
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "explore",
    label: "Explore",
    description: [
      "Delegate a read-only research question about the codebase to a subagent with its own context window.",
      "Use it when answering means sweeping many files, directories or naming conventions and you only need the conclusion, not the file dumps.",
      "The subagent reads excerpts rather than whole files, so it locates code; it does not review or audit it, and it cannot modify anything.",
      "It cannot ask you follow-up questions, so state the question, where to look if you know, and what the answer should contain.",
      "Returns the subagent's written findings only - its tool calls never enter your context.",
    ].join(" "),

    // Without a promptSnippet, pi omits the tool from the system prompt's
    // "Available tools" list entirely, and the parent never reaches for it.
    // The guidelines have to state a mechanical test - "prefer explore when a
    // question spans many files" reads as a preference and gets ignored.
    promptSnippet: "Hand a codebase search to a read-only subagent; only its findings enter your context",
    promptGuidelines: [
      "Before your first search, decide whether the question names a specific file or symbol. If it does not, call explore instead of searching yourself - do not open with bash, grep, find or read on an open-ended question.",
      "Searching by hand is only for questions you can answer in one or two calls. If you find yourself about to run a third search command on the same question, you should have called explore.",
      "Do not call explore when the user names the file, names the symbol, asks a general programming question, or asks for one command's output.",
    ],
    parameters: ExploreParams,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const runtime = await getModelRuntime();
      const model = resolveModel(runtime, ctx);
      if (!model) throw new Error("explore: no model available");

      const details: ExploreDetails = {
        task: params.task,
        model: model.id,
        status: "running",
        calls: [],
        usage: emptyUsage(),
        output: "",
      };

      const emit = () => {
        onUpdate?.({ content: [{ type: "text", text: details.output || "(exploring...)" }], details });
      };

      const settingsManager = SettingsManager.create(ctx.cwd, getAgentDir(), {
        projectTrusted: ctx.isProjectTrusted(),
      });

      // Extensions, skills, prompt templates and themes are all parent-session
      // concerns. Loading them here would pull `explore` itself back in.
      const resourceLoader = new DefaultResourceLoader({
        cwd: ctx.cwd,
        agentDir: getAgentDir(),
        settingsManager,
        noExtensions: true,
        noSkills: true,
        noPromptTemplates: true,
        noThemes: true,
        noContextFiles: !INCLUDE_CONTEXT_FILES,
        appendSystemPrompt: [EXPLORE_SYSTEM_PROMPT],
      });
      await resourceLoader.reload();

      const { session } = await createAgentSession({
        cwd: ctx.cwd,
        model,
        thinkingLevel: EXPLORE_THINKING,
        modelRuntime: runtime,
        tools: EXPLORE_TOOLS,
        resourceLoader,
        settingsManager,
        sessionManager: SessionManager.inMemory(ctx.cwd),
      });

      // `cutShort` records *why* the sweep ended early, and doubles as the flag
      // for whether a wrap-up turn is owed.
      let cutShort: "time" | "calls" | undefined;
      const cutSweepShort = (reason: "time" | "calls") => {
        if (cutShort || details.status !== "running") return;
        cutShort = reason;
        void session.abort();
      };

      const unsubscribe = session.subscribe((event) => {
        if (event.type === "tool_execution_start") {
          details.calls.push({ name: event.toolName, args: (event.args ?? {}) as Record<string, unknown> });
          emit();
          if (details.calls.length >= EXPLORE_MAX_CALLS) cutSweepShort("calls");
        } else if (event.type === "message_end") {
          const message = event.message as { role?: string; usage?: Record<string, any> };
          if (message.role !== "assistant") return;
          details.usage.turns++;
          const usage = message.usage;
          if (usage) {
            details.usage.input += usage.input ?? 0;
            details.usage.output += usage.output ?? 0;
            details.usage.cacheRead += usage.cacheRead ?? 0;
            details.usage.cacheWrite += usage.cacheWrite ?? 0;
            details.usage.cost += usage.cost?.total ?? 0;
          }
          details.output = finalOutput(session.state.messages as any);
          emit();
        }
      });

      const onAbort = () => void session.abort();
      const softTimer = setTimeout(() => cutSweepShort("time"), EXPLORE_SOFT_TIMEOUT_MS);
      let wrapUpTimer: ReturnType<typeof setTimeout> | undefined;
      signal?.addEventListener("abort", onAbort, { once: true });

      try {
        await session.prompt(params.task);
        clearTimeout(softTimer);

        if (signal?.aborted) throw new Error("explore: aborted");

        let hardTimedOut = false;
        if (cutShort) {
          // Stripping the tools makes it structurally impossible for the wrap-up
          // to keep searching, so the allowance below buys a write-up and nothing
          // else. pi synthesises tool results for calls the abort interrupted, so
          // the history is well-formed and the session accepts another turn.
          session.setActiveToolsByName([]);
          details.status = "wrapping-up";
          emit();

          wrapUpTimer = setTimeout(() => {
            hardTimedOut = true;
            void session.abort();
          }, EXPLORE_WRAP_UP_TIMEOUT_MS);
          await session.prompt(WRAP_UP_PROMPT);
          clearTimeout(wrapUpTimer);

          if (signal?.aborted) throw new Error("explore: aborted");
        }

        details.status = hardTimedOut ? "timeout" : cutShort ? "cut-short" : "done";
        details.output = finalOutput(session.state.messages as any);

        // Our own aborts set state.errorMessage, so an error is only fatal when
        // we did not cause it. A completed wrap-up clears the field itself.
        const errorMessage = session.state.errorMessage;
        if (!hardTimedOut && !details.output && errorMessage) throw new Error(`explore: ${errorMessage}`);

        let text = details.output || "(the subagent returned no findings)";
        if (cutShort) {
          const spent =
            cutShort === "calls"
              ? `its ${EXPLORE_MAX_CALLS}-call budget`
              : `its ${formatDuration(EXPLORE_SOFT_TIMEOUT_MS)} budget`;
          if (hardTimedOut) {
            if (!details.output) text = "(no findings; the subagent did not finish writing up)";
            text += `\n\n[explore spent ${spent} after ${details.calls.length} tool calls and then ran out of time writing up; anything above may be incomplete]`;
          } else {
            text += `\n\n[explore stopped searching at ${spent} (${details.calls.length} tool calls) and wrote up what it had; ask again for anything it flagged as missing]`;
          }
        }

        const result: AgentToolResult<ExploreDetails> = {
          content: [{ type: "text", text }],
          details,
        };
        return result;
      } finally {
        clearTimeout(softTimer);
        clearTimeout(wrapUpTimer);
        signal?.removeEventListener("abort", onAbort);
        unsubscribe();
        session.dispose();
      }
    },

    renderCall(args, theme, context) {
      const state = (context.state ??= {}) as ExploreRenderState;
      state.startedAt ??= Date.now();

      // Tick while the subagent is working: it can go a long time between tool
      // calls, so onUpdate alone leaves the row looking frozen.
      if (state.ticker === undefined && context.isPartial !== false) {
        state.ticker = setInterval(() => context.invalidate(), 100);
      }

      const elapsed = (state.endedAt ?? Date.now()) - state.startedAt;
      const text =
        theme.fg("toolTitle", theme.bold("explore ")) +
        theme.fg("accent", truncate(args.task ?? "...", context.expanded ? 400 : 80)) +
        theme.fg("dim", `  ${formatDuration(elapsed)}`);
      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme, context) {
      const state = (context.state ??= {}) as ExploreRenderState;
      state.endedAt ??= Date.now();
      if (state.ticker !== undefined) {
        clearInterval(state.ticker);
        state.ticker = undefined;
      }

      const details = result.details as ExploreDetails | undefined;
      if (!details) {
        const first = result.content[0];
        return new Text(first?.type === "text" ? first.text : "(no output)", 0, 0);
      }

      const icon = context.isError
        ? theme.fg("error", "✗")
        : details.status === "timeout" || details.status === "cut-short"
          ? theme.fg("warning", "⏱")
          : theme.fg("success", "✓");
      const usage = formatUsage(details.usage, details.model);

      if (expanded) {
        const container = new Container();
        container.addChild(new Text(`${icon} ${theme.fg("muted", `${details.calls.length} tool calls`)}`, 0, 0));
        for (const call of details.calls) {
          container.addChild(new Text(theme.fg("muted", "→ ") + formatToolCall(call.name, call.args, theme), 0, 0));
        }
        if (details.output) {
          container.addChild(new Spacer(1));
          container.addChild(new Markdown(details.output.trim(), 0, 0, getMarkdownTheme()));
        }
        if (usage) {
          container.addChild(new Spacer(1));
          container.addChild(new Text(theme.fg("dim", usage), 0, 0));
        }
        return container;
      }

      // Collapsed: recent tool calls while the subagent works, so the row shows
      // progress; once done, just the headline - the calls are what ctrl+o is for.
      let text = "";
      if (details.status === "wrapping-up") {
        text += `${theme.fg("warning", "⏱")} ${theme.fg("muted", `${details.calls.length} tool calls; writing up...`)}\n`;
      } else if (details.status === "running") {
        const shown = details.calls.slice(-COLLAPSED_CALL_COUNT);
        const skipped = details.calls.length - shown.length;
        if (skipped > 0) text += `${theme.fg("muted", `... ${skipped} earlier calls`)}\n`;
        for (const call of shown) {
          text += `${theme.fg("muted", "→ ") + formatToolCall(call.name, call.args, theme)}\n`;
        }
      } else {
        text += `${icon} ${theme.fg("muted", `${details.calls.length} tool calls`)}\n`;
        if (details.output) text += `${theme.fg("toolOutput", truncate(details.output, 200))}\n`;
      }
      if (usage) text += theme.fg("dim", usage);
      return new Text(text.trimEnd() || theme.fg("muted", "(exploring...)"), 0, 0);
    },
  });
}
