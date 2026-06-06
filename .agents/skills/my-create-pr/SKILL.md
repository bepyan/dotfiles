---
name: my-create-pr
description: >
  GitHub PR 생성 워크플로우. JIRA 티켓 키를 브랜치명에서 추출하고, PR 제목/설명을 JIRA 연동으로
  작성한 뒤 `gh pr create`로 생성하고, 마지막으로 JIRA 티켓을 Resolve 상태로 전이한다.
  Use when user says "create PR", "make PR", "open PR", "/create-pr", or asks to generate a PR.
compatibility: Requires gh CLI, jq, curl, and JIRA_ACCESS_TOKEN in environment.
---

# Create PR

아래 작업 흐름에 따라 GitHub PR를 생성한다.
이 단계들 중 하나라도 실패하면, 사용자에게 도움을 요청한다.

## When to Use

- Feature 브랜치 작업 완료 후 PR 생성
- Bugfix 브랜치를 main/base 브랜치로 PR 생성
- 사용자가 "PR 열어줘", "create PR", "PR 생성" 요청
- JIRA 티켓 연동이 필요한 PR

## Process

### 1. 환경변수 확인

`JIRA_ISSUE_KEY`: 브랜치명에서 티켓 키(`PROJECT-NUMBER`)를 추출한다.
티켓 키 뒤에 설명 접미사가 붙는 브랜치(`feature/PCWSSFE-965-dashboard`)에서도 동작하도록 키 패턴을 매칭한다.

```bash
JIRA_ISSUE_KEY=$(git branch --show-current | grep -oE '[A-Z]+-[0-9]+')
```

`JIRA_ACCESS_TOKEN`: `~/.zshenv`에 설정되어 있다.
**Secrets 취급**에 유의한다. 존재 확인은 `[ -n "${VAR}" ]` 또는 `${VAR:?msg}`로 진행한다.

`TARGET_BRANCH`: 가능하면 워크스페이스 시스템에서 추출한다. 명확하지 않으면 사용자에게 입력을 요구한다.

### 2. PR 정보 세팅

**title:**

JIRA API로 티켓 제목을 조회한 뒤 PR 제목을 작성한다.

```bash
JIRA_ISSUE_TITLE=$(curl -s -X GET \
  "https://jira.daumkakao.com/rest/api/2/issue/${JIRA_ISSUE_KEY}" \
  -H "Authorization: Bearer ${JIRA_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  | jq -r '.fields.summary')
```

포맷: `[JIRA_ISSUE_KEY] JIRA_ISSUE_TITLE`
예: `[PCWSSFE-768] [위자드] openWizard 제거`

**description:**

핵심 원칙:
- 최대 200줄로 작성한다.
- 간결하고, 사실에 기반하며, 리뷰어 중심으로 작성한다.
- 짧은 문장, 현재 시제, 능동태를 사용한다.
- '무엇'보다 '왜'에 집중한다. '무엇'이 변경되었는지는 diff가 보여준다.

작업 순서:
1. diff 컨텍스트를 가져온다. (staged changes, branch diff, 또는 PR diff)
2. 무엇이 '왜' 변경되었는지 파악한다.
3. 아래 템플릿에 따라 description을 작성한다.

템플릿:

```markdown
[JIRA_ISSUE_KEY]

## 작업 내용

[한줄_요약]

[전후_비교]
```

**한줄_요약:**

PR 제목을 PR 내용에 맞춰 간략히 설명한다.
- 간결함을 위해 추상적인 단어를 써도 좋다. 자세한 설명은 diff가 제공한다.
- 한 문장에 60글자 미만으로 작성한다.

**전후_비교:**

```markdown
**Before:**

⒈ [problem outcome]

[ASCII diagram]

⒉ [user/system effect]

**After:**

⒈ [fixed outcome]

[ASCII diagram]

⒉ [improvement achieved]
```

- 코드를 줄줄이 나열하지 않고 핵심만 작성한다.
- 번호는 마크다운 문법이 깨지지 않도록 이모지를 사용한다.
- `Before` 섹션의 번호와 `After` 섹션의 번호는 1:1 매핑되어야 한다.
- `ASCII diagram`은 시각화가 필요한 경우에만 포함한다.
- 요구되지 않는 한, 템플릿에 없는 섹션은 작성하지 않는다. (ex: 커밋 구성, 검증)

### 3. PR 생성

`gh pr create` 명령어로 PR을 생성한다.
사용자가 draft PR을 요구한다면 `--draft` 파라미터를 추가한다.

```bash
gh pr create --base ${TARGET_BRANCH} --title <title> --body <description> --assignee @me
```

### 4. JIRA 티켓을 Resolve 상태로 전이

```bash
curl -X POST \
  "https://jira.daumkakao.com/rest/api/2/issue/${JIRA_ISSUE_KEY}/transitions" \
  -H "Authorization: Bearer ${JIRA_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "transition": {
      "id": "31"
    }
  }'
```

`204` 응답은 JIRA 상태 전이 성공을 뜻한다.
