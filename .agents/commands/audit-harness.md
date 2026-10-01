---
description: agentic harness 정량 베이스라인 측정 (존재 계측 + 실사용 계측)
meta:
  source: ecc-derived
  updateDate: 2026-09-21
---

현재 harness 의 정량 베이스라인을 직접 측정한다. 서브에이전트를 쓰지 않는다.

측정은 두 축이다. **존재 계측**은 무엇이 설치돼 있는지 세고, **실사용 계측**은 그게 실제로 불렸는지 센다. 존재 계측만 보면 "설치 N개, meta 커버리지 100%" 같은 건강해 보이는 숫자가 나오지만, 쓰이지 않는 자산은 시스템 프롬프트만 차지한다. 둘을 나란히 놓아야 판단이 선다.

## 1. 존재 계측

1. **Hooks**: `.config/claude/settings.json` 의 `hooks.*` 배열 항목 수, 이벤트별 분포
2. **Commands**: `~/.agents/commands/*.md` 파일 수 (`__` prefix 는 별도 카운트)
3. **Skills**: `~/.agents/rosie.lock` 의 등록 수 vs `~/.agents/skills/` 실제 디렉토리 수. 차이가 로컬 자작분이다
4. **Skill 신선도**: lock 의 `updatedAt` 최신값과 최오래값
5. **MCP 서버**: `~/.claude.json` 의 `mcpServers` 키 수, repo 의 `.mcp.json`
6. **meta 커버리지**: commands 중 frontmatter `meta:` 블록 보유 비율, 누락 파일 리스트

## 2. 실사용 계측

`~/.claude/projects/**/*.jsonl` 이 모든 turn 을 기록한다. 여기서 세는 게 핵심이다.

```sh
# 세션 수 (subagent 파일 제외)
fd -e jsonl . ~/.claude/projects | grep -v '/subagents/' | wc -l

# 집계 기간
fd -e jsonl . ~/.claude/projects -x stat -f "%Sm" -t "%Y-%m-%d" {} | sort -u | sed -n '1p;$p'

# subagent 호출 집계
rg -o '"subagent_type":"[a-zA-Z0-9_-]+"' -N --no-filename ~/.claude/projects \
  | sed 's/.*://; s/"//g' | sort | uniq -c | sort -rn

# skill 호출 집계
rg -o '"skill":"[a-zA-Z0-9_:-]+"' -N --no-filename ~/.claude/projects \
  | sed 's/.*://; s/"//g' | sort | uniq -c | sort -rn | head -20
```

주의할 점 둘.

- **자기 호출 배제**: 이 명령어를 서브에이전트로 돌리면 그 호출이 집계에 잡힌다. 호출이 기록된 파일이 현재 세션 id 인지 확인한다.
- **빌트인과 커스텀 분리**: `Explore`, `general-purpose`, `Plan` 은 Claude Code 기본 제공이다. 커스텀 자산의 효용은 빌트인 호출 수와 비교해야 의미가 있다.

## 3. 참조 경로 계측

설치돼 있어도 부르는 곳이 없으면 트리거 경로가 없는 것이다.

```sh
rg -n "<asset-name>" ~/.agents --glob '!**/<asset-dir>/*'
```

commands, rules, skills, AGENTS.md 에서 각 자산 이름의 참조 수를 센다. 참조 0 + 호출 0 이면 제거 후보다.

## 산출물

| 영역 | 설치 | 호출 | 참조 | 비고 |
|---|---|---|---|---|
| hooks | N | | | 이벤트별 분포 |
| commands | N | N회 | | `__` prefix 제외 |
| skills | N | N회 | | lock vs dir |
| MCP servers | N | | | 0이면 권고 |
| skill-lock 최오래 | YYYY-MM-DD | | | 90일 이내 목표 |
| meta 커버리지 | X% | | | 100% 목표, 누락 리스트 |

후속: top 3 leverage 영역 식별 + 최소 변경 제안. 설치 대비 호출이 현저히 낮은 레이어를 먼저 본다.
