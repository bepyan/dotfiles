---
description: dotfiles harness 무결성 검증 — symlink, skill drift, frontmatter 스키마
meta:
  source: native
  updateDate: 2026-05-10
---

dotfiles repo 의 무결성을 3 단계로 점검한다. 각 단계는 실패해도 다음 단계를 계속 진행하고, 마지막에 종합 결과 표를 출력한다.

`/audit-harness` 와 보완 관계 — 이쪽은 "깨진 곳 없나" 무결성, 저쪽은 정량 베이스라인.

전제: `REPO=~/vscode/dotfiles` 로 가정한다.

## 1. Symlink 무결성

`.setup.main.sh` + `.setup.agents.sh` 가 만드는 모든 symlink 가 올바른 타깃을 가리키는지 확인한다.

### 점검 대상

| 카테고리 | 링크 | 예상 타깃 |
|---|---|---|
| canonical | `~/.agents` | `$REPO/.agents` |
| Claude — instruction | `~/.claude/CLAUDE.md` | `~/.agents/AGENTS.md` |
| Claude — assets | `~/.claude/{commands,rules,agents,skills}` | `~/.agents/{commands,rules,agents,skills}` |
| Claude — settings | `~/.claude/settings.json` | `$REPO/.config/claude/settings.json` |
| Claude — statusline | `~/.claude/statusline.sh`, `~/.claude/statusline-fetch-rl.sh` | `$REPO/.config/claude/statusline*.sh` |
| Codex | `~/.codex/AGENTS.md`, `~/.codex/prompts`, `~/.codex/rules` | `~/.agents/AGENTS.md`, `~/.agents/commands`, `~/.agents/rules` |
| .config | `~/.config/{ghostty,zsh,vscode}` | `$REPO/.config/*` |
| VSCode + Cursor | `User/settings.json`, `User/cspell-user-words.txt` | `$REPO/.config/vscode/{settings.json,cspell-user-words.txt}` |

> Codex 의 `~/.codex/skills` 는 의도적으로 symlink 없음 — codex 는 `~/.agents/skills` 를 직접 읽는다 (`.setup.agents.sh` 의 line 84 주석 참고).

### 검증 방법

각 항목에 대해 두 가지를 본다:

```bash
readlink "$LINK"   # symlink 가 가리키는 raw 타깃
[ -e "$LINK" ]     # 체인을 끝까지 따라갔을 때 실제 존재 여부
```

상태 분류:
- `OK` — symlink 존재 + 타깃 reachable.
- `BROKEN` — symlink 는 있지만 타깃 없음 (dangling).
- `WRONG_TARGET` — symlink 는 있지만 예상과 다른 곳 가리킴.
- `MISSING` — symlink 자체가 없음 (real file 이거나 아예 없음).

### 산출물

표 컬럼: `링크 / 예상 타깃 / 실제 타깃 / 상태`.
1 개 이상 비-OK → `bash $REPO/.setup.agents.sh` 재실행 권고. `~/.config/*` 가 깨졌으면 `bash $REPO/.setup.main.sh` 까지.

## 2. Skill 인벤토리 drift

`~/.agents/.skill-lock.json` 과 `~/.agents/skills/` 디렉토리의 정합성을 확인한다.

### 검증 방법

```bash
# lock 에 등록된 skill
jq -r '.skills | keys[]' ~/.agents/.skill-lock.json | sort > /tmp/lock.txt

# 디렉토리에 실제 존재하는 skill (__ prefix 포함)
ls -1 ~/.agents/skills/ | sort > /tmp/dir.txt

comm -23 /tmp/lock.txt /tmp/dir.txt   # lock-only — 디렉토리 사라짐
comm -13 /tmp/lock.txt /tmp/dir.txt   # dir-only  — __ prefix 또는 lock 미등록
comm -12 /tmp/lock.txt /tmp/dir.txt   # 양쪽 존재 — hash 검증 후보
```

양쪽 존재하는 항목은 hash drift 까지 본다 (`skillFolderHash` 비교):

```bash
jq -r '.skills | to_entries[] | "\(.key)\t\(.value.skillFolderHash)"' \
  ~/.agents/.skill-lock.json
# 각 skill 에 대해 ~/.agents/skills/<name> 의 SHA256 과 대조
```

### 분류와 결정

- **lock-only** → 디렉토리 누락, 재설치 필요. lock 의 source URL 로 복구.
- **dir-only** + `__` prefix → 네이티브 skill, 정상.
- **dir-only** + non-prefix → 수동 추가분, lock 등록할지 결정.
- **양쪽 + hash 동일** → OK.
- **양쪽 + hash 다름** → 로컬 수정됨, lock 갱신 또는 원복 결정.

### 산출물

표 컬럼: `skill / lock / dir / hash / 결정`.

## 3. Frontmatter 스키마

`.agents/agents/`, `.agents/commands/`, `.agents/hooks/` 의 source-tracking 메타 컨벤션 (`CLAUDE.md` § Source tracking convention) 준수 확인.

### 점검 대상

| 디렉토리 | 컨벤션 | 필수 필드 |
|---|---|---|
| `.agents/agents/*.md` | YAML frontmatter | `name`, `description`, `meta.source`, `meta.updateDate` |
| `.agents/commands/*.md` | YAML frontmatter | `description`, `meta.source`, `meta.updateDate` |
| `.agents/hooks/*.sh` | 파일 상단 한 줄 주석 | `# meta: source=... updateDate=...` |
| `.agents/skills/*` | (제외) | `.skill-lock.json` 자동 추적 |

### 검증 방법

frontmatter — `yq` 권장:

```bash
for f in ~/.agents/agents/*.md ~/.agents/commands/*.md; do
  src=$(yq eval '.meta.source // ""' "$f" 2>/dev/null)
  date=$(yq eval '.meta.updateDate // ""' "$f" 2>/dev/null)
  [ -z "$src"  ] && echo "MISSING meta.source: $f"
  [ -z "$date" ] && echo "MISSING meta.updateDate: $f"
  [ -n "$date" ] && [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] \
    && echo "INVALID updateDate format ($date): $f"
done

# agents 만 추가로
for f in ~/.agents/agents/*.md; do
  yq eval '.name // ""' "$f" | grep -q . || echo "MISSING name: $f"
  yq eval '.description // ""' "$f" | grep -q . || echo "MISSING description: $f"
done
```

hooks — 한 줄 주석 컨벤션:

```bash
for f in ~/.agents/hooks/*.sh; do
  head -n 5 "$f" | grep -qE '^# *meta: *source=.+ *updateDate=[0-9]{4}-[0-9]{2}-[0-9]{2}' \
    || echo "MISSING/INVALID meta line: $f"
done
```

### 산출물

표 컬럼: `파일 / 누락 필드 / 형식 오류 / 권고`.
누락 발견 → 해당 파일 frontmatter (또는 hooks 한 줄 주석) 백필 권고.

## 종합 결과

```
| 단계                       | 결과 | 문제 항목 수 | 권고                                   |
|----------------------------|------|--------------|----------------------------------------|
| 1. Symlink 무결성          | ✓/✗  | N            | .setup.agents.sh / .setup.main.sh 재실행 |
| 2. Skill 인벤토리 drift    | ✓/✗  | N            | 재설치 / lock 갱신                      |
| 3. Frontmatter 스키마      | ✓/✗  | N            | 누락 필드 백필                          |
```

복구 우선순위는 위에서 아래로 — symlink 가 깨지면 나머지 검증이 잘못된 경로에서 도는 셈이라 먼저 고친다.
