#!/bin/bash
# Claude Code status line: model, effort, context usage, plan usage / directory, branch

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
session_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
now=$(date +%s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
if [ -n "$dir" ] && [ "$dir" = "$HOME" -o "${dir#$HOME/}" != "$dir" ]; then
  dir_display="~${dir#$HOME}"
else
  dir_display="$dir"
fi

# used_percentage is measured against the model's full context window, but
# autoCompactWindow (if set, and lower) is what actually triggers compaction, so
# it's the effective ceiling. It isn't in the status line payload — read it from
# settings, project-local first, then project, then user.
autocompact=""
for settings_file in \
  "$project_dir/.claude/settings.local.json" \
  "$project_dir/.claude/settings.json" \
  "$HOME/.claude/settings.json"; do
  if [ -z "$autocompact" ] && [ -f "$settings_file" ]; then
    autocompact=$(jq -r '.autoCompactWindow // empty' "$settings_file" 2>/dev/null)
  fi
done

if [ -n "$ctx_tokens" ] && [ -n "$ctx_size" ] && [ -n "$autocompact" ]; then
  used_pct=$(awk -v tokens="$ctx_tokens" -v size="$ctx_size" -v compact="$autocompact" '
    BEGIN {
      limit = (compact < size ? compact : size)
      pct = tokens / limit * 100
      print (pct > 100 ? 100 : pct)
    }')
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

# Extrapolates current usage to the window's reset time; prints 1 if that
# projects past 100% (on track to exhaust the budget early), else 0.
is_projected_over() {
  # args: used_pct resets_at window_seconds now
  awk -v used="$1" -v resets_at="$2" -v window="$3" -v now="$4" '
    BEGIN {
      elapsed = window - (resets_at - now)
      if (elapsed <= 0) { print "0"; exit }
      print (used * window / elapsed > 100) ? "1" : "0"
    }'
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
  session_warn=""
  if [ -n "$session_resets_at" ] && [ "$(is_projected_over "$session_pct" "$session_resets_at" 18000 "$now")" = "1" ]; then
    session_warn="!"
  fi
  top_parts+=("$(printf "${COLOR_SESSION}5h:%.0f%%%s${COLOR_RESET}" "$session_pct" "$session_warn")")
fi

if [ -n "$week_pct" ]; then
  week_warn=""
  if [ -n "$week_resets_at" ] && [ "$(is_projected_over "$week_pct" "$week_resets_at" 604800 "$now")" = "1" ]; then
    week_warn="!"
  fi
  top_parts+=("$(printf "${COLOR_WEEK}7d:%.0f%%%s${COLOR_RESET}" "$week_pct" "$week_warn")")
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
