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
    dircolors
    gitconfig
    gitignore_global
    oh-my-zsh/custom/themes
    timetrap.yml
    tmux.conf
    tmuxinator
    vim
    vimrc
    zsh/completions
    zshrc
)
dotfiles_config=(
    mypy/mypy.ini
    i3
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
    sudo apt-get install -y libsource-highlight-common | grep "to upgrade"

    ## Pyenv
    echo -e "$magenta""\n Installing pyenv dependencies...\n""$white"
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev | grep "to upgrade"

    # Oh-my-zsh
    oh-my-zsh

    # Sublime Text
    sublime-text-3

    # Base16 Shell
    base-16-shell

    # MyPy Stubs
    mypy-stubs

    # Gnome extensions
    gnome-extensions

    # Wiki
    wiki

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

sublime-text-3() {
    if sudo test -f /usr/bin/subl
    then
        echo -e $magenta"\n Updating Sublime Text 3... \n"$white
        sudo apt-get install --only-upgrade | grep "to upgrade"
        sublime-text-3-config
    else
        echo -e $magenta"\n Installing Sublime Text 3... \n"$white
        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
        sudo apt-get install apt-transport-https
        echo "deb https://download.sublimetext.com/ apt/dev/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        sudo apt-get update
        sudo apt-get install sublime-text | grep "to upgrade"
        sublime-text-3-config
    fi
}

sublime-text-3-config() {
    source=git@github.com:jacksmith15/SublimeUser.git
    target="$HOME"/.config/sublime-text-3/Packages/User
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

base-16-shell() {
    if [ ! -d "$HOME/.config/base16-shell" ]
    then
        echo -e $magenta"\n Cloning base16-shell.."
        git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
    else
        echo -e $magenta"\n Updating base16-shell... \n"$white
        cd ~/.config/base16-shell || exit 1
        git pull
        ./colortest
    fi
}

mypy-stubs() {
    declare -A target_stubs=(
        [sqlalchemy]=git@github.com:JelleZijlstra/sqlalchemy-stubs.git
    )
    MYPY_CONFIG=~/.config/mypy
    if [ ! -d "$MYPY_CONFIG" ]
    then
        mkdir $MYPY_CONFIG
    fi
    MYPY_STUBS="$MYPY_CONFIG"/stubs
    if [ ! -d "$MYPY_STUBS" ]
    then
        mkdir $MYPY_STUBS
    fi
    for stub in "${!target_stubs[@]}"
    do
        stub_dir="$MYPY_STUBS"/"$stub"
        if [ ! -d "$stub_dir" ]
        then
            echo -e $magenta"\n Cloning mypy stubs: $stub.."$white
            git clone "${target_stubs[$stub]}" "$stub_dir"
        else
            echo -e $magenta"\n Updating mypy stubs: $stub.."$white
            cd "$stub_dir" || exit 1
            git pull --ff-only
        fi
    done
}

gnome-extensions() {
    GNOME_EXTENSIONS=~/.local/share/gnome-shell/extensions
    if pgrep -f gnome>/dev/null
    then
        if [ ! -d "$GNOME_EXTENSIONS" ]
        then
            mkdir -p "$GNOME_EXTENSIONS"
            echo -e $magenta"\n Cloning gnome extensions.."$white
            git clone git@github.com:jacksmith15/gnome-extensions.git "$GNOME_EXTENSIONS"
        elif [ ! -d "$GNOME_EXTENSIONS"/.git ]
        then
            mv "$GNOME_EXTENSIONS" "$GNOME_EXTENSIONS".bak
            echo -e $magenta"\n Cloning gnome extensions.."$white
            git clone git@github.com:jacksmith15/gnome-extensions.git "$GNOME_EXTENSIONS"
        else
            echo -e $magenta"\n Updating gnome extensions.."$white
            cd "$GNOME_EXTENSIONS" || exit 1
            git pull --ff-only
        fi
    else
        echo -e $red"\n Gnome not found.."$white
    fi
}

dropbox() {
    echo -e $magenta"Installing dropbox..."$white
    DROPBOX_FOLDER=~/Dropbox
    mkdir -p DROPBOX_FOLDER
    sudo apt install nautilus-dropbox
}

install() {
    requirements
    # Backup config.
    if ! [ -f $backupdir/check-backup.txt ]; then
        mkdir -p $backupdir/.config
        cd $backupdir || exit 1
        touch check-backup.txt

        # Backup to ~/.dotfiles.orig
        for dots in "${dotfiles[@]}"
        do
            /bin/cp -rf ~/.${dots} $backupdir &> /dev/null
        done

        # Backup some folder in ~/.config to ~/.dotfiles.orig/.config
        for dots_conf in "${dotfiles_config[@]}"
        do
            /bin/cp -rf ~/.config/${dots_conf} $backupdir/.config &> /dev/null
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

    # Install config.
    for dots in "${dotfiles[@]}"
    do
        /bin/rm -rf ~/."${dots}"
        /bin/ln -fs "$dotfilesdir/${dots}" ~/."${dots}"
    done

    # Install config to ~/.config.
    mkdir -p ~/.config
    for dots_conf in "${dotfiles_config[@]}"
    do
        /bin/rm -rf ~/.config/${dots_conf[@]}
        /bin/ln -fs "$dotfilesdir/${dots_conf}" ~/.config/${dots_conf[@]}
    done

    echo -e $blue"New dotfiles is installed!\n"$white >&2
    echo "There may be some errors when Terminal is restarted." >&2
    echo "Please read the error messages with care and make sure all packages are installed." >&2
    echo -e "To restore old config, use "$red"./install.sh -r"$white" command." >&2
}

uninstall() {
    if [ -f $backupdir/check-backup.txt ]; then
        for dots in "${dotfiles[@]}"
        do
            /bin/rm -rf ~/${dots}
            /bin/cp -rf $backupdir/${dots} ~/ &> /dev/null
            /bin/rm -rf $backupdir/${dots}
        done

        for dots_conf in "${dotfiles_config[@]}"
        do
            /bin/rm -rf ~/.config/$dots_conf
            /bin/cp -rf $backupdir/.config/${dots_conf} ~/.config &> /dev/null
            /bin/rm -rf $backupdir/.config/${dots_conf}
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
