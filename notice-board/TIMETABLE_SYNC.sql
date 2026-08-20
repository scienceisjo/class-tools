-- ═══════════════════════════════════════════════════════════════════
-- 시간표 매일 자동 갱신 - 1단계 : 저장 자리 + 예약 실행
-- -------------------------------------------------------------------
-- 이 SQL 을 먼저 실행한 뒤, Edge Function(sync-timetable)을 올리세요.
-- 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


-- 1) 시간표 저장 표 (반 x 요일)
CREATE TABLE IF NOT EXISTS timetables (
  class_key  text NOT NULL,
  weekday    int  NOT NULL,
  periods    jsonb NOT NULL,
  source     text,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (class_key, weekday)
);

ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tt_public_read" ON timetables;
CREATE POLICY "tt_public_read" ON timetables FOR SELECT USING (true);

CREATE INDEX IF NOT EXISTS idx_tt_updated ON timetables(updated_at DESC);


-- 2) 갱신 기록
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


-- 3) 확장 기능 켜기
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;


-- 4) 기존 예약이 있으면 제거
DO $clean$
BEGIN
  PERFORM cron.unschedule('sync-timetable-daily');
EXCEPTION WHEN OTHERS THEN
  NULL;
END
$clean$;


-- ═══════════════════════════════════════════════════════════════════
-- 5) 매일 아침 8시 30분(한국시간) 자동 실행 등록
--
--    아래 SERVICE_ROLE_KEY_HERE 부분을 본인 키로 바꾼 뒤 실행하세요.
--    키 위치 : Supabase - Settings - API - service_role
--    (키 앞뒤의 따옴표는 지우지 마세요)
--
--    23:30 UTC = 다음날 08:30 한국시간 / 일~목 = 월~금 아침
-- ═══════════════════════════════════════════════════════════════════
SELECT cron.schedule(
  'sync-timetable-daily',
  '30 23 * * 0-4',
  $job$
  SELECT net.http_post(
    url     := 'https://hmzklbrksfdhzsgwzfyg.supabase.co/functions/v1/sync-timetable',
    headers := '{"Content-Type":"application/json","Authorization":"Bearer SERVICE_ROLE_KEY_HERE"}'::jsonb,
    body    := '{}'::jsonb
  );
  $job$
);


-- 6) 확인
SELECT jobname, schedule, active FROM cron.job WHERE jobname = 'sync-timetable-daily';
SELECT COUNT(*) AS saved_rows FROM timetables;
