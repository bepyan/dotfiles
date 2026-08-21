---
description: 유튜브 채널 전집을 수집해 제텔카스텐식 원자 노트로 쪼개고, 검증된 인용만으로 종합 리포트를 작성
argument-hint: "<채널 URL | @핸들> [--sample N | --all] [--dir <경로>]"
meta:
  source: native
  updateDate: 2026-08-14
---

대상 채널: $ARGUMENTS

## 목표

한 채널의 자막 전집을 진실원천으로 고정하고, 반복 등장하는 주장만 골라내 실천 가능한 지식베이스를 만든다.
핵심 원칙 세 가지:

1. **자막 원문은 한 번만 받고 지우지 않는다.** 재수집 비용이 가장 크다.
2. **모든 노트는 자막에서 잘라낸 verbatim 인용을 갖는다.** 인용이 원문에 없으면 그 노트는 리포트에 들어가지 않는다.
3. **분류 체계는 미리 정하지 않는다.** 노트를 다 만든 뒤 claim 목록을 보고 상향식으로 도출한다.

## 인자 해석

- 첫 인자: 채널 URL 또는 `@핸들`. `@핸들`만 오면 `https://www.youtube.com/<핸들>/videos`로 확장한다.
- `--sample N`: N개만 노트화한다 (기본값 50). 자막은 항상 전수 수집한다.
- `--all`: 전 영상을 노트화한다.
- `--dir <경로>`: 작업 디렉토리. 기본값은 현재 repo의 `research/<핸들-slug>/`.

슬러그는 핸들에서 `@`를 떼고 소문자화한다 (`@Hirenze` → `hirenze`).

## 사전 확인

```bash
command -v yt-dlp jq
```

- `yt-dlp` 없으면 중단하고 `brew install yt-dlp`를 안내한다.
- `textify`가 PATH에 없으면 textify-cli repo에서 `bun run src/index.ts`로 폴백한다. 두 경우 모두 아래 `$TEXTIFY`로 통일해 쓴다.

```bash
TEXTIFY=$(command -v textify || echo "bun run /path/to/textify-cli/src/index.ts")
```

작업 디렉토리가 git에 잡히지 않는지 확인한다. `git check-ignore -q <dir>`가 실패하면 `.gitignore`에 한 줄 추가하고 사용자에게 알린다.

## 디렉토리 구조

```
<dir>/
  meta/playlist.json        yt-dlp 원본 덤프
  meta/videos.jsonl         index·videoId·title·duration
  meta/failed.txt           자막 수집 실패 videoId (재시도용)
  meta/sample.jsonl         노트화 대상
  raw/<videoId>.txt         평문 자막 — 진실원천, 절대 수정·삭제 금지
  logs/fetch.err            yt-dlp/textify stderr
  notes/batch/*.jsonl       서브에이전트별 산출
  notes/atomic.jsonl        병합된 원자 노트
  notes/verified.jsonl      인용 검증 통과
  notes/quarantine.jsonl    인용 미매칭 — 리포트 제외
  notes/buckets.json        상향식 택소노미
  notes/principles/P##-*.md 상위 노트
  scripts/verify-quotes.ts  인용 검증기
  REPORT.md
  CHEATSHEET.md
```

## 1단계 — 영상 목록

```bash
mkdir -p "$DIR"/{meta,raw,logs,notes/batch,notes/principles,scripts}
yt-dlp --flat-playlist --no-warnings -J "$CHANNEL_URL" > "$DIR/meta/playlist.json"
jq -c '.entries | to_entries[] | {
  index: (.key + 1),
  videoId: .value.id,
  title: .value.title,
  duration: .value.duration
}' "$DIR/meta/playlist.json" > "$DIR/meta/videos.jsonl"
wc -l < "$DIR/meta/videos.jsonl"
```

검증: 줄 수가 채널 영상 수와 맞는지 확인하고 사용자에게 보고한다. 0줄이면 채널 URL 해석 실패이므로 중단한다.

**채널명은 반드시 메타데이터에서 읽는다.** 영상 제목이나 자막에서 추측하면 게스트 이름을 채널 운영자로 착각한다. 게스트 대담이 많은 채널에서는 제목에 전문가 이름이 자주 들어간다.

```bash
jq '{channel, uploader_id, channel_id}' "$DIR/meta/playlist.json"
```

`--flat-playlist`는 조회수·업로드일을 `NA`로 준다. 목록 순서가 최신순이므로 `index`를 시간축 프록시로 쓴다. 조회수 기준 정렬이 꼭 필요하면 영상별 메타데이터를 따로 조회해야 하고 수십 분이 더 든다 — 요청받지 않았으면 하지 않는다.

## 2단계 — 자막 전수 수집

```bash
cd "$DIR"
jq -r '.videoId' meta/videos.jsonl | xargs -P 3 -I {} sh -c '
  test -s "raw/{}.txt" && exit 0
  '"$TEXTIFY"' youtube subtitle "https://www.youtube.com/watch?v={}" \
    --output "raw/{}.txt" 2>>logs/fetch.err || echo "{}" >> meta/failed.txt
'
```

- **videoId를 watch URL로 감싸서 넘긴다.** YouTube videoId는 `-`로 시작할 수 있다(`-bQcrL_MkMg`). 최신 textify는 이런 ID를 그대로 넘겨도 동작하지만(`normalizeYoutubeArgv`), 구버전은 commander가 옵션으로 파싱해 `error: unknown option`으로 죽는다. URL 형태는 버전과 무관하게 안전하다. 395개 채널에서 6개가 이 경우였다.
- 이미 받은 파일은 건너뛴다. 중단 후 같은 명령을 다시 돌리면 이어서 받는다.
- `--lang`은 지정하지 않는다. textify가 수동 자막을 우선하고 그 중 원어(`-orig`)를 고르므로 원어 자막이 잡힌다.
- 동시성 3을 넘기지 않는다. YouTube가 429를 주면 `-P 1`로 낮춰 `meta/failed.txt`만 재시도한다.
- 오래 걸리므로 background로 돌리고, 진행 상황은 `ls raw | wc -l`로 확인한다.

검증: `ls raw/*.txt | wc -l` + `meta/failed.txt` 줄 수 = 전체 영상 수. 실패 목록이 비지 않으면 재시도 후 남은 것만 사용자에게 보고한다.

수집 후 자막 품질을 직접 확인한다. 자동 생성 자막은 문장 부호가 없고 4~8단어마다 개행돼 있다. 빈 파일이나 수십 바이트짜리 파일은 자막 없는 영상이므로 노트화 대상에서 제외한다.

```bash
find raw -name '*.txt' -size -1k
```

## 3단계 — 노트화 대상 표집

### 먼저 다국어 중복을 걸러낸다

많은 채널이 같은 내용을 다른 언어로 다시 올린다. **지지수가 이 리포트의 유일한 객관 지표인데, 번역·더빙판이 섞이면 같은 주장이 2회로 계수돼 지표가 무너진다.**

```bash
jq -r 'select(.title | test("[가-힣]") | not) | "\(.index)\t\(.title[0:50])"' meta/videos.jsonl | wc -l
```

제목에 한글이 없는 영상 비율을 먼저 확인한다. 무시할 수 없는 규모면(수 %를 넘으면) 모집단을 한국어로 좁힌다.

```bash
jq -c 'select(.title | test("[가-힣]"))' meta/videos.jsonl > meta/videos-ko.jsonl
```

**제목 언어와 자막 언어는 별개 축이다.** 제목이 한국어인데 자막만 영어인 영상이 섞인다. 자막 수집이 끝난 뒤 본문의 한글 비율로 한 번 더 검사한다.

```bash
for f in raw/*.txt; do
  ko=$(grep -o '[가-힣]' "$f" | wc -l); en=$(grep -o '[a-zA-Z]' "$f" | wc -l)
  [ $((ko * 2)) -lt $((ko + en)) ] && echo "$f ko=$ko en=$en"
done
```

걸린 영상은 표본에서 빼거나, 남기되 인용이 외국어라는 사실을 리포트에 표시한다. (참고: @Hirenze는 한국어 제목 233개 중 1개가 이 경우였다)

- 자막은 이미 전수 확보돼 있으므로 나중에 다른 언어판이 필요해도 재수집이 없다.
- 실천용 지식베이스라면 인용도 모국어로 남아야 바로 쓸 수 있다.
- 이 비율은 채널마다 크게 다르다. 확인 없이 넘어가지 않는다. (참고: @Hirenze는 395개 중 162개가 영어판이었다)

### 층화 표집

`--all`이면 위에서 좁힌 모집단 전체, 아니면 **인덱스 층화 표집**을 쓴다. 최신 N개만 뽑으면 특정 시기 포맷에 프롬프트가 과적합된다.

```bash
TOTAL=$(wc -l < meta/videos.jsonl | tr -d ' ')
STEP=$(( (TOTAL + SAMPLE - 1) / SAMPLE ))   # ceil. floor로 하면 뒤쪽 구간이 통째로 빠진다
awk -v s="$STEP" 'NR % s == 1' meta/videos.jsonl | head -n "$SAMPLE" > meta/sample.jsonl
jq -r '.index' meta/sample.jsonl | sed -n '1p;$p'   # 범위가 1 ~ (TOTAL 근처)인지 확인
```

`STEP`을 floor로 잡으면 `STEP × SAMPLE < TOTAL`이 되어 목록 끝(= 채널 초창기) 영상이 표본에 한 개도 안 들어간다. 표집 후 반드시 index 범위를 눈으로 확인한다.

## 4단계 — 원자 노트 추출 (서브에이전트 팬아웃)

`meta/sample.jsonl`을 5개씩 묶어 배치를 만들고, 배치 하나당 서브에이전트 하나를 병렬로 띄운다. 메인 컨텍스트에 자막 원문을 올리지 않는다 — 영상 1개가 2,000~5,000단어다.

각 서브에이전트에게 주는 지시:

> 아래 영상들의 자막 파일을 읽고 원자 노트를 추출해 `<dir>/notes/batch/<배치ID>.jsonl`에 쓴다.
> 영상: `<videoIndex> <videoId> <title>` (5개)
>
> 노트 한 줄의 스키마 (JSON 한 줄, 줄바꿈 없음):
>
> ```json
> {"id":"A0073-02","type":"rule","claim":"","quote":"","videoId":"","videoIndex":73,"title":"","bucket":null,"ts":null}
> ```
>
> - `id`: `A{videoIndex를 4자리로}-{영상 내 순번 2자리}`. 전역 시퀀스를 쓰지 않는다 — 배치 간 충돌한다.
> - `type`: 아래 셋 중 하나만.
>   - `rule` — 내가 당장 할 수 있는 행동 처방. "말 끝을 질문으로 되돌린다"
>   - `signal` — 상대를 판별하는 관찰 가능한 단서. "자기 얘기로만 화제를 돌리면 회피 신호"
>   - `mechanism` — 왜 그런지에 대한 설명·심리 기제. "통제감 상실이 방어를 유발한다"
> - `claim`: 한 문장. 하나의 주장만 담는다. 두 개면 노트 두 개로 쪼갠다. 영상 요약문을 쓰지 않는다.
> - `quote`: **자막 파일에서 그대로 잘라낸 연속된 구간.** 최소 20자. 요약·윤문·부호 추가 금지. 자막의 개행은 공백으로 바꿔도 되지만 단어를 바꾸면 안 된다. 사후 자동 검증에서 원문 대조에 실패하면 그 노트는 폐기된다.
> - 대담 영상 자막에는 화자 전환 마커(`>>`)가 있다. **마커를 넘어서 인용하지 않는다.** 넘기면 진행자와 게스트의 말이 한 인용에 섞이고, 마커를 지우고 이어 붙이면 검증에서 위조로 분류된다. 한 화자의 연속 구간 안에서만 자른다.
> - `bucket`, `ts`: 항상 `null`. 뒤 단계에서 채운다.
>
> 노트화하지 않을 것: 인사말, 구독·좋아요 요청, 협찬 고지, 다음 영상 예고, 진행자 잡담.
> 영상 1개당 보통 3~10개가 나온다. 억지로 개수를 채우지 않는다. 실질 내용이 없는 영상은 0개로 두고 그렇게 보고한다.
> 작업 마지막에 `wc -l <출력파일>`로 파일이 실제로 존재하고 줄 수가 맞는지 확인하고 그 결과를 응답에 포함한다.
> 최종 응답은 `배치ID, 처리한 영상 수, 생성한 노트 수, type별 개수, wc -l 출력`만 담는다. 노트 내용을 응답에 반복하지 않는다.

**에이전트 보고를 근거로 쓰지 않는다.** 배치가 끝나면 파일을 직접 센다. 실제로 겪은 사례: 13개 배치 중 하나가 "50개 노트 검증 통과"를 보고했지만 파일을 만들지 않았다. 보고를 합산했다면 그대로 넘어갔을 것이다.

```bash
cat notes/batch/*.jsonl | jq -r '.videoId' | sort -u | wc -l   # 표본 영상 수와 같아야 한다
```

노트 수는 배치마다 편차가 커서 이상 여부를 판단할 수 없다. **커버 영상 수가 가장 값싸고 확실한 검출 장치다.** 프롬프트에 위 확인 지시를 넣으면 누락 자체가 크게 줄어든다.

배치가 다 끝나면 병합한다.

```bash
cat notes/batch/*.jsonl > notes/atomic.jsonl
wc -l < notes/atomic.jsonl
```

## 5단계 — 인용 검증

`scripts/verify-quotes.ts`를 아래 내용으로 쓰고 실행한다.

```ts
// 인용이 실제 자막에 있는지 대조한다. 자동 자막은 개행·공백이 불규칙하므로
// 양쪽에서 공백과 문장 부호를 모두 제거한 뒤 substring으로 비교한다.
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const dir = process.argv[2];
if (!dir) {
  console.error("usage: bun scripts/verify-quotes.ts <research-dir>");
  process.exit(1);
}

const MIN_QUOTE_LENGTH = 15;

const normalize = (text: string): string =>
  text.normalize("NFC").replace(/[\s.,!?~"'“”‘’()[\]…·-]/g, "");

const rawCache = new Map<string, string>();
const loadRaw = (videoId: string): string | null => {
  const cached = rawCache.get(videoId);
  if (cached !== undefined) return cached;

  const path = join(dir, "raw", `${videoId}.txt`);
  if (!existsSync(path)) {
    rawCache.set(videoId, "");
    return null;
  }

  const normalized = normalize(readFileSync(path, "utf8"));
  rawCache.set(videoId, normalized);
  return normalized;
};

const lines = readFileSync(join(dir, "notes/atomic.jsonl"), "utf8")
  .split("\n")
  .filter((line) => line.trim().length > 0);

const verified: string[] = [];
const quarantine: string[] = [];
const reasons = new Map<string, number>();

const reject = (line: string, reason: string): void => {
  quarantine.push(JSON.stringify({ ...JSON.parse(line), rejectReason: reason }));
  reasons.set(reason, (reasons.get(reason) ?? 0) + 1);
};

for (const line of lines) {
  let note: { videoId?: string; quote?: string };
  try {
    note = JSON.parse(line);
  } catch {
    reasons.set("malformed-json", (reasons.get("malformed-json") ?? 0) + 1);
    quarantine.push(JSON.stringify({ rejectReason: "malformed-json", line }));
    continue;
  }

  const quote = normalize(note.quote ?? "");
  if (quote.length < MIN_QUOTE_LENGTH) {
    reject(line, "quote-too-short");
    continue;
  }

  const raw = note.videoId ? loadRaw(note.videoId) : null;
  if (raw === null) {
    reject(line, "raw-missing");
    continue;
  }

  if (!raw.includes(quote)) {
    reject(line, "quote-not-found");
    continue;
  }

  verified.push(line);
}

writeFileSync(join(dir, "notes/verified.jsonl"), verified.join("\n") + "\n");
writeFileSync(join(dir, "notes/quarantine.jsonl"), quarantine.join("\n") + (quarantine.length ? "\n" : ""));

const rate = lines.length === 0 ? 0 : (verified.length / lines.length) * 100;
console.log(`total ${lines.length} / verified ${verified.length} (${rate.toFixed(1)}%)`);
for (const [reason, count] of [...reasons].sort((a, b) => b[1] - a[1])) {
  console.log(`  ${reason}: ${count}`);
}
```

```bash
bun scripts/verify-quotes.ts .
```

판단 기준:

- 통과율 90% 이상이면 그대로 진행한다.
- 70~90%면 `quarantine.jsonl`의 실패 사유를 확인한다. `quote-not-found`가 몰린 배치가 있으면 그 배치만 재실행한다.
- 70% 미만이면 진행하지 말고 사용자에게 보고한다. 프롬프트나 자막 형식에 문제가 있다는 뜻이다.

## 6단계 — 상향식 클러스터링

claim만 뽑아 메인 컨텍스트에 올린다. 노트 500개면 2만 토큰 수준이라 한 번에 들어간다.

```bash
jq -r '[.id, .type, .claim] | @tsv' notes/verified.jsonl
```

이 목록만 보고 **자연 발생하는 주제 버킷**을 도출한다. 미리 정한 카테고리에 밀어넣지 않는다. 버킷 6~12개가 보통이고, 각 버킷은 서로 겹치지 않아야 한다.

`notes/buckets.json`:

```json
[
  {
    "id": "B01",
    "name": "경계 설정",
    "definition": "무엇을 거절하고 어디서 선을 긋는가",
    "noteIds": ["A0073-02", "A0121-01"]
  }
]
```

모든 verified 노트는 정확히 하나의 버킷에 속한다. 어디에도 안 맞는 노트는 `B99 미분류`에 모아두고 개수를 보고한다.

## 7단계 — 상위 노트

버킷 안에서 같은 주장이 여러 영상에 반복되면 원칙으로 승격한다. **지지수 = 그 주장을 뒷받침하는 서로 다른 영상의 수**이며, 클러스터링의 부산물로 공짜로 나온다. 이 채널에서 진짜 반복되는 원칙과 한 번 지나간 말을 가르는 유일한 객관 지표다.

`notes/principles/P07-질문으로-되받기.md`:

```markdown
---
id: P07
bucket: B03
title: 상대의 말을 질문으로 되받는다
type: rule
support: 6
refs: [A0073-02, A0121-01, A0245-03, A0301-01, A0333-02, A0377-01]
---

## 원칙

한 문단. 무엇을 하라는 것인지.

## 왜

연결된 mechanism 노트로 설명한다. 없으면 "채널에서 기제 설명 없음"이라고 쓴다.

## 판단 기준

연결된 signal 노트. 언제 이 원칙을 꺼내야 하는지.

## 근거

- [A0073-02] "자막 원문 인용" — [영상 제목](https://youtu.be/VIDEOID)
```

지지수 1인 노트도 버리지 않는다. 게스트 인터뷰의 1회성 통찰이 여기 있다. 리포트에서 `단발` 표시를 달아 따로 모은다.

두 가지를 반드시 지킨다.

- **인용문을 손으로 옮겨 적지 않는다.** 원칙 파일과 리포트를 생성하는 스크립트가 노트 id로 `verified.jsonl`에서 인용을 주입하게 만든다. 존재하지 않는 id를 참조하면 스크립트가 즉시 실패해야 한다. 검증을 통과한 인용이 리포트 작성 단계에서 다시 변형되면 앞의 검증이 무의미해진다.
- **원칙 본문도 검증 대상이다.** 인용과 claim은 기계로 검증되지만 `왜`/`언제`는 집필자가 쓴 산문이라 아무 검증도 통과하지 않는다. 본문을 문장 단위로 쪼개 각 원칙의 근거 claim과 대조하는 감사를 돌린다. 문장 분리는 결정적 스크립트가 한 곳에서만 하고(에이전트가 각자 쪼개면 병합 시 id가 어긋난다), 판정은 `supported` / `paraphrase` / `unsupported` 세 값으로 하며 흔들리면 `unsupported`로 둔다. 근거 없는 문장은 지우지 않고 표시한다. (참고: @Hirenze에서 본문 520문장 중 56개가 무근거였고, `원칙` 슬롯은 1.2%인데 `왜`/`언제`가 19%대였다. 채널이 규칙만 말하고 이유를 말하지 않은 원칙에서 상식으로 빈칸을 메운 결과다.)
- **지지수 1인 주장을 원칙으로 올리지 않는다.** 근거가 부족해 보이면 다른 영상 노트를 끌어와 지지수를 맞추고 싶어지는데, 그 순간 지표 자체가 죽는다. 단발로 내리고 그 사실을 리포트에 적는다.
- **후보 추출 단계에 개수 상한을 걸지 않는다.** "최대 N개"를 지시하면 두 가지 왜곡이 생긴다. 하나는 잘라내기 — 기준을 충족하는 후보가 조용히 사라진다. 다른 하나는 더 나쁜 병합 — 별개 주장 둘을 하나로 뭉쳐 목록에는 멀쩡히 있으면서 지지수만 부풀린다. 후보가 많아 곤란한 건 병합 단계에서 정리하면 되는 문제지, 추출 단계에서 미리 줄일 일이 아니다.
- 불가피하게 상한을 걸었다면 "상한 때문에 제외하거나 병합한 것이 있으면 전부 보고하라"를 붙이고, 보고된 것을 회수한다. 완료된 에이전트는 이름으로 다시 깨워 이어서 시킬 수 있으므로 입력을 처음부터 다시 읽히지 않는다. (참고: @Hirenze 확장에서 상한 때문에 사라질 뻔한 후보가 37개, 병합된 쌍이 3개였다.)
- **후보를 다 뽑은 뒤 한 번 더 묻는다.** "더 없나"라는 2패스 질문이 첫 패스에서 놓친 교차 연결을 실제로 찾아낸다. 특히 미매칭 claim을 영상별로 묶어 보고하게 하면 교차 연결이 가려지므로, 주제별로 다시 훑게 한다.

## 8단계 — 산출물

`REPORT.md`:

1. 머리말 — 채널 정보, 수집 범위(영상 수/노트 수/검증 통과율), 수집 일자
2. 버킷별 섹션 — 지지수 높은 원칙부터. 원칙 제목, 본문, 근거 인용 2~3개, 상위 노트 링크
3. 단발 통찰 — 지지수 1인데 버릴 수 없는 것들
4. 채널이 말하지 않는 것 — 자막 전체를 통틀어 다루지 않은 주제. 이 지식베이스의 경계를 명시한다
5. 방법론 부록 — 파이프라인 요약, quarantine 개수와 사유, 재현 명령

분량 상한은 두지 않는다. 지지수와 근거 링크가 붙지 않은 문장은 쓰지 않는다.

`CHEATSHEET.md`: 상황별 체크리스트 한 장. 원칙 설명이 아니라 상황 진입점으로 배열한다.

```markdown
## 처음 만난 사람과 대화할 때
- [ ] (P07) 상대 말을 질문으로 되받는다
- [ ] (P12) 내 얘기 비중을 3할 아래로

## 상대가 선을 넘을 때
- [ ] ...
```

## 확장

`--sample`로 시작해 리포트 초안을 리뷰한 뒤 전체로 넓힌다. 확장 시 재수집하는 것은 없다.

1. `meta/sample.jsonl`을 전체 목록으로 교체
2. 이미 처리한 영상은 `notes/atomic.jsonl`의 `videoIndex`로 걸러낸다
3. 남은 영상만 4단계부터 다시 돌린다
4. 버킷은 기존 것을 출발점으로 쓰되, 새 노트가 안 들어가는 주제가 생기면 버킷을 추가한다 — 억지로 기존 버킷에 밀어넣지 않는다

## 하지 말 것

- `raw/*.txt` 수정. 진실원천이다. 오타가 있어도 그대로 둔다.
- 인용을 매끄럽게 다듬기. 검증에서 걸러지고, 걸러지지 않으면 지식베이스가 거짓이 된다.
- 자막 원문을 메인 컨텍스트로 끌어오기. 서브에이전트가 파일을 직접 읽는다.
- 버킷을 먼저 정하고 노트를 분류하기. 채널이 실제로 무엇을 반복하는지 못 본다.
- 지지수 없는 원칙 서술. 근거 링크가 없으면 그 문장은 리포트에 들어갈 자격이 없다.
