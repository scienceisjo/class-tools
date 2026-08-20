// ═══════════════════════════════════════════════════════════════════
// ⏰ sync-timetable — 컴시간알리미에서 학교 시간표를 받아 Supabase 에 저장
// ───────────────────────────────────────────────────────────────────
// Supabase Edge Function (Deno)
// 매일 아침 8:30(KST) 자동 실행되어 그날의 변경까지 반영합니다.
//
// 왜 서버에서 하나:
//   컴시간은 http 전용이고 CORS 를 허용하지 않아 브라우저에서 직접 못 부릅니다.
//   서버(Deno)는 그 제약이 없습니다.
// ═══════════════════════════════════════════════════════════════════

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SCHOOL_CODE = "90186";        // 해누리중학교 (컴시간 코드)
const COMCI_HOST  = "comci.net";
const COMCI_PORT  = 4082;

// 컴시간 조회 규칙 — 학교 페이지의 스크립트에서 확인한 값
const QUERY_PREFIX = "73629_";
const QUERY_PATH   = "36179";

async function fetchComcigan() {
  const q = btoa(`${QUERY_PREFIX}${SCHOOL_CODE}_0_1`);
  const url = `http://${COMCI_HOST}:${COMCI_PORT}/${QUERY_PATH}?${q}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`컴시간 응답 오류 ${res.status}`);
  const text = new TextDecoder("utf-8").decode(await res.arrayBuffer());
  const json = text.slice(0, text.lastIndexOf("}") + 1);
  return JSON.parse(json);
}

// 코드값 → 과목명  (분리값으로 나눈 몫이 과목, 나머지가 교사)
function subjectOf(code: number, subjects: string[], sep: number) {
  if (!code) return "";
  return subjects[Math.floor(code / sep)] ?? "";
}

function buildRows(d: any) {
  const subjects: string[] = d["자료492"];
  const sep: number        = d["분리"];
  const base               = d["자료481"];   // 기본 시간표
  const changed            = d["자료147"];   // 이번 주 변경 반영본
  const rows: any[] = [];

  const gradeCount = base[0];
  for (let g = 1; g <= gradeCount; g++) {
    const classCount = base[g][0];
    for (let c = 1; c <= classCount; c++) {
      for (let dy = 1; dy <= 5; dy++) {
        // 변경본이 비어 있지 않으면 그것을, 아니면 기본표를 쓴다
        const chgDay  = changed?.[g]?.[c]?.[dy];
        const baseDay = base[g][c][dy];
        const day = (chgDay && chgDay[0] > 0) ? chgDay : baseDay;
        if (!day || !day[0]) continue;

        const periods: string[] = [];
        for (let p = 1; p <= day[0]; p++) {
          periods.push(subjectOf(day[p] ?? 0, subjects, sep));
        }
        rows.push({
          class_key: `${g}-${c}`,
          weekday: dy,
          periods,
          source: (chgDay && chgDay[0] > 0) ? "comcigan(변경반영)" : "comcigan",
        });
      }
    }
  }
  return rows;
}

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,   // RLS 우회 (서버 전용 키)
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

    return new Response(
      JSON.stringify({ ok: true, rows: rows.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    await supabase.from("timetable_sync_log")
      .insert({ ok: false, rows: 0, message: msg });
    return new Response(
      JSON.stringify({ ok: false, error: msg }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
