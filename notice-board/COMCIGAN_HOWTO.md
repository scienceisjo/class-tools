# 컴시간알리미 시간표 자동 연동 — 인계서

> 이 문서를 Claude 에게 통째로 붙여넣고 이렇게 말씀하세요:
> **"이 인계서대로 우리 학교 시간표 자동 연동을 만들어줘. 학교 이름은 ○○중학교야."**
>
> 해누리중학교(조승재)에서 2026년 9월에 실제로 돌리고 있는 방식 그대로입니다.
> 소스: https://github.com/scienceisjo/class-tools/tree/main/notice-board/edge-function

---

## Claude 에게 — 먼저 읽어주세요

당신의 역할은 **선생님의 학교 시간표를 컴시간알리미에서 매일 자동으로 받아와 DB에 저장하는 시스템**을 만드는 것입니다. 아래 내용은 이미 검증된 방법이므로 새로 설계하지 말고 그대로 따르세요.

시작하기 전에 선생님께 세 가지만 여쭤보세요:

1. **학교 이름** (컴시간 학교코드를 찾기 위해)
2. **백엔드** — Supabase 를 쓰시는지, 아니면 다른 것(Cloudflare Worker · Vercel · Google Apps Script 등)인지. 이 문서는 Supabase 기준이고 §7 에 다른 백엔드 요령이 있습니다.
3. **시간표를 어디에 보여줄 건지** — 이미 만든 화면이 있는지, 새로 만들어야 하는지

선생님이 개발자가 아닐 수 있으니 SQL 이나 코드를 드릴 때는 **"어디에 붙여넣고 어떤 버튼을 누르는지"** 까지 함께 적어주세요. 브라우저 자동번역이 켜져 있으면 SQL 식별자가 번역되어 깨지니, 복사하실 때 번역을 끄시라고 꼭 안내하세요.

---

## 1. 원리 — 왜 이렇게 하나

컴시간알리미에는 공식 API 가 없습니다. 대신 **컴시간 홈페이지가 자기 시간표를 그릴 때 부르는 주소**가 있고, 그걸 그대로 부르면 학교 전체 시간표가 JSON 으로 옵니다.

```
http://comci.net:4082/36179?<base64("73629_" + 학교코드 + "_0_1")>
```

제약이 둘 있습니다.

| 제약 | 결과 |
|---|---|
| **http 전용** (https 아님) | https 페이지에서 직접 못 부름 |
| **CORS 허용 안 함** | 브라우저 JS 로 못 부름 |

→ 그래서 **서버에서 하루 한 번 받아 DB 에 넣고, 화면은 DB 만 읽습니다.**

```
컴시간 (http://comci.net:4082)
   │  매일 08:30 KST — 예약 작업이 깨움
   ▼
서버 함수 (Supabase Edge Function / Deno)   ← fetch + 해독
   │
   ▼
timetables 표 (반·요일별 과목 + 바뀐 교시 번호)
   │
   ▼
화면 (REST 로 읽기만, 로그인 불필요)
```

---

## 2. 학교코드 찾기

컴시간 학교코드는 NEIS 학교코드와 **다릅니다.** 5자리 숫자입니다 (예: 해누리중 = 90186).

찾는 법 (쉬운 순):

1. **컴시간알리미 담당 실무사님께 여쭤보기** — 관리 화면에 나옵니다.
2. **컴시간알리미 사이트에서 검색** — `http://컴시간알리미.kr` 에서 학교 이름 검색 → 개발자도구(F12) → Network 탭 → `comci.net:4082` 로 가는 요청의 주소를 base64 디코드하면 `73629_90186_0_1` 처럼 코드가 보입니다.
3. **npm `comcigan-parser`** 의 `search('학교이름')` 기능.

코드를 얻었으면 §3 의 SCHOOL_CODE 에 넣습니다.

---

## 3. 응답 해독 규칙 (가장 중요)

응답은 JSON 인데 **뒤에 쓰레기 문자가 붙어 있습니다.** 마지막 `}` 까지만 잘라서 파싱하세요.

```js
const txt  = new TextDecoder("utf-8").decode(await res.arrayBuffer());
const json = txt.slice(0, txt.lastIndexOf("}") + 1);
const d    = JSON.parse(json);
```

쓰는 키는 다섯 개입니다.

| 키 | 내용 | 모양 |
|---|---|---|
| `자료492` | 과목명 목록 | `[33, "국어A", "국어B", ...]` — **[0]은 개수**, 과목은 1부터 |
| `분리` | 나눗셈 기준 | `1000` |
| `자료481` | 원래 시간표 | `[학년][반][요일][교시]` — 각 배열의 **[0]은 개수** |
| `자료147` | **이번 주 변경(결보강) 반영본** | 자료481 과 같은 모양 |
| `자료244` | 컴시간 최종수정 시각 | `"2026-09-07 09:46:06"` |

참고용: `학급수` = `[전체, 1학년반수, 2학년반수, 3학년반수]`, `자료446` = 교사명 목록, `요일별시수` = 학년별 요일별 교시 수.

### 코드 → 과목

교시마다 숫자 코드가 옵니다. 예 `12025`.

```
과목 index = Math.floor(코드 / 분리)   → 12  → 자료492[12] = "과학A"
교사 index = 코드 % 분리                → 25  → 자료446[25]
```

### ⚠️ 결보강 함정 — 여기서 대부분 막힙니다

`자료147` 에서 **바뀐 교시는 숫자가 아니라 문자열**로 옵니다.

```
원래(자료481) : [7, 12024, 1007, 4002, ...]      → 과학A · 국어A · 독서 …
변경(자료147) : [7, ">6011", 1007, 4002, ...]    → ??? · 국어A · 독서 …
```

`">6011"` 을 그냥 나누면 `NaN` → 과목이 빈칸이 됩니다. **숫자만 뽑아서** 쓰세요.

```js
function codeOf(v) {
  if (typeof v === "number") return v;
  if (typeof v === "string") return Number(v.replace(/[^0-9]/g, "")) || 0;
  return 0;
}
```

그리고 원래 표(자료481)와 **과목이 다르면 "변경된 교시"** 로 기록해 두면, 화면에 🔁 표시를 붙일 수 있습니다. 교사만 바뀐 보강(과목은 같음)은 학생에겐 의미가 없으니 표시하지 않는 걸 권합니다.

---

## 4. Supabase 준비 — SQL

Supabase → **SQL Editor** 에 붙여넣고 Run. 여러 번 실행해도 안전합니다.

```sql
-- 1) 시간표 표 (반 × 요일 한 줄)
CREATE TABLE IF NOT EXISTS timetables (
  class_key  text NOT NULL,          -- '2-3'
  weekday    int  NOT NULL,          -- 1=월 … 5=금
  periods    jsonb NOT NULL,         -- ["과학A","국어A",...]
  changed    int[] NOT NULL DEFAULT '{}',   -- 결보강으로 바뀐 교시 번호
  source     text,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (class_key, weekday)
);
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tt_public_read" ON timetables;
CREATE POLICY "tt_public_read" ON timetables FOR SELECT USING (true);

-- 2) 갱신 기록 (잘 돌고 있는지 확인용)
CREATE TABLE IF NOT EXISTS timetable_sync_log (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ok         boolean,
  rows       int,
  message    text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE timetable_sync_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ttlog_read" ON timetable_sync_log;
CREATE POLICY "ttlog_read" ON timetable_sync_log FOR SELECT USING (true);

-- 3) 덮어쓸 때도 갱신 시각이 바뀌도록 (DEFAULT now() 는 새로 넣을 때만 적용됨)
CREATE OR REPLACE FUNCTION touch_timetable_updated()
RETURNS trigger LANGUAGE plpgsql AS $fn$
BEGIN NEW.updated_at := now(); RETURN NEW; END
$fn$;
DROP TRIGGER IF EXISTS trg_timetables_touch ON timetables;
CREATE TRIGGER trg_timetables_touch
  BEFORE UPDATE ON timetables FOR EACH ROW EXECUTE FUNCTION touch_timetable_updated();

-- 4) 예약 실행에 필요한 확장
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
```

---

## 5. Edge Function — `sync-timetable`

Supabase → **Edge Functions** → **Deploy a new function** (또는 Create) → 이름 `sync-timetable` → 아래 코드를 `index.ts` 에 붙여넣기 → **Deploy**.

`SCHOOL_CODE` 만 바꾸면 됩니다. `SUPABASE_URL` 과 `SUPABASE_SERVICE_ROLE_KEY` 는 Supabase 가 함수에 자동으로 넣어줍니다 (직접 적지 마세요).

```typescript
// sync-timetable — 컴시간알리미에서 학교 시간표를 받아 Supabase 에 저장
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SCHOOL_CODE = "90186";        // ← 우리 학교 컴시간 코드로 바꾸세요
const COMCI_HOST  = "comci.net";
const COMCI_PORT  = 4082;

// 컴시간 페이지 스크립트에 박혀 있는 값. 컴시간이 바꾸면 같이 바꿔야 합니다 (§8 참고)
const QUERY_PREFIX = "73629_";
const QUERY_PATH   = "36179";

async function fetchComcigan() {
  const q = btoa(`${QUERY_PREFIX}${SCHOOL_CODE}_0_1`);
  const url = `http://${COMCI_HOST}:${COMCI_PORT}/${QUERY_PATH}?${q}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`컴시간 응답 오류 ${res.status}`);
  const text = new TextDecoder("utf-8").decode(await res.arrayBuffer());
  return JSON.parse(text.slice(0, text.lastIndexOf("}") + 1));
}

// 바뀐 교시는 ">6011" 처럼 문자열로 오므로 숫자만 뽑는다
function codeOf(v: unknown): number {
  if (typeof v === "number") return v;
  if (typeof v === "string") return Number(v.replace(/[^0-9]/g, "")) || 0;
  return 0;
}

function subjectOf(v: unknown, subjects: string[], sep: number) {
  const code = codeOf(v);
  if (!code) return "";
  return subjects[Math.floor(code / sep)] ?? "";
}

function buildRows(d: any) {
  const subjects: string[] = d["자료492"];
  const sep: number        = d["분리"];
  const base               = d["자료481"];   // 원래 시간표
  const changed            = d["자료147"];   // 이번 주 변경 반영본
  const rows: any[] = [];

  const gradeCount = base[0];
  for (let g = 1; g <= gradeCount; g++) {
    const classCount = base[g][0];
    for (let c = 1; c <= classCount; c++) {
      for (let dy = 1; dy <= 5; dy++) {
        const chgDay  = changed?.[g]?.[c]?.[dy];
        const baseDay = base[g][c][dy];
        const day = (chgDay && chgDay[0] > 0) ? chgDay : baseDay;
        if (!day || !day[0]) continue;

        const periods: string[] = [];
        const chgList: number[] = [];     // 과목이 실제로 바뀐 교시
        for (let p = 1; p <= day[0]; p++) {
          const now = subjectOf(day[p], subjects, sep);
          periods.push(now);
          if (day === chgDay) {
            const was = subjectOf(baseDay?.[p], subjects, sep);
            if (was && now && was !== now) chgList.push(p);   // 교사만 바뀐 보강은 제외
          }
        }
        rows.push({
          class_key: `${g}-${c}`,
          weekday: dy,
          periods,
          changed: chgList,
          source: (chgDay && chgDay[0] > 0) ? "comcigan(변경반영)" : "comcigan",
          updated_at: new Date().toISOString(),
        });
      }
    }
  }
  return rows;
}

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  try {
    const data = await fetchComcigan();
    const rows = buildRows(data);
    if (!rows.length) throw new Error("시간표를 한 건도 읽지 못했습니다");

    const { error } = await supabase
      .from("timetables")
      .upsert(rows, { onConflict: "class_key,weekday" });
    if (error) throw error;

    await supabase.from("timetable_sync_log").insert({
      ok: true, rows: rows.length,
      message: `갱신 완료 (컴시간 최종수정 ${data["자료244"] ?? "?"})`,
    });
    return new Response(JSON.stringify({ ok: true, rows: rows.length }),
      { headers: { "Content-Type": "application/json" } });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    await supabase.from("timetable_sync_log").insert({ ok: false, rows: 0, message: msg });
    return new Response(JSON.stringify({ ok: false, error: msg }),
      { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
```

---

## 6. 매일 아침 자동 실행 + 지금 한 번 실행

Supabase → **SQL Editor**. 두 곳을 바꾸세요:
- `PROJECT_REF` → 본인 프로젝트 ref (Settings → General 에 있는 20자 영문)
- `ANON_KEY` → Settings → API → **anon public** 키 (service_role 아님 — 함수를 깨우기만 하므로 공개키로 충분합니다)

```sql
-- 기존 예약 제거
DO $c$ BEGIN PERFORM cron.unschedule('sync-timetable-daily'); EXCEPTION WHEN OTHERS THEN NULL; END $c$;

-- 매일 08:30 KST (= 23:30 UTC 전날, 일~목 = 월~금 아침)
SELECT cron.schedule(
  'sync-timetable-daily',
  '30 23 * * 0-4',
  $job$
  SELECT net.http_post(
    url     := 'https://PROJECT_REF.supabase.co/functions/v1/sync-timetable',
    headers := '{"Content-Type":"application/json","Authorization":"Bearer ANON_KEY"}'::jsonb,
    body    := '{}'::jsonb
  );
  $job$
);

-- 지금 바로 한 번 실행 (예약 기다리지 않고)
SELECT net.http_post(
  url     := 'https://PROJECT_REF.supabase.co/functions/v1/sync-timetable',
  headers := '{"Content-Type":"application/json","Authorization":"Bearer ANON_KEY"}'::jsonb,
  body    := '{}'::jsonb
);
```

`http_post` 결과로 숫자 하나가 나오면 **접수번호**일 뿐입니다. 10초쯤 뒤에 아래로 확인하세요.

```sql
-- 응답 확인 : status_code 200 + {"ok":true,"rows":145} 면 성공
SELECT status_code, LEFT(content, 200) FROM net._http_response ORDER BY id DESC LIMIT 3;

-- 저장된 시간표 확인
SELECT class_key, weekday, periods, changed FROM timetables ORDER BY class_key, weekday LIMIT 10;

-- 갱신 기록
SELECT ok, rows, message, created_at FROM timetable_sync_log ORDER BY id DESC LIMIT 3;
```

| 응답 | 뜻 |
|---|---|
| 200 `{"ok":true,"rows":145}` | 성공 (rows = 반 수 × 5) |
| 401 `Invalid JWT` | ANON_KEY 를 안 바꿨거나 잘못 붙임 |
| 404 | 함수 이름이 `sync-timetable` 이 아님 |
| 500 `컴시간 응답 오류` | 학교코드 확인 / §8 |

---

## 7. 화면에서 읽기

로그인 없이 anon 키로 읽으면 됩니다.

```js
const { data } = await sb.from('timetables')
  .select('class_key,weekday,periods,changed,updated_at');

// 우리 반 오늘 시간표
const today = new Date().getDay();               // 1=월 … 5=금
const row = data.find(r => r.class_key === '2-3' && r.weekday === today);
row.periods.forEach((subj, i) => {
  const p = i + 1;
  const mark = row.changed.includes(p) ? ' 🔁 변경' : '';
  console.log(`${p}교시 ${subj}${mark}`);
});
```

### Supabase 가 아니라면

서버 함수와 예약만 갈아끼우면 됩니다. 해독 로직(§3, `buildRows`)은 그대로 씁니다.

| 백엔드 | 서버 함수 | 예약 | 저장 |
|---|---|---|---|
| Cloudflare Worker | Worker (fetch 가능) | Cron Trigger | KV 또는 D1 |
| Vercel | Serverless Function | Vercel Cron | 아무 DB / Blob |
| Google Apps Script | `UrlFetchApp.fetch` (http 됨) | 시간 기반 트리거 | Google Sheet |

GAS 는 서버·예약·저장이 한 곳에 있어 **가장 간단**합니다. 시트에 넣고 화면은 시트를 JSON 으로 읽으면 됩니다.

---

## 8. 함정과 대비

**① `36179` / `73629_` 가 바뀔 수 있습니다.**
이 값은 학교별이 아니라 컴시간 전체 공통이고, 컴시간이 업데이트하면 바뀝니다. 갑자기 500 이 나오면 여기부터 의심하세요. 확인법: `http://컴시간알리미.kr` 학교 페이지의 스크립트 소스에서 `sc_data(` 또는 `'36179?'` 같은 문자열을 찾습니다. npm `comcigan-parser` 는 이 값을 매번 페이지에서 자동으로 긁어오니, 더 튼튼하게 만들고 싶으면 그 방식을 참고하세요.

**② 하루 한 번만 부르세요.** 학교 자기 시간표를 학교 화면에 띄우는 용도라 문제없지만, 비공식 경로이니 자주 두드리지 않는 게 예의입니다.

**③ 응답 인코딩은 UTF-8** 입니다. PowerShell 등에서 깨져 보이면 클라이언트 쪽 문제입니다.

**④ 요일 바꿔 수업하는 날** (예: 10/7 은 금요일 시간표) 은 컴시간에 반영되지 않습니다. 화면 쪽에서 날짜→요일 표를 따로 두세요.

**⑤ 분반 과목**(과학A/B, 국어A/B 등)은 그대로 옵니다. 그게 컴시간을 쓰는 이유이기도 합니다 — NEIS 시간표 API 는 분반이 안 나옵니다.

**⑥ 과목이 빈칸으로 나오면** 거의 100% §3 의 `">` 문자열` 문제입니다. `codeOf` 를 빠뜨렸는지 확인하세요.

---

## 9. 완료 확인 체크리스트

- [ ] SQL 실행 후 `timetables`, `timetable_sync_log` 표가 보인다
- [ ] Edge Function `sync-timetable` 이 Deploy 되었다
- [ ] 수동 실행 응답이 `{"ok":true,"rows":N}` 이다 (N = 반 수 × 5)
- [ ] `timetables` 에 빈칸(`""`)인 과목이 없다
- [ ] 실무사님이 결보강을 넣은 반의 `changed` 에 교시 번호가 들어 있다
- [ ] `cron.job` 에 `sync-timetable-daily` 가 active = true 로 보인다
- [ ] 다음날 아침 08:31 에 `timetable_sync_log` 에 새 줄이 생겼다

---

작성: 조승재 (해누리중학교 과학정보부) · 2026-09-13
동작 중인 원본: https://github.com/scienceisjo/class-tools/tree/main/notice-board
