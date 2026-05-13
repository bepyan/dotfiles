## post

`textify naver-blog post <blogId/logNo-or-url> [--format markdown|json] [--output <path>]`

- `--format` 기본 `json`. 후속 파싱/메타데이터가 필요하면 `json`, 사람이 바로 읽을 본문이면 `markdown`.
- json 스키마: `{ blogId, logNo, title, url, thumbnailUrl|null, publishedAt|null, markdown }`

예: `textify naver-blog post ranto28/224028693561 --format markdown`

## post-list

`textify naver-blog post-list <blogId-or-url> [--page N] [--output <path>]`

- `--page` 는 `post-list` 에만 적용. 기본 `1`, 1 이상의 정수, 30개/페이지.
- 스키마: `{ page, hasNext, postList: [{ blogId, logNo, title, url, thumbnailUrl|null, publishedAt|null }] }`

예: `textify naver-blog post-list ranto28 --page 2`
