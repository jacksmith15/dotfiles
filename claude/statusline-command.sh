#!/bin/bash
# Claude Code status line: model, effort, context usage, plan usage / directory, branch

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
if [ -n "$dir" ] && [ "$dir" = "$HOME" -o "${dir#$HOME/}" != "$dir" ]; then
  dir_display="~${dir#$HOME}"
else
  dir_display="$dir"
fi

branch=""
if git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
fi

# Worktree layouts (e.g. ~/worktrees/<org>/<repo>/<branch>) put the branch name
# at the end of the directory path; drop it there so it isn't shown twice.
if [ -n "$branch" ] && [[ "$dir" == *"/$branch" ]]; then
  dir_display="${dir_display%"/$branch"}"
fi

# Colors (truecolor, tuned for contrast against a #2E3436 background)
COLOR_MODEL='\033[38;2;125;211;252m'   # sky blue
COLOR_EFFORT='\033[38;2;240;171;252m'  # light magenta
COLOR_CTX='\033[2;33m'                 # dim yellow
COLOR_SESSION='\033[38;2;250;189;47m'  # amber
COLOR_WEEK='\033[38;2;251;73;52m'      # orange-red
COLOR_DIR='\033[38;2;147;172;138m'     # muted sage
COLOR_BRANCH='\033[38;2;147;172;138m'  # muted sage
COLOR_RESET='\033[0m'
SEP='\033[2;37m|\033[0m'

join() {
  local out=""
  local first=1
  for p in "$@"; do
    if [ "$first" -eq 1 ]; then
      out="$p"
      first=0
    else
      out="$out $(printf "$SEP") $p"
    fi
  done
  printf "%b" "$out"
}

top_parts=()
top_parts+=("$(printf "${COLOR_MODEL}%s${COLOR_RESET}" "$model")")

if [ -n "$effort" ]; then
  top_parts+=("$(printf "${COLOR_EFFORT}effort:%s${COLOR_RESET}" "$effort")")
fi

if [ -n "$used_pct" ]; then
  top_parts+=("$(printf "${COLOR_CTX}ctx:%.0f%%${COLOR_RESET}" "$used_pct")")
fi

if [ -n "$session_pct" ]; then
  top_parts+=("$(printf "${COLOR_SESSION}5h:%.0f%%${COLOR_RESET}" "$session_pct")")
fi

if [ -n "$week_pct" ]; then
  top_parts+=("$(printf "${COLOR_WEEK}7d:%.0f%%${COLOR_RESET}" "$week_pct")")
fi

bottom_parts=()
if [ -n "$dir_display" ]; then
  bottom_parts+=("$(printf "${COLOR_DIR}%s/${COLOR_RESET}" "$dir_display")")
fi

if [ -n "$branch" ]; then
  bottom_parts+=("$(printf "${COLOR_BRANCH}%s${COLOR_RESET}" "$branch")")
fi

join "${top_parts[@]}"

if [ "${#bottom_parts[@]}" -gt 0 ]; then
  echo
  join "${bottom_parts[@]}"
fi
