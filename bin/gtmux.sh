#!/usr/bin/env bash
# 🚀 Ghostty Smart Tmux Launcher
# Always new session unless launched from a tab (inside tmux)

TMUX_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/tmux.conf"
TMUX_PLUGIN_MANAGER_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins/default"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/log}/ghostty"
LOG_FILE="$LOG_DIR/gtmux.log"
export TMUX_PLUGIN_MANAGER_PATH

SESSION_PREFIX="ghostty"
mkdir -p "$LOG_DIR"

log() {
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
}

DEBUG="${DEBUG:-0}"
dbg() { [ "$DEBUG" -eq 1 ] && printf "▶ %s\n" "$*" >&2; }

# ──────────────────────────────
# 🧷 Reuse only if already inside tmux (tab)
# ──────────────────────────────
if [ -n "$TMUX" ]; then
  SESSION_CURRENT="$(tmux display-message -p '#S' 2>/dev/null)"
  dbg "Inside tmux already, reattaching to: $SESSION_CURRENT"
  log "Reattaching inside tmux to: $SESSION_CURRENT"
  exec tmux -f "$TMUX_CONF" attach-session -t "$SESSION_CURRENT"
fi

# ──────────────────────────────
# 🌱 Create new session
# ──────────────────────────────
SESSION_NAME="${SESSION_PREFIX}-$(date +%s)"
dbg "Creating new session: $SESSION_NAME"
log "Creating new session: $SESSION_NAME"

tmux -f "$TMUX_CONF" new-session -d -s "$SESSION_NAME"

# 🔁 Auto-clean session when last client exits
tmux -f "$TMUX_CONF" set-hook -t "$SESSION_NAME" -g client-detached \
  "run-shell 'sleep 1; [ \$(tmux list-clients -t $SESSION_NAME 2>/dev/null | wc -l) -eq 0 ] && tmux kill-session -t $SESSION_NAME && echo \"[$(date '+%F %T')] Auto-cleaned session: $SESSION_NAME\" >> $LOG_FILE'"

exec tmux -f "$TMUX_CONF" attach-session -t "$SESSION_NAME"
