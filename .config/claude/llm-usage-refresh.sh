#!/usr/bin/env bash
# meta: source=native updateDate=2026-06-18
#
# LiteLLM 사용량 단발 fetch → ~/.cache/jdai/llm-usage.json atomic write.
# statusline.sh TTL 만료 시 백그라운드에서 호출된다.
# 토큰/PII 어떤 로그에도 노출 금지.

set -uo pipefail

cache_dir="$HOME/.cache/jdai"
cache="$cache_dir/llm-usage.json"
lock="$cache_dir/llm-usage.lock"
lock_ttl=30  # 초 내 재호출 skip

mkdir -p "$cache_dir" 2>/dev/null || exit 1

now=$(date +%s)

# Single-flight: lock 파일에 blocked_until 저장, 아직 유효하면 skip
if [ -f "$lock" ]; then
  blocked_until=$(jq -r '.blocked_until // 0' "$lock" 2>/dev/null || echo 0)
  [ "$now" -lt "$blocked_until" ] && exit 0
fi

jq -n --argjson u "$((now + lock_ttl))" '{blocked_until:$u}' \
  > "$lock.tmp" 2>/dev/null && mv "$lock.tmp" "$lock" 2>/dev/null

base_url="${LITELLM_BASE_URL:-https://llm-dashboard.onkakao.net}"

# Token chain: apiKeyHelper → 환경변수 순
token=""

# 1. settings.json apiKeyHelper
helper=$(jq -r '.apiKeyHelper // empty' "$HOME/.claude/settings.json" 2>/dev/null)
if [ -n "$helper" ]; then
  token=$(eval "$helper" 2>/dev/null | head -1 | tr -d '[:space:]')
fi

# 2. AWS_BEARER_TOKEN_BEDROCK / ANTHROPIC_API_KEY 폴백
if [ -z "$token" ] || [[ "$token" != sk-* ]]; then
  for var in AWS_BEARER_TOKEN_BEDROCK ANTHROPIC_API_KEY; do
    val="${!var:-}"
    if [[ "$val" == sk-* ]]; then token="$val"; break; fi
  done
fi

# 토큰 없으면 조용히 종료
[[ "$token" == sk-* ]] || exit 0

# LiteLLM 호출
key_file=$(mktemp 2>/dev/null) || exit 1
user_file=$(mktemp 2>/dev/null) || { rm -f "$key_file"; exit 1; }
trap 'rm -f "$key_file" "$user_file"' EXIT

key_code=$(curl -sS -o "$key_file" -w '%{http_code}' \
  --max-time 5 \
  -H "Authorization: Bearer $token" \
  "${base_url}/key/info" 2>/dev/null) || exit 0

user_code=$(curl -sS -o "$user_file" -w '%{http_code}' \
  --max-time 5 \
  -H "Authorization: Bearer $token" \
  "${base_url}/user/info" 2>/dev/null) || exit 0

[ "$key_code" = "200" ] || exit 0
[ "$user_code" = "200" ] || exit 0

# 스냅샷 계산 — --slurpfile 로 파일 직접 전달 (인자 크기 제한 우회)
jq -n \
  --slurpfile key "$key_file" \
  --slurpfile user "$user_file" \
  --argjson now "$now" \
  --arg base_url "$base_url" \
  '
  def nn: . // 0 | tonumber? // 0;

  ($key[0].info // $key[0]) as $ki |
  ($user[0].user_info // $user[0].info // $user[0]) as $ui |

  ($ui.max_budget // $ki.max_budget // null | if . then tonumber? // null else null end) as $budget |
  ($ki.spend // 0 | nn)  as $ks |
  ($ui.spend // 0 | nn)  as $us |
  ([$ks, $us] | max)     as $conservative |

  {
    generated_at:          $now,
    base_url:              $base_url,
    token_source:          "apiKeyHelper",
    budget_usd:            $budget,
    key_spend_usd:         $ks,
    user_period_spend_usd: $us,
    conservative_spend_usd: $conservative,
    remaining_budget_usd:  (if $budget then ($budget - $conservative) else null end),
    remaining_budget_pct:  (if ($budget and $budget > 0) then (($budget - $conservative) / $budget * 100) else null end),
    budget_reset_at:       ($ui.budget_reset_at // $ki.budget_reset_at // null)
  }
  ' > "$cache.tmp" 2>/dev/null \
  && mv "$cache.tmp" "$cache" 2>/dev/null
