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
    -r        Restore old config
    -u        Upgrade dependencies
```

`setup.sh` must be run from the repo root — it builds symlink targets from `$(pwd)`.

## Adding a new config

Move the file or directory into this repo, then register it in the appropriate manifest at the top of `setup.sh`:

| Manifest | Repo path | Destination | Example |
|---|---|---|---|
| `dotfiles` | `<name>` | `~/.<name>` | `zshrc` → `~/.zshrc`, `claude/rules` → `~/.claude/rules` |
| `dotfiles_config` | `<path>` | `~/.config/<path>` | `ghostty` → `~/.config/ghostty` |
| none — auto-discovered | `commands/<exe>` | `~/bin/<exe>`, if the executable bit is set | `commands/clone` → `~/bin/clone` |

For `dotfiles`, the leading dot is prefixed to the whole entry, so it lands on the first path segment only — `claude/rules` becomes `~/.claude/rules`, not `~/.claude/.rules`.

Files and directories are handled identically. Link a directory's individual children rather than the directory itself when the destination also holds local state, since the install loop does `rm -rf` on the target before linking — this is why `~/.claude` has three separate entries instead of one, and why `~/.config/ghostty` has just one.

Backup only ever happens on the first `-i` run (guarded by the `check-backup.txt` sentinel in `~/.dotfiles.orig`). Adding an entry later and re-running `-i` will destroy whatever is already at the destination, so move the original into this repo *before* running the install.
