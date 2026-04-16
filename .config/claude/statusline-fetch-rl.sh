#!/usr/bin/env bash
# meta: source=sirmalloc/ccstatusline-derived updateDate=2026-04-17
#
# Anthropic rate-limit fetcher: keychain/credentials → OAuth API → cache.
# Invoked in background from statusline.sh when cache is stale. Silent on all errors.
# Honors HTTP 429 Retry-After via lock file so we never spam the API.

set -u

cache="$HOME/.claude/statusline-rl-cache.json"
lock="$HOME/.claude/statusline-rl.lock"
now=$(date +%s)

# Acquire lock first — blocks parallel fetchers even before we know if we'll hit the API.
mkdir -p "$(dirname "$lock")" 2>/dev/null
jq -n --argjson u "$((now + 30))" '{blocked_until:$u}' > "$lock.tmp" 2>/dev/null \
  && mv "$lock.tmp" "$lock" 2>/dev/null

# Token: macOS keychain first, ~/.claude/.credentials.json as fallback.
tok=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null \
      | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
[ -z "$tok" ] && tok=$(jq -r '.claudeAiOauth.accessToken // empty' \
                        "$HOME/.claude/.credentials.json" 2>/dev/null)
[ -n "$tok" ] || exit 0

body_file=$(mktemp 2>/dev/null) || exit 0
hdr_file=$(mktemp 2>/dev/null) || { rm -f "$body_file"; exit 0; }
trap 'rm -f "$body_file" "$hdr_file"' EXIT

http_code=$(curl -sS -o "$body_file" -D "$hdr_file" -w '%{http_code}' \
              --max-time 5 \
              -H "Authorization: Bearer $tok" \
              -H "anthropic-beta: oauth-2025-04-20" \
              https://api.anthropic.com/api/oauth/usage 2>/dev/null) || exit 0

case "$http_code" in
  200) ;;
  429)
    # Retry-After: extend lock so we don't retry until server says we can.
    retry_after=$(awk 'BEGIN{IGNORECASE=1} /^retry-after:/ {print $2; exit}' "$hdr_file" \
                  | tr -d '\r\n')
    [[ "$retry_after" =~ ^[0-9]+$ ]] || retry_after=300
    jq -n --argjson u "$((now + retry_after))" '{blocked_until:$u}' \
      > "$lock.tmp" 2>/dev/null && mv "$lock.tmp" "$lock" 2>/dev/null
    exit 0
    ;;
  *) exit 0 ;;
esac

iso2ts() {
  # Anthropic returns "2026-04-16T20:00:00.373735+00:00" style.
  # macOS `date -j -f` needs: no fractional secs, `Z`→`+0000`, `+HH:MM`→`+HHMM`.
  local s="${1:-}"
  [ -z "$s" ] || [ "$s" = "null" ] && return 0
  s=$(printf '%s' "$s" | sed -E 's/\.[0-9]+//; s/Z$/+0000/; s/([+-][0-9]{2}):([0-9]{2})$/\1\2/')
  date -j -u -f '%Y-%m-%dT%H:%M:%S%z' "$s" +%s 2>/dev/null
}

fh_u=$(jq -r '.five_hour.utilization // 0' "$body_file" 2>/dev/null)
fh_r=$(iso2ts "$(jq -r '.five_hour.resets_at // empty' "$body_file" 2>/dev/null)")
sd_u=$(jq -r '.seven_day.utilization // 0' "$body_file" 2>/dev/null)
sd_r=$(iso2ts "$(jq -r '.seven_day.resets_at // empty' "$body_file" 2>/dev/null)")

prev=$( [ -f "$cache" ] && cat "$cache" 2>/dev/null || echo '{}' )
printf '%s' "$prev" | jq \
  --argjson fhu "${fh_u:-0}" --argjson fhr "${fh_r:-null}" \
  --argjson sdu "${sd_u:-0}" --argjson sdr "${sd_r:-null}" \
  --argjson now "$now" \
  '. * {five_hour:{used_percentage:$fhu, resets_at:$fhr},
        seven_day:{used_percentage:$sdu, resets_at:$sdr},
        api_fetched_at:$now}' > "$cache.tmp" 2>/dev/null \
  && mv "$cache.tmp" "$cache" 2>/dev/null
