#!/bin/bash
input=$(cat)

# Caveman badge
CAVEMAN_BADGE=""
FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
if [ -f "$FLAG" ] && [ ! -L "$FLAG" ]; then
  MODE=$(head -c 64 "$FLAG" 2>/dev/null | tr -d '\n\r' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
  case "$MODE" in
    off|lite|full|ultra|wenyan-lite|wenyan|wenyan-full|wenyan-ultra|commit|review|compress)
      if [ -z "$MODE" ] || [ "$MODE" = "full" ]; then
        CAVEMAN_BADGE='\033[38;5;172m[CAVEMAN]\033[0m '
      else
        CAVEMAN_BADGE=$(printf '\033[38;5;172m[CAVEMAN:%s]\033[0m ' "$(echo "$MODE" | tr '[:lower:]' '[:upper:]')")
      fi
      ;;
  esac
fi

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.session_duration_ms // 0')

FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
SEVEN_D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git -C "$DIR" branch --show-current 2>/dev/null)"

# Helper: format seconds until reset as "Xh Ym" or "Ym" or "Xs"
format_reset() {
  local epoch=$1
  local now diff
  now=$(date +%s)
  diff=$((epoch - now))
  [ "$diff" -le 0 ] && return
  if [ "$diff" -ge 3600 ]; then
    printf '%dh %dm' $((diff / 3600)) $(((diff % 3600) / 60))
  elif [ "$diff" -ge 60 ]; then
    printf '%dm' $((diff / 60))
  else
    printf '%ds' "$diff"
  fi
}

# Helper: color a percentage value
color_pct() {
  local val=$1
  local int_val
  int_val=$(printf '%.0f' "$val" 2>/dev/null) || int_val=0
  if [ "$int_val" -ge 90 ]; then printf '%b' "$RED"
  elif [ "$int_val" -ge 70 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}

# Build rate limit string (omit entirely if both absent)
RATE_STR=""
if [ -n "$FIVE_H" ] || [ -n "$SEVEN_D" ]; then
  RATE_STR=" |"
  if [ -n "$FIVE_H" ]; then
    FIVE_H_INT=$(printf '%.0f' "$FIVE_H")
    RESET_STR=""
    [ -n "$FIVE_H_RESET" ] && { R=$(format_reset "$FIVE_H_RESET"); [ -n "$R" ] && RESET_STR=" ↺${R}"; }
    RATE_STR="${RATE_STR} $(color_pct "$FIVE_H")5h: ${FIVE_H_INT}%${RESET_STR}${RESET}"
  fi
  if [ -n "$SEVEN_D" ]; then
    SEVEN_D_INT=$(printf '%.0f' "$SEVEN_D")
    RESET_STR=""
    [ -n "$SEVEN_D_RESET" ] && { R=$(format_reset "$SEVEN_D_RESET"); [ -n "$R" ] && RESET_STR=" ↺${R}"; }
    RATE_STR="${RATE_STR} $(color_pct "$SEVEN_D")7d: ${SEVEN_D_INT}%${RESET_STR}${RESET}"
  fi
fi

echo -e "${CAVEMAN_BADGE}${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH"
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}%${RATE_STR} | ⏱️ ${MINS}m ${SECS}s"