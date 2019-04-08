################################################################################
# ENV and ZSH set-up..

## Path and Locale.
export GOPATH=/home/jack/go
export PATH=$HOME/bin:/usr/local/bin:$PATH:$GOPATH/bin
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
fpath=(/var/lib/gems/2.5.0/gems/timetrap-1.15.1/completions/zsh $HOME/.zsh/completions $fpath)

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

export SUBLIME_CONFIG="$HOME"/.config/sublime-text-3/Packages/User

## sublime project directory
export SUBLIME_PROJECT_DIR="$HOME"/proj

## jira url
export JIRA_URL="https://jira.extge.co.uk"

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
if python -c "import virtualenvwrapper";
then
    pip install virtualenvwrapper &> /dev/null
fi
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
if python -c "import pipenv"
then
    pip install pipenv &> /dev/null
fi

## The Fuck
if python -c "import thefuck";
then
    pip3 install thefuck &> /dev/null
fi

## MyPy
if python -c "import mypy";
then
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
# export NVM_DIR="$HOME/.nvm"

# ### This loads nvm
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ### This loads nvm bash_completion
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

## Zsh hook - commented as quite slow
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

### JIRA ticket from branch
function

### Tmux CI
function localci {
  local type_check="bash test.sh -ni -t"
  local lint="bash test.sh -ni -p"
  local unit="bash test.sh -ni -u"
  local component="bash test.sh -ni -ct"
  local integration="make integration"
  tmux split-window -v "watchmedo shell-command  --patterns=\"*.py\"  --recursive  --command='$type_check' --wait"
  tmux split-window -v "watchmedo shell-command  --patterns=\"*.py\"  --recursive  --command='$lint' --wait"
  tmux split-window -v "watchmedo shell-command  --patterns=\"*.py\"  --recursive  --command='$unit' --wait"
  tmux select-layout tiled
  tmux split-window -v "watchmedo shell-command  --patterns=\"*.py\"  --recursive  --command='$component' --wait"
  tmux split-window -v "watchmedo shell-command  --patterns=\"*.py\"  --recursive  --command='$integration' --wait"
  tmux select-layout tiled
  htop
}

################################################################################
# Final tasks.

# If ENV is set, and a .env file exists, source that .env file.
if [ -f "$HOME"/."$ENV".env ]
then
  source "$HOME"/."$ENV".env
fi

# If local overrides exist, source those last
if [ -f "$HOME"/.local.env ]
then
  source "$HOME"/.local.env
fi

# Start the tmux session.
if command -v tmux>/dev/null; then
  [[ ! $TERM =~ screen ]] && [ -z "$TMUX" ] && exec tmux
fi

eval "$(thefuck --alias)"
eval "$(direnv hook zsh)"
