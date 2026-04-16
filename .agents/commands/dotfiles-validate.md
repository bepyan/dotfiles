---
description: dotfiles 통합 검증 — sym-check + skill-audit + frontmatter 스키마 + AGENTS.md 심링크 정합성 4단계
meta:
  source: native
  updateDate: 2026-04-16
---

dotfiles 레포의 무결성을 4단계로 점검한다. 각 단계는 실패해도 다음 단계를 계속 진행하고, 마지막에 종합 결과 표를 출력한다.

## 단계

### 1. 심링크 무결성 (`/sym-check` 위임)

`/sym-check` 의 절차를 그대로 실행해 `~/.claude`, `~/.codex`, `~/.config` 의 모든 심링크가 살아 있는지 확인한다.

### 2. Skill 인벤토리 drift (`/skill-audit` 위임)

`/skill-audit` 의 절차로 `.skill-lock.json` ↔ `.agents/skills/` 디렉토리 일치를 검사한다.

### 3. Frontmatter 스키마

`.agents/agents/*.md` 와 `.agents/commands/*.md` 의 frontmatter 가 컨벤션에 맞는지 확인:

- `name`, `description` 필수 (agents 만)
- `meta:` 블록 존재 + `source`, `updateDate` 두 필드
- yaml 파싱 오류 없음

검사:
```bash
for f in ~/.agents/agents/*.md ~/.agents/commands/*.md; do
  awk '/^---$/{c++; if(c==2) exit} c>=1' "$f" | grep -q '^meta:' \
    || echo "MISSING meta: $f"
done
```

### 4. AGENTS.md 심링크 정합성

`~/.claude/CLAUDE.md` 가 `~/.agents/AGENTS.md` 로 심링크돼 있고, 그 타깃이 dotfiles 의 실제 파일과 동일한지 확인:

```bash
readlink ~/.claude/CLAUDE.md  # → ~/.agents/AGENTS.md
readlink ~/.agents             # → dotfiles/.agents
diff <(cat ~/.claude/CLAUDE.md) <(cat ~/vscode/dotfiles/.agents/AGENTS.md)  # 무차이
```

## 산출물

- 표: 단계 / 결과(✓/✗) / 문제 항목 수 / 권고
- 1개 이상 ✗ → `bash .setup.agents.sh` 재실행 + 개별 단계 디버깅 안내
