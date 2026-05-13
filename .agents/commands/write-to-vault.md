---
description: 외부 콘텐츠를 Tolaria vault 노트로 정리
argument-hint: '[url | filepath | pasted text] [--vault <path-or-url>] [--topic <wikilink>] [--title "exact title"]'
meta:
  source: native
  updateDate: 2026-05-13
---

작업 대상: $ARGUMENTS

기본 목적은 외부 콘텐츠(블로그 글, 유튜브 영상, 문서, 메모)를 **vault note**로 저장하는 것이다.

## 기본 원칙

- 특별한 요구사항이 없다면 먼저 `/tldr` 커맨드를 트리거해 **일관된 요약 포맷**을 만든 뒤, 그 결과를 vault note 본문에 사용한다.
- note의 **제목은 원본 콘텐츠의 제목을 그대로 사용**한다.
  - 영문 제목이면 번역하지 않는다.
  - 임의로 더 짧게 줄이거나 꾸미지 않는다.
- 원본 링크가 있으면 파일 **최상단(frontmatter)** 에 `url:`로 넣는다.
- 저장 전 반드시 기존 vault의 topic/note를 탐색해, 새 노트를 적절한 기존 주제와 연결한다.
- 가능하면 새 topic을 만들기보다 **기존 topic에 연결**한다.

## Vault 대상

- 기본 vault 대상: `/Users/edward.kk/vscode/tolaria-vault`
- 다만 추후 다른 vault로 바꿀 수 있도록, **vault 경로/URL override 가능성**을 항상 열어 둔다.
- 사용자가 `--vault <path-or-url>`를 주면 그것을 우선한다.
- `--vault`가 없으면 기본 vault를 사용한다.
- vault가 로컬 경로라면 해당 vault의 `AGENTS.md`를 먼저 읽고 그 규칙을 따른다.

## 진행 절차

1. **입력 해석**
   - 입력이 URL이면 원문을 읽는다.
   - 입력이 파일 경로면 파일을 읽는다.
   - 입력이 붙여넣은 텍스트면 그것을 원문으로 사용한다.
   - `--title`이 있으면 제목 후보로 사용하되, 원문에 명시된 원제와 충돌하면 원문 제목을 우선한다.

2. **대상 vault 규칙 확인**
   - 대상 vault의 `AGENTS.md`가 있으면 먼저 읽는다.
   - 파일명 규칙, frontmatter 규칙, 관계 필드(`belongs_to`, `related_to`)를 확인한다.

3. **기존 topic 탐색**
   - vault 루트의 topic note와 기존 note들을 탐색한다.
   - 아래를 우선적으로 본다.
     - 같은 주제의 topic note
     - 같은 저자/채널/person note
     - 비슷한 키워드로 연결된 기존 note
   - 새 note는 최소 한 곳 이상 기존 graph와 연결한다.
   - 가장 자연스러운 관계를 우선 사용한다.
     - 주제가 분명하면 `belongs_to`
     - 직접적인 소속보다 연관성이 중심이면 `related_to`

4. **제목/파일명 결정**
   - 본문 H1 제목은 원본 콘텐츠 제목을 그대로 사용한다.
   - 파일명은 vault 관례에 맞춰 생성한다.
     - 기본은 kebab-case
     - 원제의 의미를 임의로 바꾸지 않는다

5. **본문 작성**
   - 특별한 형식 요구가 없다면 `/tldr` 결과를 본문으로 사용한다.
   - `/tldr` 출력 앞뒤로 불필요한 설명은 추가하지 않는다.
   - 원본 링크가 있으면 본문 첫 줄에 다시 반복하지 말고 frontmatter `url:`에만 둔다. 단, 대상 vault의 기존 문서 관례가 본문 raw URL도 함께 두는 구조라면 그 관례를 따른다.

6. **저장**
   - 새 note를 대상 vault에 저장한다.
   - 기존 note와의 연결(wikilink)이 깨지지 않는지 확인한다.

## 기본 note 템플릿

특별한 요구가 없으면 아래 구조를 따른다.

```/dev/null/write-to-vault-template.md#L1-12
---
type: Note
belongs_to: "[[existing-topic]]"
url: https://example.com
---

# Exact Source Title

## ⚡️ TL;DR

...
```

관계가 하나로 애매하면 다음처럼 사용할 수 있다.

```/dev/null/write-to-vault-template.md#L14-21
---
type: Note
related_to:
  - "[[existing-topic]]"
  - "[[existing-note-or-person]]"
url: https://example.com
---
```

## 연결 규칙

- 기존에 `ai`, `fe`, `growth`, `llm-wiki` 같은 topic이 있으면 먼저 그쪽 연결 가능성을 검토한다.
- 저자/채널/person note가 이미 있으면 함께 연결한다.
- 동일 주제 note가 여러 개 있으면, 가장 직접적인 topic 하나를 `belongs_to`로 두고 나머지는 `related_to`로 둔다.
- 적절한 기존 topic이 전혀 없을 때만 새 topic 생성을 검토한다.

## 우선순위

1. vault 규칙 준수
2. 제목 원문 보존
3. 기존 graph와의 연결
4. `/tldr` 기반의 일관된 요약 포맷
5. 최소한의 수동 장식

## 산출물

기본적으로 아래를 반환한다.

1. 저장한 note 경로
2. 연결한 topic/note 목록
3. 새로 만든 항목이 있다면 그 이유
