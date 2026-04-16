---
description: ~/.claude, ~/.codex, ~/.config 심링크 무결성 검증
meta:
  source: native
  updateDate: 2026-04-16
---

## 진행 절차

`.setup.agents.sh`, `.setup.main.sh` 가 만드는 심링크를 `readlink` 로 검증한다.

확인 대상:

1. `~/.agents` → `dotfiles/.agents`
2. `~/.claude/CLAUDE.md` → `~/.agents/AGENTS.md`
3. `~/.claude/commands` → `~/.agents/commands`
4. `~/.claude/rules` → `~/.agents/rules`
5. `~/.claude/skills` → `~/.agents/skills`
6. `~/.claude/settings.json` → `dotfiles/.config/claude/settings.json`
7. `~/.codex/AGENTS.md`, `~/.codex/prompts`, `~/.codex/rules`
8. `~/.config/{ghostty,zsh,vscode}` → `dotfiles/.config/*`
9. VSCode + Cursor user `settings.json` → `dotfiles/.config/vscode/settings.json`

각 항목: `readlink` 결과 + 타깃 파일 존재 확인.

## 산출물

- 표: 경로 / 예상 타깃 / 실제 타깃 / 상태(OK/BROKEN/MISSING)
- BROKEN/MISSING 발견 시 `.setup.agents.sh` 재실행 권고
