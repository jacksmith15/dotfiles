# Dotfiles

An amalgamation of dotfiles tricks from a range of sources.

Currently directly targets Ubuntu OS.

Oh-My-Zsh and Tmux based shell.

Install with `setup.sh`:
```
Usage: setup.sh [-option]

Options:
    --help    Print this message
    -i        Install all config
    -l        Repair symlinks only, leaving divergent local config alone
    -ld       Dry run of -l: report what it would do, change nothing
    -r        Restore old config
    -u        Upgrade dependencies
```

`setup.sh` must be run from the repo root — it builds symlink targets from `$(pwd)`.

## Repairing symlinks

`-l` is the mode to reach for after pulling config that was added on another machine, where a full `-i` would be overkill (it also does apt installs and third-party upgrades) or unsafe. Start with `-ld`, which is the same check with every filesystem change suppressed — it reports exactly what `-l` would do and where the problems are, so there is no need to remember any of the below before running it. For each entry in the manifests it does one of four things:

- **linked** — already points into this repo, nothing to do.
- **created** — nothing at the destination, so the symlink is made.
- **adopted** — a real file or directory whose contents are byte-identical to the repo copy, so it is replaced by the symlink. This is lossless by definition, which is why `-l` needs no backup step.
- **skipped** — anything else, reported with a reason and left completely untouched. Covers contents that diverge from the repo, a symlink pointing somewhere other than this repo, a file where the repo has a directory (or vice versa), and manifest entries with no matching file in the repo.

Under `-ld` the first two read as `create` and `adopt` (present tense) rather than `created` and `adopted`, so the two modes can't be confused after the fact.

Directory comparison is strict: extra local files in the destination that are not in the repo count as divergence, so `~/.claude/rules` with a local scratch file in it gets skipped rather than deleted. Both modes exit non-zero if anything was skipped, and are safe to re-run.

Reconcile a skipped entry by moving the local version into the repo (keeping whatever local additions matter) or deleting it, then run `-l` again.

## Adding a new config

Move the file or directory into this repo, then register it in the appropriate manifest at the top of `setup.sh`:

| Manifest | Repo path | Destination | Example |
|---|---|---|---|
| `dotfiles` | `<name>` | `~/.<name>` | `zshrc` → `~/.zshrc`, `claude/rules` → `~/.claude/rules` |
| `dotfiles_config` | `<path>` | `~/.config/<path>` | `ghostty` → `~/.config/ghostty` |
| none — auto-discovered | `commands/<exe>` | `~/bin/<exe>`, if the executable bit is set | `commands/clone` → `~/bin/clone` |

For `dotfiles`, the leading dot is prefixed to the whole entry, so it lands on the first path segment only — `claude/rules` becomes `~/.claude/rules`, not `~/.claude/.rules`.

Files and directories are handled identically. Link a directory's individual children rather than the directory itself when the destination also holds local state, since the install loop does `rm -rf` on the target before linking — this is why `~/.claude` has four separate entries instead of one, and why `~/.config/ghostty` has just one.

The same applies one level down. Linking a whole directory makes its contents all-or-nothing across machines, because anything added locally alongside them counts as divergence and gets the entry skipped. Register the individual file instead where a destination should stay open to machine-local additions: `claude/output-styles/assistant.md` creates `~/.claude/output-styles/` as a real directory holding one symlink, leaving room for a local style beside it.

Backup only ever happens on the first `-i` run (guarded by the `check-backup.txt` sentinel in `~/.dotfiles.orig`). Adding an entry later and re-running `-i` will destroy whatever is already at the destination, so move the original into this repo *before* running the install. Use `-l` to avoid this trap entirely — it refuses to touch a destination that does not already match the repo.
