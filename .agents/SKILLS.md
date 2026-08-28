# Skills

`.agents/skills/` 본체는 git에 추적하지 않는다. 추적 대상은 `.agents/rosie.lock` (upstream 포인터 + commit SHA). 관리 도구는 [rosie](https://github.com/matthewp/rosie).

## 설치

레포 루트에서:

```bash
rosie install <owner/repo> [skill] -a gemini-cli -y
```

`-a gemini-cli`의 skills 타깃이 `.agents/skills`이므로 canonical 실체가 거기에 직접 생기고, 다른 agent 디렉터리로 fan-out 하지 않는다. skill 인자는 하나만 받는다. 같은 레포의 여러 스킬은 각각 호출한다.

설치 후 `rosie.lock`에 `<name> <owner/repo> <ref> <sha> ...`로 기록되어 SHA가 핀된다. fresh 머신에서는 `.setup.agents.sh`가 `rosie install -a gemini-cli -y`로 lock 전체를 복원한다.

## 갱신

```bash
rosie update -a gemini-cli [skill-name]
```

`-a` 없이 `rosie update`만 실행하면 install 때의 agent 한정이 풀려, 감지된 모든 agent의 repo-root 디렉터리로 스킬이 fan-out 된다.

부산물이 생겼다면 `.agents/skills`만 남기고 레포 루트의 다른 `*/skills/`를 지운다. `.claude/commands/`처럼 git 추적 파일이 섞인 디렉터리는 통째로 지우지 말고 `skills/`만 지운 뒤 추적 파일을 복원한다.

lock 스킬에 로컬 수정을 가하지 않는다. `rosie update` 시 upstream으로 덮어써진다. 커스터마이즈는 로컬 자작으로 분리한다.

## 태그·번들

rosie는 기본으로 최신 릴리스 태그를 받는다. 태그에서 제외된 경로의 스킬은 `<owner/repo>@main`으로 ref를 명시한다 (lock에 `pin`).

서브경로의 `SKILL.md`도 자동 발견한다.

## 로컬 자작

upstream 없는 스킬은 git·lock 어디에도 들어가지 않는다. 이 머신 디스크에만 있으므로 `git clean`·fresh clone 시 사라진다. 공유가 필요하면 별도 레포를 만들어 `rosie install`로 등재한다. 로컬 전용 이름은 `my-*`.
