---
description: .skill-lock.json ↔ .agents/skills/ 디렉토리 drift 검사
meta:
  source: ecc-derived
  updateDate: 2026-04-16
---

## 진행 절차

1. `~/.agents/.skill-lock.json` 의 `skills` 키 목록 추출 — `jq -r '.skills | keys[]'`
2. `~/.agents/skills/` 디렉토리에서 실제 skill 목록 추출 — `ls -1`
3. drift 분류:
   - lock 에만 있음 → 디렉토리 사라진 skill (재설치 필요)
   - 디렉토리에만 있음 → lock 없는 skill (`__` prefix native 또는 수동 추가분)
   - 양쪽 일치 → OK
4. (선택, 비용 큼) 각 lock 항목의 `skillFolderHash` 와 실제 디렉토리 hash 비교

## 산출물

- 표: skill 이름 / lock 상태 / 디렉토리 상태 / 결정
- 후속 조치: 누락 skill 재설치 명령 또는 수동 native skill 의 lock 등록 권고
