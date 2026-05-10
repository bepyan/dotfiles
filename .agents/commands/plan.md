---
description: brainstorming → planner 로 spec/plan 산출 (구현은 별도 워크플로에 위임)
argument-hint: <task description>
meta:
  source: native
  updateDate: 2026-05-10
---

작업: $ARGUMENTS

## 진행 절차

1. **컨텍스트 수집** — 의도 명확화의 input 으로 사용한다.
   - `code-explorer` agent spawn — 작업 영역의 진입점/의존성/실행 경로 보고
   - 동시에 `git log -10 --oneline`, `git status` 로 최근 변경/모달 파악
   - 산출물: 코드 컨텍스트 보고서

2. **의도/요구사항 명확화**
   - `__brainstorming` skill 호출 — 1번 보고서를 컨텍스트로 전달
   - **저장 위치 override**: skill 기본값(`.brainstorm/specs/`) 대신 아래 「저장」 섹션의 글로벌 경로를 사용한다고 skill 에 명시
   - 결정 트리에 모호한 분기가 남으면 `grill-me` skill 로 추가 질문
   - 산출물: **spec** (목적, 요구사항, 접근 방식, 결정 사항)

3. **구현 계획 작성**
   - `planner` agent spawn — 입력: spec + 코드 컨텍스트
   - 산출물: **plan** (Phase별 단계, 파일 경로, risk, 검증 포인트)

4. **Self-check + 사용자 승인** — 아래 통과 못하면 `planner` 재호출.
   - [ ] 모든 단계에 구체 파일 경로가 있는가
   - [ ] 각 Phase 가 독립적으로 머지 가능한가
   - [ ] 테스트 전략(unit/integration/e2e) 이 명시되었는가
   - [ ] 에지 케이스/위험과 mitigation 이 명시되었는가

   승인되면 종료. **구현(TDD, E2E, 코드 작성) 은 일반 워크플로에 위임**한다.

## 저장

- 경로: `~/.agents/plans/YYYY-MM-DD-<topic>.md` 단일 파일 (글로벌)
  - `~/.agents` 는 dotfiles `.agents/` 의 symlink. 모든 프로젝트의 plan 결과물이 한 곳에 누적되며, dotfiles 의 `.gitignore` 가 이미 `.agents/plans/*` 를 제외해서 git 오염 없음
  - 호출된 cwd 의 `.gitignore` 를 건드리지 않는다 (글로벌 command 원칙)
- 구조: `## Spec` (2번 산출물) + `## Plan` (3번 산출물) 섹션 분리
- 2번 brainstorming 이 spec 까지 작성 → 3번 planner 출력은 같은 파일 `## Plan` 섹션으로 append

## 산출물

- 저장된 spec/plan 파일 경로
- Self-check 결과 (통과 또는 보완 사유)
- 미해결 질문 목록 (있으면)
