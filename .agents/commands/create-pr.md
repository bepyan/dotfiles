---
description: PR 생성 규칙
meta:
  source: native
  updateDate: 2026-05-07
---

아래 작업 흐름에 따라 Github PR를 생성한다.
이 단계들 중 하나라도 실패하면, 사용자에게 도움을 요청한다.

## 1. 환경변수 확인

`JIRA_ISSUE_KEY`: 브랜치명에서 티켓 번호를 추출한다.
```shell
JIRA_ISSUE_KEY=$(git branch --show-current | sed 's|.*/||')
```

`JIRA_ACCESS_TOKEN`: `~/.zshenv`에 설정되어 있다.
**Secrets 취급**에 유의해야 한다. 존재 확인은 `[ -n "${VAR}" ]` 또는 `${VAR:?msg}` 로 진행한다.

`TARGET_BRANCH`: 가능한면 워크스페이스 시스템에서 추출한다. 명확하지 않는다면 사용자에게 입력을 요구한다.

## 2. PR 정보 세팅

### title

JIRA 티켓 제목 바탕 PR 제목을 작성한다.

```shell
JIRA_ISSUE_TITLE=$(curl -s -X GET \
  "https://jira.daumkakao.com/rest/api/2/issue/${JIRA_ISSUE_KEY}" \
  -H "Authorization: Bearer ${JIRA_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  | jq -r '.fields.summary')
```

`[JIRA_ISSUE_KEY] JIRA_ISSUE_TITLE` ex: `[PCWSSFE-768] [위자드] openWizard 제거`

### description

**핵심 원칙**

- 최대 200줄로 작성한다.
- 간결하고, 사실에 기반하며, 리뷰어 중심으로 작성한다.
- 짧은 문장, 현재 시제, 능동태를 사용한다.
- '무엇'보다 '왜'에 집중한다. '무엇'이 변경되었는지는 diff가 보여주기 때문이다.

**작업 순서**

1. diff 컨텍스트를 가져온다. (staged changes, branch diff, 또는 PR diff)
2. 무엇이 '왜' 변경되었는지 파악한다.
3. 아래 템플릿에 따라 description을 작성한다.

**템플릿**

```markdown
[JIRA_ISSUE_KEY]

## 작업 내용

[한줄_요약]

[전후_비교]
```

**한줄_요약**

이 PR이 달성하는 바를 간략히 설명한다.
- '왜'에 집중해서 설명한다.
- 간결함을 위해 추상적인 단어를 써도 좋다. 자세한 설명은 다른 곳에서 작성될 것이기 때문이다.

**전후_비교**

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

- 코드를 줄줄이 업급하지 않고, 핵심만 작성한다.
- 번호는 마크다운 문법이 깨지지 않도록 이모지를 사용한다.
- `Before` 색션의 번호와 `After` 색션의 번호는 1:1 매핑되어야 한다.
- `ASCII diagram`은 시각화가 필요할 경우에만 포함한다.
- 요구되지 않는 한, 템플릿에 없는 색션은 작성하지 않는다. 
  - ex: 커밋 구성, 검증 ...

## 3. PR 생성

`gh pr create` 명령어를 활용해 PR을 생성한다.
사용자가 draft PR를 요구한다면 `--draft` 파라미터를 추가한다.

```shell
gh pr create --base ${TARGET_BRANCH} --title <title> --body <description> --assignee @me
```

## 4. JIRA 티켓를 `Resolve` 상태로 수정

```shell
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
