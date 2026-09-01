---
name: agent-handoff
description: Creates a structured handoff document so one coding agent can pass in-progress work to a fresh agent with no shared context. Use when context usage is running high, when the user asks to hand off or start a fresh session, or when resuming work from an existing handoff document.
disable-model-invocation: true
---

# Agent Handoff

Passes work between coding agent sessions. Two modes:

1. **Create** - write a handoff document (default mode)
2. **Resume** - pick up work described by an existing handoff document

A handoff document is the *only* channel between sessions. The receiving
agent has none of the current conversation's context, so the document must
be fully self-contained.

## Create mode

Run when context usage is high, or the user asks to hand off / start a
fresh session.

1. **Gather state before writing.** Verify claims against the actual
   repo - do not trust memory of the conversation alone:
   - `git status` / `git log --oneline -10` / `git diff` (or equivalent for VCS)
   - Build/test/lint status - run them if cheap, otherwise note the last
     known result and when it was obtained
2. **Write the handoff document** to `.pi/handoff.md` in the project
   root, unless the user specified another path. Copy the structure from
   [template.md](template.md) and fill in every section. Delete sections
   that genuinely don't apply rather than leaving stubs.
3. **Quality check** the document before finishing:
   - No references to "the conversation", "as discussed", "the user said
     earlier" - restate the content instead
   - Every file mentioned exists at that exact path (or the document says
     it was deleted/renamed and by what)
   - Every command is copy-pasteable
   - A fresh agent with repo access and *only this document* could
     continue the work without guessing
4. **Report to the user**: the document path, a one-paragraph summary of
     what was handed off, and how to resume - start a new session and
     invoke `/skill:agent-handoff resume` (or just mention the handoff
     file).

### Writing rules

- Prefer bullet points over prose; front-load the next steps
- Include the *why* behind decisions, not just the what, so the receiving
  agent doesn't re-litigate settled questions
- Record dead ends and approaches already rejected, with reasons, to stop
  the next agent repeating them
- Include exact commands to build, test, run, and reproduce any failure
- State the environment: interpreter/tool versions if they matter, active
  branch, uncommitted changes, running processes or ports in use
- Keep it under ~150 lines; link to files in the repo for detail instead
  of pasting code into the document

## Resume mode

Run when the user asks to resume from a handoff document, or one exists at
`.pi/handoff.md`.

1. Read the handoff document (user-provided path, else `.pi/handoff.md`)
   completely.
2. **Verify state matches the document** before trusting it:
   - Check the recorded commit/branch matches reality (`git status`,
     `git log --oneline -5`). If the repo has moved on, reconcile first:
     note what changed and ask the user if the difference is significant.
   - Confirm the claimed current state of the work (files exist, tests
     pass or fail as stated).
3. Skim the referenced files to rebuild context, then continue with the
   documented next steps. Ask the user about any open questions recorded
   in the document before acting on ambiguous items.
4. **Maintain the document**: update its Current State and Next Steps as
   you complete work. When the task is fully done, delete the handoff
   document so stale state doesn't mislead a future session.
