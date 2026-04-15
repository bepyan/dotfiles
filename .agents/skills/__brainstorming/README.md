# __brainstorming

구현 전 설계를 탐색하는 대화형 skill. 아이디어 → 명확한 spec까지를 한 번의 대화로 수렴시키고, 승인된 spec이 나오기 전에는 어떤 구현도 시작하지 않는다(HARD GATE).

원본은 [obra/superpowers](https://github.com/obra/superpowers)의 `brainstorming` skill. 본 복사본은 `.skill-lock.json`에서 분리되어 있어 upstream sync에 덮이지 않는다.

## 언제 호출하나

기능 추가, 컴포넌트 제작, 동작 수정 등 **새로 무언가를 짓는 모든 작업의 초입**. 간단해 보여도 호출한다 — skill 내부 Anti-Pattern 섹션 참고.

대화에서 `/__brainstorming` 또는 자연어로 "브레인스토밍 해줘"로 기동.

## 산출물 위치

| 경로 | 내용 | 영속성 |
|---|---|---|
| `.brainstorm/specs/YYYY-MM-DD-<topic>-design.md` | 최종 design spec | 휘발. `.gitignore` 권장 |
| `.brainstorm/sessions/<session-id>/` | visual companion mockup/이벤트 로그 | 휘발 |

### `.gitignore`

프로젝트 루트에 다음 한 줄 추가:

```
.brainstorm/
```

### spec을 보존하고 싶을 때

`.brainstorm/specs/`는 의도적으로 휘발성. spec이 장기적 가치를 가진다고 판단하면 `docs/`(또는 팀 컨벤션 위치)로 **직접 이동**한다. 그게 skill과 영구 문서 저장소를 분리한 이유 — brainstorm 결과물 자동 축적을 막아 stale spec이 쌓이지 않도록 한다.

## Visual Companion

선택 기능. 브라우저로 mockup을 보여주며 A/B/C 선택을 받는다. 질문 성격이 **시각적일 때만** 제안된다(요구사항/트레이드오프 대화는 터미널 유지).

- 서버 실행: `scripts/start-server.sh --project-dir <프로젝트 루트>`
- 정지: `scripts/stop-server.sh <session_dir>`
- 자세한 내용: [visual-companion.md](./visual-companion.md)

## 구성 파일

| 파일 | 역할 |
|---|---|
| `SKILL.md` | skill 본문. 프로세스/체크리스트/프로세스 플로우 |
| `visual-companion.md` | 브라우저 companion 상세 가이드 |
| `spec-document-reviewer-prompt.md` | spec 자체 검수용 subagent 프롬프트 템플릿 |
| `scripts/start-server.sh` · `stop-server.sh` | companion 서버 기동/정지 |
| `scripts/server.cjs` · `helper.js` · `frame-template.html` | companion 런타임 (수정 불필요) |

## 흐름 요약

1. 프로젝트 컨텍스트 탐색 (files, docs, commits)
2. 필요 시 visual companion 제안
3. 한 번에 한 질문씩 요구사항/제약 확인
4. 2~3개 접근 제시 + 추천
5. 섹션별 design 제시 → 승인
6. spec 작성 (`.brainstorm/specs/`)
7. spec self-review (placeholder/모순/모호성/스코프)
8. 사용자 최종 검토
9. 승인된 spec을 구현 단계로 인계 (자동 skill 호출 없음 — 사용자가 주도)

## 커스터마이즈 포인트

- spec 경로 기본값: `SKILL.md` L29, L111 / `spec-document-reviewer-prompt.md` L7
- 세션 경로 기본값: `scripts/start-server.sh` L9, L81 / `visual-companion.md` 전역
- 한국어 spec의 후처리: `humanizer` skill 사용 권장 (`SKILL.md` L116 부근)
