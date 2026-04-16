#!/usr/bin/env bash
# meta: source=native updateDate=2026-04-16
# trigger: Stop
# 동작: 세션 종료 시 jsonl 한 줄 append (.agents/log/sessions.jsonl)

set -uo pipefail

LOG_DIR="$HOME/.agents/log"
LOG_FILE="$LOG_DIR/sessions.jsonl"
mkdir -p "$LOG_DIR"

INPUT="$(cat)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
TRANSCRIPT="$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CWD="$(pwd)"

FILES="[]"
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
  FILES="$(jq -s -c '
    [.[] | .message?.content? | arrays | .[] | select(.type? == "tool_use") | select(.name | IN("Edit","Write","MultiEdit")) | .input.file_path] | unique
  ' "$TRANSCRIPT" 2>/dev/null || echo "[]")"
  [[ -z "$FILES" || "$FILES" == "null" ]] && FILES="[]"
fi

jq -c -n \
  --arg ts "$TS" \
  --arg cwd "$CWD" \
  --arg sid "$SESSION_ID" \
  --argjson files "$FILES" \
  '{ts: $ts, cwd: $cwd, session_id: $sid, files_touched: $files}' \
  >> "$LOG_FILE" 2>/dev/null

exit 0
