---
description: .agents/log/sessions.jsonl 최근 N일 → 패턴 추출
argument-hint: "[days=7]"
meta:
  source: native
  updateDate: 2026-04-16
---

기간: $ARGUMENTS (기본 7일)

## 진행 절차

1. `~/.agents/log/sessions.jsonl` 에서 최근 N일치 행 추출 — `jq` 또는 `rg` 활용
2. `files_touched` 집계 — 가장 자주 수정된 파일 top 10
3. `cwd` 분포 — 작업 프로젝트 분포
4. 반복되는 작업 흐름이 있으면 `systematic-debugging` skill 의 분류 기법 활용
5. **Instinct 후보 추출** (선택, 비용 ~$0.05/호출):
   - 추출한 빈도/패턴 요약 + 반복 작업 흐름 일부 jsonl 라인을 Opus 에 단일 프롬프트로 전달
   - 프롬프트 골자: "다음 세션 로그에서 *반복적이고 자동화 가치 있는* 행동 5개를 trigger/action/evidence 형식으로 추출. 각 후보는 1-3 문장."
   - 출력 형식 예시:
     ```
     1. trigger: <상황>
        action: <자동화 가능 행동>
        evidence: 최근 N회 발생 (cwd: ...)
     ```
   - 사용자 검토 후 승인된 후보만 dotfiles `CLAUDE.md` 또는 해당 프로젝트 CLAUDE.md 에 한 줄로 추가 (글로벌 AGENTS.md 는 영향 범위 너무 크니 피한다)
   - **첫 호출 전 데이터 충분성 확인**: jsonl 50행 미만이면 instinct 추출 의미 약함 → 더 누적 후 재시도

## 산출물

- 빈도/패턴 요약 (top 파일/cwd/명령)
- (선택) instinct 후보 5개 + 사용자 승인 받은 항목의 적용 위치
