# Dotfiles

macOS workstation setup. 한 repo에 두 얼굴이 공존한다.

- **macOS bootstrap** — Homebrew manifest, VSCode·Cursor·Ghostty·zsh 설정, Node·Bun·Vite+·Rust·Python toolchain, `macOS defaults write` tweaks.
- **Multi-AI harness hub** — `.agents/`에 instruction·subagent·command·rule·skill을 집약하고, symlink로 Claude Code·Codex·Gemini에 fan-out 한다.

## 저장소 구조

```
.setup.sh                  # 원격 bootstrap 진입점 (curl target)
.setup.main.sh             # local setup orchestrator
.setup.agents.sh           # global ~/.agents wiring
.setup.agents.project.sh   # 프로젝트별 agent scaffold
.brew.sh                   # brew bundle runner (.brewfile 사용)
.macos.sh                  # macOS defaults write tweaks
.brewfile, .brewfile.vscode# Homebrew + VSCode·Cursor 확장 manifest
AGENTS.md                  # → .agents/AGENTS.md (Codex·Gemini·repo-root용)
CLAUDE.md                  # 이 파일 (Claude Code가 repo root에서 읽음)
.agents/                   # canonical agent 자산 (아래 구조 참고)
.config/
  claude/settings.json     # Claude Code harness 설정 (tracked)
  ghostty/                 # 터미널 설정
  zsh/                     # init.zsh + style.zsh (~/.zshrc에서 로드)
  vscode/settings.json     # VSCode + Cursor 공용
  browserino/              # 브라우저 설정
```

## 진입 스크립트

| 스크립트 | 용도 |
|---|---|
| `.setup.sh` | 원격 bootstrap. Xcode CLT를 설치하고 `~/vscode/dotfiles`로 clone한 뒤, `.brew.sh`를 source하고 `.setup.main.sh`를 exec 한다. |
| `.setup.main.sh` | 전체 local setup. `.config/*` symlink, VSCode·Cursor 설정 wiring, nvm+Node 24+pnpm, Bun, Vite+ (`vp`), rustup, uv+Python 3.13, Claude Code, `gh`를 설치하고 `.setup.agents.sh`와 `.macos.sh`를 source 한다. |
| `.setup.agents.sh` | Global agent wiring (단독 실행 가능). |
| `.setup.agents.project.sh <dir>` | 타 프로젝트에 `.agents/` 구조를 scaffold 한다. |
| `.brew.sh` | `.brewfile`과 `.brewfile.vscode`로 `brew bundle`을 실행한다 (Code·Cursor 양쪽에 확장 설치). |
| `.macos.sh` | macOS Finder·Dock·키보드 defaults를 적용한다. |

모든 스크립트는 멱등하다. 이미 설치된 부분은 건너뛰며, symlink는 `rm -rf` 후 `ln -sfn`으로 교체한다.

## Symlink topology (runtime)

`.setup.main.sh`와 `.setup.agents.sh`가 실제로 연결하는 구조는 다음과 같다.

```
dotfiles/.agents ─► ~/.agents ─┬─► ~/.claude/{CLAUDE.md→AGENTS.md, commands, rules, skills}
                               └─► ~/.codex/{AGENTS.md, prompts→commands, rules}

dotfiles/.config/claude/settings.json ─► ~/.claude/settings.json   (직접 연결, ~/.agents 우회)
dotfiles/.config/{ghostty,zsh,vscode} ─► ~/.config/*
dotfiles/.config/vscode/settings.json ─► VSCode + Cursor user settings.json
```

Claude Code는 `AGENTS.md`를 native로 읽지 않는다 (`.setup.agents.project.sh:30-34`, claude-code issue #6235 참고). 그래서 사본을 두 벌 두는 대신 `CLAUDE.md → AGENTS.md` symlink를 유지한다.

## `.agents/` 구조

- `AGENTS.md` — canonical instruction (tone, 코딩 가이드). 이 머신의 모든 툴에 대한 단일 진실 공급원이다.
- `agents/` — subagent markdown 정의 (planner, code-reviewer, tdd-guide 등).
- `commands/` — slash command prompt template. `~/.claude/commands/`와 `~/.codex/prompts/`로 노출된다.
- `rules/` — 계층형 구성. `common/`(언어 무관)과 언어별 디렉터리(`typescript/`, `rust/`)로 나뉜다. 우선순위는 `rules/README.md`를 참고하라 (language-specific이 common을 덮어쓴다).
- `skills/` — progressive-disclosure skill 패키지. 각 패키지에는 `SKILL.md`와 선택적 bundle 리소스가 들어 있다.

## 자주 쓰는 workflow

- 전체 머신 bootstrap 또는 재동기화: `bash .setup.main.sh`
- Homebrew만 재실행: `bash .brew.sh`
- macOS defaults만 재실행: `bash .macos.sh`
- pull 후 agent symlink 재동기화: `bash .setup.agents.sh`
- 타 프로젝트에 agent 구조 scaffold: `bash .setup.agents.project.sh <path>`
- Claude 설정 편집: tracked 상태의 `.config/claude/settings.json`을 수정한다. `~/.claude/settings.json`이 symlink이므로 즉시 전파되어 setup을 재실행할 필요가 없다.
- 주기적 harness 점검 (월 1회 권장): `/dotfiles-validate`(symlink·schema·skill drift 4단계)와 `/harness-audit`(baseline 측정 → harness-optimizer 제안).

Test suite나 linter는 없다. Symlink 점검으로 검증한다: `ls -la ~/.claude ~/.agents ~/.config`.

## 편집 시 주의점

- `.agents/AGENTS.md`는 `~/.claude/CLAUDE.md` symlink를 통해 모든 Claude Code 세션에 전역으로 로드된다. 편집 즉시 이 머신의 모든 프로젝트에 영향을 준다.
- `~/.claude/` 아래에 rules·skills의 병렬 사본을 만들지 말라. 모두 `.agents/`로 향하는 symlink이므로, 원본은 `dotfiles/.agents/`에서 수정한다.
- `.setup.agents.project.sh`가 scaffold한 프로젝트 레벨 툴 디렉터리는 **상대** symlink(`../.agents/...`)를 사용한다. 프로젝트의 `.agents/`를 이동하거나 이름을 변경하면 link가 깨진다.
- `.brewfile`과 `.brewfile.vscode`는 `.brew.sh`가 같은 pass에서 함께 설치한다. 패키지·확장 목록을 변경할 때는 두 파일을 함께 조정하라.

## Multi-harness 경계

`.agents/` 자산은 Claude Code·Codex·Gemini에 symlink로 fan-out 된다. 다만 모든 자산이 harness 간에 호환되는 것은 아니다.

- Cross-harness (전 harness 공유): `AGENTS.md`, `commands/`, `skills/`, `rules/`
- Claude 전용: `.config/claude/settings.json`, `.agents/hooks/` (hooks JSON key조차 harness마다 다르다)

신규 자산을 추가할 때는 어느 category에 속하는지 명확히 밝힌다. Claude 전용 자산을 cross-harness 영역에 두지 말라.

## Source tracking convention

사람이 작성·관리하는 `.agents/` 자산 (agents·commands·hooks·rules) 에는 frontmatter `meta:` block이 필수다. 필드는 최소 2개를 둔다.

```yaml
meta:
  source: affaan-m/everything-claude-code  # 또는 native | <source>-derived
  updateDate: 2026-04-16
```

- `source` 값: `<user>/<repo>` (외부 차용) | `native` (자체 제작) | `<source>-derived` (영감을 받아 축약·재작성).
- `updateDate`: 마지막 동기화 또는 갱신 날짜 (YYYY-MM-DD).
- `hooks/*.sh`는 frontmatter가 없으므로, 파일 상단에 `# meta: source=... updateDate=...` 한 줄로 표기한다.
- `skills/`는 `rosie.lock` 자동 추적이 우선이므로 frontmatter `meta:`를 backfill하지 않는다.

## Skills 추적 정책

`.agents/skills/` 본체는 **어느 것도 git에 추적하지 않는다**. `.gitignore` 의 `.agents/skills/*/` 가 모든 스킬 디렉터리를 제외하고, `.gitkeep` 로 디렉터리 자체만 유지한다. 추적 대상은 `.agents/rosie.lock` (upstream 포인터 + commit SHA) 뿐이다. 관리 도구는 [`rosie`](https://github.com/matthewp/rosie) 이며 `.brewfile` 에 등재돼 있다.

- **lock 등재 스킬** (upstream 있음): 반드시 **레포 루트**에서 아래 명령으로 설치한다.
  ```bash
  rosie install <owner/repo> [skill] -a gemini-cli -y
  ```
  `-a gemini-cli` 의 skills 타깃 경로가 `.agents/skills` 이므로, canonical 실체가 거기에 직접 생기고 다른 agent 디렉터리(`.claude/skills` 등)로 fan-out 하는 부산물이 안 생긴다. skill 인자는 **하나만** 받으므로 같은 레포의 여러 스킬은 각각 호출한다. 설치 후 `rosie.lock` 에 `<name> <owner/repo> <ref> <sha> ...` 형식으로 자동 기록되어 commit SHA 가 핀된다. fresh 머신에서는 `.setup.agents.sh` 가 `rosie install -a gemini-cli -y` 로 lock 전체를 복원한다.
- **태그에 없는 스킬**: rosie 는 기본으로 레포의 최신 릴리스 태그를 받는다. `in-progress/` 같이 태그에서 제외된 경로의 스킬은 `<owner/repo>@main` 으로 ref 를 명시해야 한다 (lock 에 `pin` 으로 기록됨). 현재 해당 스킬 없음.
- **번들 리소스가 분리된 스킬**: rosie 는 서브경로의 `SKILL.md` 도 자동 discovery 한다 (예: `frontend-slides`). `npx skills` 시절 필요했던 수동 `skillPath` 보정은 더 이상 필요 없다.
- ⚠️ lock 스킬에 로컬 수정을 가하지 말 것 — `rosie update` 시 upstream 으로 덮어써진다. 커스터마이즈가 필요하면 로컬 자작 스킬로 분리한다.
- **갱신**: 반드시 `-a gemini-cli` 를 붙여 `rosie update -a gemini-cli [skill-name]` 으로 실행한다. `-a` 없이 `rosie update` 만 실행하면 install 때의 agent 한정이 풀려, 감지된 **모든** agent(`.claude`·`.cursor`·`.codex`·`.opencode`·`.continue`·`.pi`)의 repo-root 디렉터리로 스킬이 fan-out 되는 부산물이 생긴다. 만약 인자 없이 실행해 부산물이 생겼다면 `.agents/skills` 를 제외한 그 디렉터리들을 지운다 — 단 `.claude/commands/` 처럼 git 추적 파일이 섞인 경우 `.claude/` 를 통째로 지우지 말고 `.claude/skills/` 만 지운 뒤 `git checkout -- <추적파일>` 로 복원한다.
- **로컬 자작 스킬** (upstream 없음): git·lock 어디에도 들어가지 않는 로컬 전용이다. 이 머신 디스크에만 존재하므로 `git clean`·fresh clone 시 사라진다. 공유·백업이 필요해지면 별도 개인 skills 레포를 만들어 `rosie install` 로 등재한다. 현재 로컬 자작: `my-*` 8종.
