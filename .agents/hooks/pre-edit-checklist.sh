#!/usr/bin/env bash
# meta: source=ecc-derived updateDate=2026-04-16
# inspiration: ECC GateGuard fact-forcing — 축약 reminder 형 (deny 아님)
# trigger: PreToolUse[Edit|Write|MultiEdit]

cat <<'MSG' >&2
[pre-edit] 편집 전 점검:
  1) 이 파일을 import/참조하는 곳 grep 했나?
  2) public API 영향 확인했나? (시그니처/타입/export)
  3) 데이터 스키마 변경 시 마이그레이션 필요한가?
  → skills/verification-before-completion, skills/systematic-debugging
MSG

exit 0
