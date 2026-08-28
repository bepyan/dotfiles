# Dotfiles

macOS workstation setup. 한 repo에 두 얼굴이 공존한다.

- **macOS bootstrap** — Homebrew, 에디터·터미널·쉘, toolchain, `defaults write`.
- **Multi-AI harness hub** — `.agents/`에 instruction·subagent·command·rule·skill을 집약하고, symlink로 Claude Code·Codex·Gemini에 fan-out 한다.

이 파일은 **이 레포에서 작업할 때만** 로드된다. 전역 행동 규칙은 `.agents/AGENTS.md`.

## 불변식

- 에이전트 자산의 원본은 `.agents/`. `~/.agents`가 중개하고 `~/.claude`·`~/.codex`로 fan-out 한다. `~/.claude/` 아래에 사본을 만들지 말고 원본만 고친다.
- `.config/claude/`는 Claude 전용이며 `~/.claude/`로 직접 연결된다 (`~/.agents` 우회). 나머지 `.config/`는 setup 스크립트가 홈으로 링크한다.
- 루트 `AGENTS.md`는 이 파일로의 심링크다. Codex·Gemini가 루트 `AGENTS.md`를 읽기 때문이다.
- 부트스트랩은 `.setup*.sh`, `.brew.sh`, `.macos.sh`. 모두 멱등이다. 패키지·버전·파일 목록은 그 파일들과 `.brewfile*`이 진실이다. `.brewfile`과 `.brewfile.vscode`는 같은 pass에서 설치한다.
- Cross-harness: `AGENTS.md`, `commands/`, `skills/`, `rules/`. Claude 전용: `.config/claude/`, `.agents/hooks/`. 신규 자산은 어느 쪽인지 밝히고, Claude 전용을 cross-harness 영역에 두지 않는다.
- Skills 설치·갱신·로컬 자작: `.agents/SKILLS.md`. 본체는 git 밖, `rosie.lock`만 추적. 레포 루트에서 `rosie … -a gemini-cli`. `-a` 없으면 다른 agent 디렉터리로 fan-out 한다.

## Source tracking

사람이 작성하는 `.agents/` 자산 (agents·commands·hooks·rules)에는 frontmatter `meta:`가 필수다.

```yaml
meta:
  source: native # <user>/<repo> | native | <source>-derived
  updateDate: YYYY-MM-DD
```

`hooks/*.sh`는 파일 상단 `# meta: source=... updateDate=...`. `skills/`는 `rosie.lock`이 추적하므로 `meta:`를 넣지 않는다.

## 이 파일을 고치는 때

harness가 늘거나, canonical 경로가 바뀌거나, cross-harness 경계가 바뀔 때.
패키지·버전·파일 하나 추가로는 고치지 않는다.
