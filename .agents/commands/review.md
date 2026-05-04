---
description: PR/current/local diff/filepath를 code/security/silent-failure 관점으로 통합 리뷰
argument-hint: "[pr-number | current | diff-base | filepath]"
meta:
  source: native
  updateDate: 2026-05-04
---

검토 대상: $ARGUMENTS

없으면 현재 staged + unstaged diff를 검토한다.

## 대상 판별

1. `$ARGUMENTS`가 없으면:
   - `git diff --cached`
   - `git diff`

2. `$ARGUMENTS`가 `current`이면:
   - `gh pr view`
   - `gh pr diff`

3. `$ARGUMENTS`가 PR 번호이면:
   - `gh pr view <num>`
   - `gh pr diff <num>`

4. `$ARGUMENTS`가 파일/경로이면 (filesystem 존재 확인 우선):
   - 해당 파일/경로의 diff와 주변 context 확보

5. 그 외에는 diff base로 간주:
   - `git diff <base>...HEAD`

## 진행 절차

1. 변경사항과 메타데이터 수집
2. 병렬 spawn:
   - `code-reviewer` agent — 품질, 패턴, 가독성, 테스트 커버리지
   - `security-reviewer` agent — OWASP Top 10, 비밀 누출, 입력 검증
   - `silent-failure-hunter` agent — empty catch, error swallow, 잘못된 fallback
   - 조건부 `typescript-reviewer`
   - 조건부 `database-reviewer`
   - 조건부 `type-design-analyzer`
3. PR 대상이면 추가 점검:
   - 제목 70자 이하
   - 설명 구조
   - 테스트 체크리스트
   - CI 상태: `gh pr checks`
4. 결과 중복 제거 및 심각도 분류
5. `caveman-review` skill로 코멘트 압축
6. PR 대상이고 사용자가 승인하면 `gh pr comment`로 게시 — 기존 봇 코멘트(marker `<!-- claude-review -->` 매칭) 가 있으면 `--edit-last` 로 갱신, 없으면 새 코멘트 (멱등성 가드)

## 산출물

- CRITICAL / HIGH / MEDIUM / LOW 분류
- 차단 여부
- 권고 액션
- PR 대상인 경우 게시용 코멘트 초안
