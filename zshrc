################################################################################
# ENV and ZSH set-up..

## Path and Locale.
export GOPATH=$HOME/scraps/go
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/go/bin:$PATH:$GOPATH/bin
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
export DROPBOX_FOLDER=~/Dropbox
export TASKDATA="$DROPBOX_FOLDER"/task

## Uncomment the following line to enable command auto-correction.
## ENABLE_CORRECTION="true"

## zsh plugins to use
plugins=(
  aws
  django
  docker
  docker-compose
  extract
  git
  jira
  kubectl
  pip
  poetry
  python
  sublime
  taskwarrior
  thefuck
  urltools
  zsh-autosuggestions
)

source "$ZSH/oh-my-zsh.sh"

## Add timetrap completions
fpath=(/var/lib/gems/2.5.0/gems/timetrap-1.15.1/completions/zsh $HOME/.zsh/completions $fpath)

## Base16 Shell.
[ -n "$PS1" ] && [ -s "$BASE16_SHELL/profile_helper.sh" ] && eval "$("$BASE16_SHELL/profile_helper.sh")"


################################################################################
# User configuration

# Don't append % to the end of output:
# https://unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
unsetopt prompt_cr prompt_sp

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

export SUBLIME_CONFIG="$HOME"/.config/sublime-text-3/Packages/User

## sublime project directory
export SUBLIME_PROJECT_DIR="$HOME"/proj

## jira url
export JIRA_URL="https://jira.extge.co.uk"

## Tfenv
export PATH="$HOME/.tfenv/bin:$PATH"

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
PYTHON_VERSION=3.8.6

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
  eval "$(pyenv init --path)"
fi

## Virtualenv
if python -c "import virtualenvwrapper";
then
  true
else
    pip install virtualenvwrapper &> /dev/null
fi
export WORKON_HOME=$HOME/venvs
export PROJECT_HOME=$HOME/repo
source /home/jack/.pyenv/versions/"$PYTHON_VERSION"/bin/virtualenvwrapper.sh



## Poetry
export POETRY_HOME="$HOME/.poetry"
export PATH="$POETRY_HOME/bin:$PATH"


## The Fuck
if python -c "import thefuck";
then
  true
else
    pip3 install thefuck &> /dev/null
fi

## MyPy
if python -c "import mypy";
then
  true
else
    pip install mypy &>/dev/null
fi
# export MYPY_CONF=~/.config/mypy
# for stub in "$MYPY_CONF"/stubs/*
# do
#   inner_directory="$(basename "$stub")"
#   export MYPYPATH=$MYPYPATH:$stub/$inner_directory
# done



################################################################################
# Node
## Node version manager options
export NVM_DIR="$HOME/.nvm"

if [ -s "$NVM_DIR/nvm.sh" ]; then

  ### This loads nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  ### This loads nvm bash_completion
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # Zsh hook - commented as quite slow
  # autoload -U add-zsh-hook
  # load-nvmrc() {
  #   local node_version="$(nvm version)"
  #   local nvmrc_path="$(nvm_find_nvmrc)"

  #   if [ -n "$nvmrc_path" ]; then
  #     local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

  #     if [ "$nvmrc_node_version" = "N/A" ]; then
  #       nvm install
  #     elif [ "$nvmrc_node_version" != "$node_version" ]; then
  #       nvm use
  #     fi
  #   elif [ "$node_version" != "$(nvm version default)" ]; then
  #     echo "Reverting to nvm default version"
  #     nvm use default
  #   fi
  # }
  # add-zsh-hook chpwd load-nvmrc
  # load-nvmrc
fi


################################################################################
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

### Load .env into current shell
function load-env {
  local environment="$1"
  export "$(cat .env."${environment}" | xargs)"
}

### Backup a file - maybe make this do folders?
bk() {
  cp -a "$1" "${1}_$(date --iso-8601=seconds).bk"
}

### Extract a field from a table
## $1 the field number
## $2 the data
## Example: ps aux | grep ssh | field 1
function field {
  tr -s ' ' ' ' $2 | cut -f $1 -d ' '
}

### Highlight matches
## $1 the pattern to match
## $2 the content to search
## Example: cat README.md | highlight author
function highlight {
  local pattern="$1""\|$"
  local content="$2"
  grep --color $pattern $content
}

### Search on google.
function google {
  local base_url="https://www.google.com/search?q="
  local search=$(urlencode "${(j: :)@}")
  xdg-open "$base_url""$search"

}

### Search on wikipedia.
function wikipedia {
  local base_url="https://en.wikipedia.org/w/index.php?search="
  local search=$(urlencode "${(j: :)@}")
  xdg-open "$base_url""$search"
}

### Get my public IP.
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

### Get the ip of an alias in my hosts file.
function hostsip {
  local host="$1"
  echo $(cat /etc/hosts | grep "$host") | awk '{print $1;}'
}

### Get the string representation of an alias in my aliases.
function f-alias {
  local alias=$1
  grep "$alias" "$HOME"/.zsh_aliases
}

### Get the description of a function defined in zshrc.
function f-func {
  local func=$1
  grep -B 1 "$func" "$$HOME"/.zshrc
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


## Python source code
### Clean a sub tree
function py-clean {
  local dir
  dir="$1"
  find "$dir" -name "*.pyc" -exec rm -f {} \;
}

## Sublime management commands:
### Open a sublime project by name
function proj {
  local projectname
  projectname=$1
  subl --project "$SUBLIME_PROJECT_DIR"/"$projectname".sublime-project
}

### Make a sublime project for currnet directory
function mkproj {
  local dir
  local name
  local projfile
  dir=${PWD}
  name=${PWD##*/}
  projfile="$SUBLIME_PROJECT_DIR"/"$name".sublime-project
  if [ ! -f "$projfile" ]
  then
    touch "$projfile"
    echo "{\n\"folders\":\n  [\n    {\n      \"path\": \"$dir\"\n    }\n  ]\n}" >> "$projfile"
  fi
}

### List sublime projects
function lsproj {
  find $SUBLIME_PROJECT_DIR -name "*.sublime-project" -exec basename {} .sublime-project \;
}

## Git commands:
### Show the base commit of a potential rebase target.
function grbb {
  local upstream=$1
  local hash=`git rev-list $upstream..HEAD | tail -1`
  git show "${hash}"
}

### Graph of rebase.
function grbbg {
  local upstream=$1
  local hash=$upstream..HEAD
  git log --decorate --oneline --graph "$hash"
}

### Timetrap in using current git branch as tag.
function tgit {
  local here=`git symbolic-ref HEAD | sed -e 's,refs/heads/[a-z]*/\(.*\),\1,'`
  t in "$here"
}

function git-cloc {
  local repo="$1"
  git clone --depth 1 "$repo" temp-linecount-repo &&
    printf "('temp-linecount-repo' will be deleted automatically)\n\n\n" &&
    cloc temp-linecount-repo &&
    rm -rf temp-linecount-repo
}

### JIRA ticket open
function ticket {
  local code
  if [[ "$#" > 0 ]]; then
    code=$1
  else
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    code=$(echo $current_branch | sed -rn 's@^[a-zA-Z0-9_-]+\/([a-zA-Z0-9-]+)\/[a-zA-Z0-9_-]+$@\1@p')
  fi
  xdg-open "$JIRA_URL/browse/$code"
}


################################################################################
# Final tasks.

## History configuration
export HIST_STAMPS="yyyy-mm-dd"

### Set file and size
export HISTFILE=~/.zsh_history
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000

### Share history between shells
setopt SHARE_HISTORY

### Save exact timestamps
export HISTTIMEFORMAT="[%F %T] "
setopt EXTENDED_HISTORY

### Don't show duplicates when searching
setopt HIST_FIND_NO_DUPS


# Start the tmux session.
if command -v tmux>/dev/null; then
  [[ ! $TERM =~ screen ]] && [[ -z "$TMUX" ]] && exec tmux
fi

eval "$(thefuck --alias)"

export PATH="$HOME/.poetry/bin:$PATH"
