## subtitle

`textify youtube subtitle <videoId-or-url> [--lang <code>] [--output <path>]`

- 이 명령은 `yt-dlp` 가 필요함. 실행 전 `command -v yt-dlp` 또는 `yt-dlp --version` 으로 확인.
- `<videoId-or-url>`: `videoId` 또는 YouTube 영상 URL.
- `--lang`: 자막 언어 코드. 결과를 결정적으로 고정해야 하면 항상 명시. 지정하지 않으면 사용 가능한 자막 중 기본 후보를 선택.
- 성공 중에도 자막 다운로드 진행 메시지가 stderr에 출력될 수 있음. 실패 여부는 exit code로 판단.
- 출력은 타임스탬프/메타데이터를 제거한 줄바꿈 기반 평문 자막.

예:

- `textify youtube subtitle NwNvW0lLVtc`
- `textify youtube subtitle https://www.youtube.com/watch?v=NwNvW0lLVtc --lang ko-orig`
