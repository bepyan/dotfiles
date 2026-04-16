---
description: planner agent + brainstorming/grill-me skill 로 작업 단계화
argument-hint: <task description>
meta:
  source: native
  updateDate: 2026-04-16
---

작업: $ARGUMENTS

## 진행 절차

1. `__brainstorming` skill 로 사용자 의도/요구사항을 명확히 한다 (모호하면 `grill-me` skill 도 활용).
1.5. (선택) 기존 코드 영역 작업이면 `code-explorer` agent spawn → 진입점/의존성 보고 후 brainstorming 진입.
2. 핵심 파일/패턴 파악이 필요하면 Explore subagent 를 병렬로 띄워 컨텍스트 수집.
3. `planner` agent 를 spawn 해 단계별 구현 계획을 작성 — 의존성, 위험, 검증 포함.
4. 계획은 `.agents/plans/` 또는 `~/.claude/plans/` 경로에 markdown 파일로 저장.
5. 사용자 승인 후 구현 단계로 진입.
6. (선택) 테스트 우선 명시 작업이면 `tdd-guide` agent spawn → RED phase 진입.
7. (선택) GREEN 후 critical user flow 가 있으면 `e2e-runner` agent spawn → Playwright 시나리오 생성/실행.

## 산출물

- 계획 파일 경로
- 미해결 질문 목록 (있으면)
