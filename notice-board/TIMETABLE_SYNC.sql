-- ═══════════════════════════════════════════════════════════════════
-- ⏰ 시간표 매일 자동 갱신 — 1단계: 저장 자리 + 예약 실행
-- ───────────────────────────────────────────────────────────────────
-- 이 SQL 을 먼저 실행한 뒤, Edge Function(sync-timetable)을 올리세요.
-- 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════

-- ① 시간표 저장 표 (반 × 요일)
CREATE TABLE IF NOT EXISTS timetables (
  class_key  text NOT NULL,          -- '2-3'
  weekday    int  NOT NULL,          -- 1=월 … 5=금
  periods    jsonb NOT NULL,         -- ["과학B","기가","기술", ...]
  source     text,                   -- 'comcigan'
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (class_key, weekday)
);

ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;

-- 전자칠판(익명)이 읽어야 하므로 공개 읽기
DROP POLICY IF EXISTS "tt_public_read" ON timetables;
CREATE POLICY "tt_public_read" ON timetables FOR SELECT USING (true);

-- 쓰기는 서버(Edge Function, service_role)만 → 별도 정책 없음
--   service_role 은 RLS 를 우회하므로 정책이 없어도 기록됩니다.

CREATE INDEX IF NOT EXISTS idx_tt_updated ON timetables(updated_at DESC);


-- ② 갱신 기록 (언제 성공/실패했는지)
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


-- ③ 매일 아침 8시 30분(한국시간)에 자동 실행
--    Supabase 서버는 UTC 로 도므로 23:30 UTC = 다음날 08:30 KST
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ⚠️ 아래 두 값을 본인 것으로 바꾼 뒤 실행하세요.
--    PROJECT_REF : hmzklbrksfdhzsgwzfyg
--    SERVICE_KEY : Supabase → Settings → API → service_role key
DO $$
DECLARE
  project_ref text := 'hmzklbrksfdhzsgwzfyg';
  service_key text := '여기에_service_role_키_붙여넣기';
BEGIN
  -- 기존 예약이 있으면 지우고 다시 등록
  PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = 'sync-timetable-daily';

  PERFORM cron.schedule(
    'sync-timetable-daily',
    '30 23 * * 0-4',      -- 일~목 23:30 UTC = 월~금 08:30 KST
    format($cron$
      SELECT net.http_post(
        url     := 'https://%s.supabase.co/functions/v1/sync-timetable',
        headers := jsonb_build_object(
                     'Content-Type','application/json',
                     'Authorization','Bearer %s'),
        body    := '{}'::jsonb
      );
    $cron$, project_ref, service_key)
  );
END$$;


-- ═══════════════════════════════════════════════════════════════════
-- 📋 확인
-- ═══════════════════════════════════════════════════════════════════
SELECT jobname, schedule, active FROM cron.job WHERE jobname = 'sync-timetable-daily';
SELECT COUNT(*) AS 저장된_시간표_행 FROM timetables;
