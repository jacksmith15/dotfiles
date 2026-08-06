---
paths:
  - "**/CLAUDE.md"
---

# CLAUDE.md

Guidance for writing and maintaining a project's `CLAUDE.md`.

## What earns a line

Every line is loaded into every session for that project, so it is charged against every future task — including the ones nowhere near the code it describes. Add a line only when it passes all of these:

- **Nothing else already enforces it.** If a type, a test, or lint catches the mistake, the rule is redundant. Documenting a self-enforcing invariant costs context and buys nothing.
- **The failure symptom points somewhere else.** The highest-value entries are the ones where getting it wrong produces a misleading error — a toolchain mismatch that reads as a broken test, a server setting that presents as a CORS failure. Describe the symptom, not just the rule.
- **You need it before you find the code.** Toolchain, commands, cross-cutting conventions, and traps that span several files. A rule about one function belongs in that function's docstring, where it is in front of whoever changes it.

## How to write it

- State the constraint and the consequence of breaking it. A rule with no "because" gets simplified away by the next person who reads it.
- Do not restate what the code already says.
- Do not duplicate. If it belongs in a docstring, it belongs there *instead*, not as well.

## Pruning

Re-read it whenever it grows. Entries describing code that has since gained a type, a test, or a lint rule are dead — delete them.
