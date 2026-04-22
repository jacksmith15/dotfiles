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
  # aws
  # django
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
  # taskwarrior
  thefuck
  urltools
  zsh-autosuggestions
)

## Add custom and timetrap completions (must be before compinit in oh-my-zsh)
fpath=(/var/lib/gems/2.5.0/gems/timetrap-1.15.1/completions/zsh $HOME/.zsh/completions $fpath)

source "$ZSH/oh-my-zsh.sh"

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
export JIRA_URL="https://wavetrak.atlassian.net/"

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
PYTHON_VERSION=3.10.12

# Disable __pycache__ folders
export PYTHONDONTWRITEBYTECODE=1

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

## Rye
if [ -f "${HOME}/.rye/env" ]
then
  source "$HOME/.rye/env"
fi

################################################################################
# Rust

# Add to path
if [ -f "${HOME}/.cargo/env" ]
then
  . "${HOME}/.cargo/env"
fi



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
# AWS
export AWS_SDK_LOAD_CONFIG=true


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

# Plot memory usage for a process
function memoryplot {
  while :; do grep -oP '^VmRSS:\s+\K\d+' /proc/${1}/status \
    | numfmt --from-unit Ki --to-unit Mi; sleep 1; done | ttyplot -u Mi
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

### Switch between git worktrees
# gws() {
#   local branch="$1"
#   local repo_root repo_name worktree_path

#   repo_root=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
#   if [[ $? -ne 0 ]]; then
#     echo "gws: not inside a git repository"
#     return 1
#   fi
#   repo_root="${repo_root%/.git}"

#   if [[ -z "$branch" ]]; then
#     cd "$repo_root"
#     return 0
#   fi

#   repo_name=$(basename "$repo_root")
#   worktree_path="${HOME}/worktrees/${repo_name}/${branch}"

#   if [[ ! -d "$worktree_path" ]]; then
#     echo "gws: creating worktree for '$branch' at '$worktree_path'"
#     if git rev-parse --verify "$branch" &>/dev/null; then
#       # Branch exists, just create a worktree for it
#       git worktree add "$worktree_path" "$branch" || return 1
#     else
#       # Branch doesn't exist, create it
#       git worktree add -b "$branch" "$worktree_path" || return 1
#     fi
#   fi

#   cd "$worktree_path"
# }

gws() {
  local branch="$1"
  local repo_root repo_name worktree_path relative_path current subdir

  repo_root=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "gws: not inside a git repository"
    return 1
  fi
  repo_root="${repo_root%/.git}"

  # Capture subdirectory relative to current worktree toplevel
  local toplevel
  toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$toplevel" && "$PWD" != "$toplevel" ]]; then
    subdir="${PWD#"$toplevel"/}"
  fi

  if [[ -z "$branch" ]]; then
    if [[ -n "$subdir" && -d "$repo_root/$subdir" ]]; then
      cd "$repo_root/$subdir"
    else
      cd "$repo_root"
    fi
    return 0
  fi

  # Walk up from repo_root looking for a 'repo' ancestor directory
  relative_path=$(basename "$repo_root")
  current=$(dirname "$repo_root")
  while [[ "$current" != "/" && "$current" != "$HOME" ]]; do
    if [[ $(basename "$current") == "repo" ]]; then
      break
    fi
    relative_path="$(basename "$current")/${relative_path}"
    current=$(dirname "$current")
  done

  worktree_path="${HOME}/worktrees/${relative_path}/${branch}"

  if [[ ! -d "$worktree_path" ]]; then
    echo "gws: creating worktree for '$branch' at '$worktree_path'"
    if git rev-parse --verify "$branch" &>/dev/null; then
      git worktree add "$worktree_path" "$branch" || return 1
    elif git rev-parse --verify "origin/$branch" &>/dev/null; then
      git worktree add -b "$branch" "$worktree_path" "origin/$branch" || return 1
    else
      git worktree add -b "$branch" "$worktree_path" || return 1
    fi
  fi

  if [[ -n "$subdir" && -d "$worktree_path/$subdir" ]]; then
    cd "$worktree_path/$subdir"
  else
    cd "$worktree_path"
  fi
}
alias gwo="gws"

### Delete a worktree and associated local branch
gwd() {
  local branch="$1"
  local repo_root

  repo_root=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "gwd: not inside a git repository"
    return 1
  fi
  repo_root="${repo_root%/.git}"

  if [[ -z "$branch" ]]; then
    echo "gwd: branch name required"
    return 1
  fi

  # Remove worktree by branch name
  git worktree remove "$branch" || {
    echo "gwd: failed to remove worktree '$branch' — may have uncommitted changes, use 'git worktree remove --force $branch' manually if sure"
    return 1
  }

  # Delete local branch if it exists
  if git rev-parse --verify "$branch" &>/dev/null; then
    git branch -D "$branch" || {
      echo "gwd: failed to delete branch '$branch'"
      return 1
    }
  fi

  # If we were inside the worktree being deleted, go back to repo root
  if [[ "$PWD" == "$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | grep -v "^$repo_root$" | head -1)"* ]]; then
    cd "$repo_root"
  fi
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
export COLORTERM=truecolor
if command -v tmux>/dev/null; then
  [[ ! "${TERM}" =~ screen ]] && [[ -z "${TERM_PROGRAM}" || "${TERM_PROGRAM}" != "vscode" ]] && [[ -z "$TMUX" ]] && exec tmux
fi

eval "$(thefuck --alias)"

export PATH="$HOME/.poetry/bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/jack/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/jack/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/jack/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/jack/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
export MAMBA_EXE="/home/jack/.local/bin/micromamba";
export MAMBA_ROOT_PREFIX="/home/jack/micromamba";
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    if [ -f "/home/jack/micromamba/etc/profile.d/micromamba.sh" ]; then
        . "/home/jack/micromamba/etc/profile.d/micromamba.sh"
    else
        export  PATH="/home/jack/micromamba/bin:$PATH"  # extra space after export prevents interference from conda init
    fi
fi
unset __mamba_setup
# <<< mamba initialize <<<
alias mamba=micromamba

# pnpm
export PNPM_HOME="/home/jack/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
