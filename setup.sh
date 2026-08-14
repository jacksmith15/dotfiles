#!/usr/bin/env bash

blue='\e[1;34m'
red='\e[1;31m'

magenta='\e[1;35m'
green='\e[1;32m'

white='\e[0;37m'

CMD="$1"

dotfilesdir=$(pwd)
backupdir=~/.dotfiles.orig

dotfiles=(
    aliases
    bashrc
    # Only these entries under ~/.claude are linked - the rest of that
    # directory holds credentials/session state that must stay local.
    claude/output-styles/assistant.md
    claude/rules
    claude/settings.json
    claude/statusline-command.sh
    dircolors
    gitconfig
    gitignore_global
    oh-my-zsh/custom/themes
    # Global pi config lives at ~/.pi/agent/. Only these files are managed
    # here; session state and trust decisions under ~/.pi/agent/ stay local.
    pi/agent/settings.json
    pi/agent/APPEND_SYSTEM.md
    pi/agent/themes/oxide.json
    pi/agent/extensions/block-editor.ts
    pi/agent/extensions/compact-bash.ts
    pi/agent/extensions/explore.ts
    pi/agent/extensions/openrouter-cost.ts
    taskrc
    tmux.conf
    tmuxinator
    vim
    vimrc
    zsh/completions
    zshenv
    zshrc
)
dotfiles_config=(
    ghostty
)

## key-value for non-default zsh plugins. plugin name -> plugin repo.
declare -A zsh_plugins=(
  [zsh-autosuggestions]=https://github.com/zsh-users/zsh-autosuggestions
)



printusage() {
    prog=$(basename "$0")
    echo "Usage: $prog [-option]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "    --help    Print this message" >&2
    echo "    -i        Install all config" >&2
    echo "    -l        Repair symlinks only, leaving divergent local config alone" >&2
    echo "    -ld       Dry run of -l: report what it would do, change nothing" >&2
    echo "    -r        Restore old config" >&2
    echo "    -u        Upgrade dependencies" >&2
}

requirements() {
    if [ ! "$(dpkg -s apt)" ]
    then
        echo "Install assumes apt package manager for installing dependencies."
        exit 1
    fi
    # Requirements
    ## Base
    echo -e "$magenta""\n Installing base dependencies...\n""$white"
    sudo apt-get install -y tmuxinator zsh git | grep "to upgrade"

    ## Less highlighting
    echo -e "$magenta""\n Installing less highlighting dependencies...\n""$white"
    sudo apt-get install -y libsource-highlight-common source-highlight | grep "to upgrade"

    ## Pyenv
    echo -e "$magenta""\n Installing pyenv dependencies...\n""$white"
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev | grep "to upgrade"

    # Oh-my-zsh
    oh-my-zsh

    # Tmux Plugin Manager
    tmux-plugin-manager

    # Sublime Text
    sublime-text-3

    # Wiki
    # wiki

    # Dropbox
    dropbox
}

oh-my-zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]
    then
        echo "installing oh-my-zsh..."
        sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
        oh-my-zsh-plugins
    else
        echo -e $magenta"\n Updating oh-my-zsh... \n"$white
        cd ~/.oh-my-zsh
        # git reset HEAD --hard
        /bin/sh ~/.oh-my-zsh/tools/upgrade.sh
        echo -e $magenta"\n Updating zsh plugins... \n"$white
        oh-my-zsh-plugins
    fi
}

oh-my-zsh-plugins() {
    ZSH_CUSTOM=$HOME/.oh-my-zsh/custom

    ## Check plugin exists, if not clone it.
    for plugin in "${!zsh_plugins[@]}"
    do
        echo -e "$green""  $plugin"":\n""$white"
        if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]
        then
            echo "cloning $plugin..."
            target="${ZSH_CUSTOM}"/plugins/$plugin
            git clone "${zsh_plugins[$plugin]}" $target
        else
            cd "$ZSH_CUSTOM/plugins/$plugin" || exit 1
            git pull origin master
        fi
    done
}

tmux-plugin-manager() {
    target="$HOME/.tmux/plugins/tpm"
    if sudo test -f $target
    then
        echo -e $magenta"\n Updating Tmux Plugin Manager... \n"$white
        cd "$target"
        git pull
    else
        echo -e $magenta"\n Cloning Tmux Plugin Manager... \n"$white
        mkdir -p $HOME/.tmux/plugins
        git clone https://github.com/tmux-plugins/tpm $target
    fi
}

sublime-text-3() {
    if sudo test -f /usr/bin/subl
    then
        # echo -e $magenta"\n Updating Sublime Text 3... \n"$white
        # sudo apt-get install --only-upgrade | grep "to upgrade"
        sublime-text-3-config
    else
        # echo -e $magenta"\n Installing Sublime Text 3... \n"$white
        # wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
        # sudo apt-get install apt-transport-https
        # echo "deb https://download.sublimetext.com/ apt/dev/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        # sudo apt-get update
        # sudo apt-get install sublime-text | grep "to upgrade"
        sublime-text-3-config
    fi
}

sublime-text-3-config() {
    source=git@github.com:jacksmith15/SublimeUser.git
    target="$HOME"/.config/sublime-text/Packages/User
    if [ ! -d "$target" ]
    then
        echo -e $magenta"\n Cloning Sublime Text Config.. \n"$white
        mkdir "$target"
        git clone "$source" "$target"
    elif [ ! -d "$target"/.git ]
    then
        echo -e $magenta"\n Cloning Sublime Text Config.. \n"$white
        mv "$target" "$target".bak
        mkdir "$target"
        git clone "$source" "$target"
    else
        echo -e $magenta"\n Updating Sublime Text 3 config.. \n"$white
        cd "$target"
        git pull --ff-only
    fi
}

wiki() {
    source=git@github.com:jacksmith15/wiki.git
    target="$HOME"/wiki
    if [ ! -d "$target" ]
    then
        echo -e $magenta"\n Cloning wiki files.. \n"$white
        mkdir "$target"
        git clone "$source" "$target"
    else
        echo -e $magenta"\n Updating wiki \n"$white
        cd "$target"
        git pull --ff-only
    fi
}

dropbox() {
    echo -e $magenta"Installing dropbox..."$white
    DROPBOX_FOLDER=~/Dropbox
    mkdir -p "$DROPBOX_FOLDER"
    sudo apt install nautilus-dropbox
}

# Emit a "<source>\t<target>" line for every managed link. Both -i and -l read
# this, so the manifest-to-path mapping lives in exactly one place.
link_targets() {
    for dots in "${dotfiles[@]}"
    do
        printf '%s\t%s\n' "$dotfilesdir/$dots" "$HOME/.$dots"
    done

    for dots_conf in "${dotfiles_config[@]}"
    do
        printf '%s\t%s\n' "$dotfilesdir/$dots_conf" "$HOME/.config/$dots_conf"
    done

    for cmd in "$dotfilesdir"/commands/*
    do
        if [ -x "$cmd" ]; then
            printf '%s\t%s\n' "$cmd" "$HOME/bin/$(basename "$cmd")"
        fi
    done
}

install() {
    requirements
    # Backup config.
    if ! [ -f $backupdir/check-backup.txt ]; then
        mkdir -p $backupdir/.config
        cd $backupdir || exit 1
        touch check-backup.txt

        # Backup to ~/.dotfiles.orig, preserving nested paths (e.g. claude/rules)
        for dots in "${dotfiles[@]}"
        do
            mkdir -p "$backupdir/$(dirname ".${dots}")"
            /bin/cp -rf ~/."${dots}" "$backupdir/.${dots}" &> /dev/null
        done

        # Backup some folder in ~/.config to ~/.dotfiles.orig/.config
        for dots_conf in "${dotfiles_config[@]}"
        do
            mkdir -p "$backupdir/.config/$(dirname "$dots_conf")"
            /bin/cp -rf ~/.config/"$dots_conf" "$backupdir/.config/$dots_conf" &> /dev/null
        done

        # Backup again with Git.
        git init &> /dev/null
        git add -u &> /dev/null
        git add . &> /dev/null
        git commit -m "Backup original config on `date '+%Y-%m-%d %H:%M'`" &> /dev/null

        # Output.
        echo -e $blue"Your config is backed up in "$backupdir"\n" >&2
        echo -e $red"Please do not delete check-backup.txt in .dotfiles.orig folder."$white >&2
        echo -e "It's used to backup and restore your old config.\n" >&2
    fi

    # Install config. Whatever is at the destination is destroyed - use -l
    # instead to repair links without clobbering divergent local config.
    while IFS=$'\t' read -r source target
    do
        # Nested entries (e.g. claude/rules) need their parent to exist first.
        mkdir -p "$(dirname "$target")"
        /bin/rm -rf "$target"
        /bin/ln -fs "$source" "$target"
    done < <(link_targets)

    # Attach symlinks for dropbox?

    echo -e $blue"New dotfiles is installed!\n"$white >&2
    echo "There may be some errors when Terminal is restarted." >&2
    echo "Please read the error messages with care and make sure all packages are installed." >&2
    echo -e "To restore old config, use "$red"./install.sh -r"$white" command." >&2
}

is_identical() {
    if [ -d "$1" ]; then
        diff -rq --no-dereference "$1" "$2" &> /dev/null
    else
        cmp -s "$1" "$2"
    fi
}

# place_link <dry_run> <source> <target>
place_link() {
    [ "$1" -eq 1 ] && return 0
    mkdir -p "$(dirname "$3")"
    /bin/rm -rf "$3"
    /bin/ln -fs "$2" "$3"
}

# relink [--dry-run]
relink() {
    local source target label source_type target_type
    local linked=0 created=0 adopted=0 skipped=0
    local dry_run=0 create_label="created" adopt_label="adopted"

    if [ "$1" = "--dry-run" ]; then
        dry_run=1
        create_label="create"
        adopt_label="adopt"
        echo -e "$magenta""\n Dry run - reporting what -l would do, changing nothing.\n""$white"
    else
        echo -e "$magenta""\n Repairing symlinks...\n""$white"
    fi

    while IFS=$'\t' read -r source target
    do
        label="${target#"$HOME"/}"

        if [ ! -e "$source" ]; then
            printf "  %b%-9s%b %s (no such file in repo: %s)\n" \
                "$red" "missing" "$white" "$label" "$source" >&2
            skipped=$((skipped + 1))
            continue
        fi

        # -e is false for a broken symlink, so test -L first. realpath -m
        # normalises without requiring existence, so a repo reached by another
        # path spelling still counts as linked and a dangling link doesn't error.
        if [ -L "$target" ]; then
            if [ "$(realpath -m "$target")" = "$(realpath -m "$source")" ]; then
                printf "  %b%-9s%b %s\n" "$green" "linked" "$white" "$label"
                linked=$((linked + 1))
            else
                printf "  %b%-9s%b %s (points at %s)\n" \
                    "$red" "foreign" "$white" "$label" "$(readlink "$target")" >&2
                skipped=$((skipped + 1))
            fi
            continue
        fi

        if [ ! -e "$target" ]; then
            place_link "$dry_run" "$source" "$target"
            printf "  %b%-9s%b %s\n" "$blue" "$create_label" "$white" "$label"
            created=$((created + 1))
            continue
        fi

        if [ -d "$source" ]; then source_type=directory; else source_type=file; fi
        if [ -d "$target" ]; then target_type=directory; else target_type=file; fi
        if [ "$source_type" != "$target_type" ]; then
            printf "  %b%-9s%b %s (repo has a %s, found a %s)\n" \
                "$red" "conflict" "$white" "$label" "$source_type" "$target_type" >&2
            skipped=$((skipped + 1))
            continue
        fi

        # Only ever replace something already byte-identical to the repo copy,
        # so there is nothing to back up and nothing to lose.
        if is_identical "$source" "$target"; then
            place_link "$dry_run" "$source" "$target"
            printf "  %b%-9s%b %s\n" "$blue" "$adopt_label" "$white" "$label"
            adopted=$((adopted + 1))
        else
            printf "  %b%-9s%b %s (local %s differs from the repo)\n" \
                "$red" "diverged" "$white" "$label" "$target_type" >&2
            skipped=$((skipped + 1))
        fi
    done < <(link_targets)

    if [ "$dry_run" -eq 1 ]; then
        echo -e "\n""$blue""$linked linked, $created to $create_label, $adopted to $adopt_label, $skipped skipped""$white" >&2
        echo -e "Nothing was changed. Re-run with "$green"-l"$white" to apply." >&2
    else
        echo -e "\n""$blue""$linked linked, $created created, $adopted adopted, $skipped skipped""$white" >&2
    fi

    if [ "$skipped" -gt 0 ]; then
        echo "Skipped entries are never touched. Reconcile each by hand, then re-run." >&2
        return 1
    fi
}

uninstall() {
    if [ -f $backupdir/check-backup.txt ]; then
        for dots in "${dotfiles[@]}"
        do
            /bin/rm -rf ~/."${dots}"
            mkdir -p ~/"$(dirname ".${dots}")"
            /bin/cp -rf "$backupdir/.${dots}" ~/."${dots}" &> /dev/null
            /bin/rm -rf "$backupdir/.${dots}"
        done

        for dots_conf in "${dotfiles_config[@]}"
        do
            /bin/rm -rf ~/.config/"$dots_conf"
            mkdir -p ~/.config/"$(dirname "$dots_conf")"
            /bin/cp -rf "$backupdir/.config/$dots_conf" ~/.config/"$dots_conf" &> /dev/null
            /bin/rm -rf "$backupdir/.config/$dots_conf"
        done

        # Save old config in backup directory with Git.
        cd $backupdir &> /dev/null
        git add -u &> /dev/null
        git add . &> /dev/null
        git commit -m "Restore original config on `date '+%Y-%m-%d %H:%M'`" &> /dev/null
    fi

    if ! [ -f $backupdir/check-backup.txt ]; then
        echo -e $red"You have not installed this dotfiles yet."$white >&2
    else
        echo -e $blue"Your old config has been restored!\n"$white >&2
    fi

    /bin/rm -rf $backupdir/check-backup.txt
}

if [[ -z "$1" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    printusage
    exit 0
fi

case "$CMD" in
    -i)
        install
        ;;
    -l)
        relink
        ;;
    -ld)
        relink --dry-run
        ;;
    -r)
        uninstall
        ;;
    -u)
        requirements
        ;;
    *)
        echo "Command not found" >&2
        exit 1
esac
