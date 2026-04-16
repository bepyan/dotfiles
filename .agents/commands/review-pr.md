---
description: gh CLI + code-reviewer + security-reviewer agents 로 PR 리뷰
argument-hint: "[pr-number | current]"
meta:
  source: native
  updateDate: 2026-04-16
---

대상 PR: $ARGUMENTS (없으면 현재 브랜치 PR)

## 진행 절차

1. `gh pr view <num>` (또는 현재 브랜치) 로 PR 메타데이터 조회
2. `gh pr diff <num>` 로 변경사항 확보
3. 병렬 spawn:
   - `code-reviewer` agent — 일반 품질, 패턴, 가독성, 테스트 커버리지
   - `security-reviewer` agent — OWASP Top 10, 비밀 누출
   - (선택) 언어별 reviewer (`typescript-reviewer`, `database-reviewer`)
4. PR 컨벤션 점검: 제목 70자 이하, 설명 구조, 테스트 체크리스트, CI 상태(`gh pr checks`)
5. `caveman-review` skill 로 코멘트 압축
6. 사용자 승인 후 `gh pr comment` 로 게시

## 산출물

- 심각도별 분류 (CRITICAL / HIGH / MEDIUM / LOW)
- 차단 여부 + 권고 액션
