---
name: textify
description: 사용자가 'textify'를 명시적으로 언급했거나, 지원 provider의 웹 콘텐츠 추출을 요청할 때 사용. 웹 콘텐츠를 Markdown/JSON으로 변환하는 CLI.
---

호출: `textify <provider> <command> <args> [options]`

- 먼저 `command -v textify` 와 `textify --help` 로 설치/실행 가능 여부를 확인
- 전제: `textify` 명령이 PATH에 있어야 함.
- 기본 결과 채널은 stdout
- `--output <path>` 시 파일 저장 후 절대경로를 stdout으로 출력
- stderr는 상태/진단 메시지에 사용될 수 있음. 실패 여부는 stderr 존재만으로 판단하지 말고 exit code로 판정

Provider:

- `naver-blog` (`post`, `post-list`) → 본문 추출/목록 조회, `providers/naver-blog.md`
- `youtube` (`subtitle`) → 평문 자막 추출, `providers/youtube.md`
