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

## 리뷰 원칙

- 변경된 내용에 대해서만 리뷰한다.
- 같은 내용을 여러 섹션에 반복하지 않는다.

## 진행 절차

1. 변경사항과 메타데이터 수집
2. 병렬 spawn:
   - `code-reviewer` agent — 품질, 패턴, 가독성, 테스트 커버리지
   - `security-reviewer` agent — OWASP Top 10, 비밀 누출, 입력 검증
   - `silent-failure-hunter` agent — empty catch, error swallow, 잘못된 fallback
   - 조건부 `typescript-reviewer`
   - 조건부 `type-design-analyzer`
3. `caveman-review` skill로 코멘트 압축
4. Red/Green 팀 병렬 spawn:
   - Red(공격) = 이 코멘트를 **버려도 되는 이유**를 최대한 동원한다.
     - false positive: 코드 경로·타입·런타임에서 실제로 성립하지 않음
     - 과잉 진단: 스타일/취향을 버그처럼 말함, 비용 대비 이득이 거의 없음
     - 의도된 패턴: 기존 코드베이스 관례, 명시적 trade-off, 테스트·가드가 이미 있음
     - 문맥 누락: 변경 범위 밖, 이미 상위에서 보장됨, reviewer가 놓친 주석·문서
   - Green(방어) = 이 코멘트를 **살려야 하는 이유**를 최대한 동원한다.
     - 실제 incident 시나리오: 장애·데이터 손상·보안 사고로 이어질 수 있는 구체적 경로
     - hidden invariant: 암묵적 계약(순서, 동시성, null, 경계값) 위반
     - 회귀·확장 비용: 지금 고치지 않으면 다음 변경에서 비용이 폭증하는 지점
5. PR 대상이고 사용자가 승인하면 `gh pr comment`로 게시
   — 기존 봇 코멘트(marker `<!-- claude-review -->` 매칭) 가 있으면 `--edit-last` 로 갱신, 없으면 새 코멘트 작성
   - 단일 review batch 방식으로 하나의 Review로 묶어서 이슈별로 inline 코멘트 작성
   - 사람이 보기 좋은 형태로 코멘트를 재구성
