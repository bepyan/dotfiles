---
description: code-reviewer + security-reviewer agents + caveman-review skill 통합 검토
argument-hint: "[diff-base | filepath]"
meta:
  source: native
  updateDate: 2026-04-16
---

검토 대상: $ARGUMENTS (없으면 현재 staged + unstaged diff)

## 진행 절차 (병렬 spawn)

1. `code-reviewer` agent — 일반 품질, 패턴, 가독성, 테스트 커버리지
2. `security-reviewer` agent — OWASP Top 10, 비밀 누출, 입력 검증
3. `silent-failure-hunter` agent — empty catch / 에러 swallow / 잘못된 fallback (필수)
4. (선택) `typescript-reviewer` 또는 `database-reviewer` — 언어/도메인 매칭 시
5. (선택) 큰 타입 변경 (union/branded/discriminated unions/제네릭 도입) 감지 시 → `type-design-analyzer` 추가 spawn
6. 결과 종합 후 `caveman-review` skill 로 최종 코멘트를 한 줄/이슈 형태로 압축

## 산출물

- 심각도별 분류 (CRITICAL / HIGH / MEDIUM / LOW)
- 차단 여부 판단
