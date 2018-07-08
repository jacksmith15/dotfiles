################################################################################
# ENV and ZSH set-up..

## Path and Locale.
export PATH=$HOME/bin:/usr/local/bin:$PATH
export LC_ALL=en_GB.UTF-8
export LANG=en_GB.UTF-8

## Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$ZSH/custom

## Set name of the theme to load.
#### See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#### ZSH_THEME="robbyrussell"
ZSH_THEME="oxide"

export UPDATE_ZSH_DAYS=15

## Sensible default for use by `.env` files.
export ENV=dev

## Uncomment the following line to enable command auto-correction.
## ENABLE_CORRECTION="true"

## Formatting for output of `history` command.
HIST_STAMPS="yyyy-mm-dd"

## zsh plugins to use
plugins=(
  django
  docker
  docker-compose
  extract
  git
  jira
  pip
  python
  sublime
  thefuck
  urltools
  zsh-autosuggestions
)

source "$ZSH/oh-my-zsh.sh"

## Add timetrap completions
fpath=(/var/lib/gems/2.5.0/gems/timetrap-1.15.1/completions/zsh $fpath)

## Base16 Shell.
[ -n "$PS1" ] && [ -s "$BASE16_SHELL/profile_helper.sh" ] && eval "$("$BASE16_SHELL/profile_helper.sh")"


################################################################################
# User configuration

## Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

## Compilation flags
export ARCHFLAGS="-arch x86_64"

## ssh
export SSH_KEY_PATH="$HOME/.ssh/rsa_id"

## secret variables
source ~/.zsh_secrets

## aliases
source ~/.zsh_aliases

## bind ctrl arrow keys
bindkey '^[[D' backward-word
bindkey '^[[C' forward-word

bindkey '^W' backward-word
bindkey '^F' forward-word
bindkey '^[w' backward-kill-word
bindkey '^[f' kill-word


################################################################################
# Python
PYTHON_VERSION=3.6.5

## Virtualenv
pip install virtualenvwrapper &> /dev/null
export WORKON_HOME=$HOME/venvs
export PROJECT_HOME=$HOME/repo
source /usr/local/bin/virtualenvwrapper.sh

## Pyenv
if [ ! -d "$HOME/.pyenv" ]; then
  echo "cloning pyenv..."
  git clone https://github.com/pyenv/pyenv.git "$HOME"/.pyenv
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VERSION="$PYTHON_VERSION"
if command -v pyenv 1>/dev/null 2>&1
then
  eval "$(pyenv init -)"
fi

## Pipenv
pip install pipenv &> /dev/null

## The Fuck
pip3 install thefuck &> /dev/null


################################################################################
# Node
## Node version manager options
export NVM_DIR="$HOME/.nvm"

### This loads nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

### This loads nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

## Zsh hook
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc


# Less

## Custom less syntax highlighting
if dpkg -s libsource-highlight-common>/dev/null && \
   dpkg -s source-highlight>/dev/null; then
    target=$(dpkg -L libsource-highlight-common | grep lesspipe)
    export LESSOPEN="| $target %s"
    export less=' -R '
else
    echo "Make sure source-highlight is installed for less highlighting."
fi


################################################################################
# Custom Utility functions.

# Backup a file - maybe make this do folders?
bk() {
  cp -a "$1" "${1}_$(date --iso-8601=seconds).bk"
}

# Search on google.
function google {
  local base_url="https://www.google.com/search?q="
  local search=$(urlencode "${(j: :)@}")
  xdg-open "$base_url""$search"

}

# Search on wikipedia.
function wiki {
  local base_url="https://en.wikipedia.org/w/index.php?search="
  local search=$(urlencode "${(j: :)@}")
  xdg-open "$base_url""$search"
}

# Get my public IP.
function myip {
  local api
  case "$1" in
    "-4")
      api="http://v4.ipv6-test.com/api/myip.php"
      ;;
    "-6")
      api="http://v6.ipv6-test.com/api/myip.php"
      ;;
    *)
      api="http://ipv6-test.com/api/myip.php"
      ;;
  esac
  curl -s "$api"
  echo # Newline.
}

# Send a PUT request with JSON body.
function json_put {
  local url=$1
  local json=$2

  curl -H 'Content-Type: application/json' -X PUT -d "$json" "$url"
}

# Show folder and subfolder sizes.
function space {
  du -cs "$1"/* | sort -n
}

# Browse in shell, elinks with default settings.
function web {
  elinks "$1"
}

# Pipe to clipboard.
function clip {
  xclip -selection clipboard "$1"
}

# Open remote file with sublime.
### Installs rmate on the remote to allow this.
## $1 - server_user@server_address
## $2 - path/to/file
function rsubl {
  local remote=$1
  local file_path=$2
  local rsub_path="/usr/local/bin/rsub"
  ssh -R 52698:localhost:52698 "$remote" "
    if ! [ -f $rsub_path ]; then
      wget -O $rsub_path \https://raw.github.com/aurora/rmate/master/rmate
      chmod a+x $rsub_path
    fi
    rsub $file_path
  "
}

### Open a file on a vagrant remote with sublime.
function vsubl {
  local remote=$1
  local file_path=$2
  local rsub_path="/usr/local/bin/rsub"
  ssh -q \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -i ~/.vagrant.d/insecure_private_key \
      -R 52698:localhost:52698 "$remote" "
    if ! [ -f $rsub_path ]; then
      sudo wget -O $rsub_path \https://raw.github.com/aurora/rmate/master/rmate
      sudo chmod a+x $rsub_path
    fi
    rsub $file_path
  "
}

# Show the base commit of a potential rebase target.
function grbb {
  local upstream=$1
  local hash=`git rev-list $upstream..HEAD | tail -1`
  git show "${hash}"
}

# Graph of rebase.
function grbbg {
  local upstream=$1
  local hash=$upstream..HEAD
  git log --decorate --oneline --graph "$hash"
}

# Timetrap in using current git branch as tag.
function tgit {
  local here=`git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'`
  t in "$here"
}

################################################################################
# Final tasks.

# Start the tmux session.
if command -v tmux>/dev/null; then
  [[ ! $TERM =~ screen ]] && [ -z "$TMUX" ] && exec tmux
fi

eval "$(thefuck --alias)"
