---
description: harness-optimizer agent 진입점 — hooks/commands/skills/agents 베이스라인 측정
meta:
  source: ecc-derived
  updateDate: 2026-04-16
---

`harness-optimizer` agent 가 가정하는 진입점. 현재 agentic harness 의 정량 베이스라인을 산출한다.

## 절차

`harness-optimizer` agent 를 spawn 해 다음 측정값을 수집:

1. **Hooks 활성 수** — `.config/claude/settings.json` 의 `hooks.*` 배열 항목 수 (이벤트별)
2. **Commands 활성 수** — `~/.agents/commands/*.md` 파일 수 (`__` prefix 제외 카운트도 별도)
3. **Skills 활성 수** — `~/.agents/.skill-lock.json` 의 `skills` 키 수 + 디렉토리 실제 수
4. **Agents 모델 분포** — `~/.agents/agents/*.md` frontmatter `model:` 값 집계 (opus/sonnet/haiku 분포)
5. **`.skill-lock.json` 신선도** — 각 skill 의 `updatedAt` 최신/최오래값
6. **MCP 서버 등록** — `~/.claude.json` 또는 `.mcp.json` 의 mcpServers 키 수
7. **Frontmatter `meta:` 커버리지** — agents/commands 중 `meta:` 블록 보유 비율

## 산출물

baseline scorecard:

| 영역 | 현재값 | 목표 | 비고 |
|---|---|---|---|
| hooks | N | — | 이벤트별 분포 |
| commands | N | — | __ prefix 제외 |
| skills | N | — | lock vs dir |
| agent models | { opus: X, sonnet: Y } | — | |
| skill-lock 최오래 | YYYY-MM-DD | <90d | |
| MCP servers | N | ≥1 | 미설정 시 권고 |
| meta 커버리지 | X% | 100% | 누락 항목 리스트 |

`harness-optimizer` 의 후속: top 3 leverage 영역 식별 + 최소 변경 제안.
