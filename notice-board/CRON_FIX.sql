-- ═══════════════════════════════════════════════════════════════════
-- 시간표 자동 갱신 예약 - 바로 실행 가능 (키가 이미 채워져 있습니다)
-- -------------------------------------------------------------------
-- 앞서 401 Invalid JWT 가 났던 이유 : 키 자리가 안 채워져 있었음
-- 이 파일은 고칠 곳이 없습니다. 그대로 복사해서 실행하세요.
--
-- 참고 : 여기 쓰인 키는 공개용(anon) 키입니다.
--        이 함수는 시간표를 받아 저장하기만 하므로 안전합니다.
-- ═══════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;


-- 1) 기존 예약 제거
DO $clean$
BEGIN
  PERFORM cron.unschedule('sync-timetable-daily');
EXCEPTION WHEN OTHERS THEN
  NULL;
END
$clean$;


-- 2) 매일 아침 8시 30분(한국시간) 자동 실행 등록
--    23:30 UTC = 다음날 08:30 KST / 일~목 = 월~금 아침
SELECT cron.schedule(
  'sync-timetable-daily',
  '30 23 * * 0-4',
  $job$
  SELECT net.http_post(
    url     := 'https://hmzklbrksfdhzsgwzfyg.supabase.co/functions/v1/sync-timetable',
    headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtemtsYnJrc2ZkaHpzZ3d6ZnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MTY4NDcsImV4cCI6MjA5NTA5Mjg0N30.LuTEeJyu-mtkNzUTNaA8IigmdtWPWXS2ucVgXDeevPA"}'::jsonb,
    body    := '{}'::jsonb
  );
  $job$
);


-- 3) 예약을 기다리지 않고 지금 한 번 실행 (동작 확인용)
SELECT net.http_post(
  url     := 'https://hmzklbrksfdhzsgwzfyg.supabase.co/functions/v1/sync-timetable',
  headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtemtsYnJrc2ZkaHpzZ3d6ZnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MTY4NDcsImV4cCI6MjA5NTA5Mjg0N30.LuTEeJyu-mtkNzUTNaA8IigmdtWPWXS2ucVgXDeevPA"}'::jsonb,
  body    := '{}'::jsonb
);


-- ═══════════════════════════════════════════════════════════════════
-- 4) 10초쯤 기다린 뒤, 아래를 따로 실행해서 확인하세요
-- ═══════════════════════════════════════════════════════════════════
-- SELECT status_code, LEFT(content,200) AS response
-- FROM net._http_response ORDER BY id DESC LIMIT 3;
--    -> status_code 가 200 이고 response 에 {"ok":true,"rows":145} 면 성공
--
-- SELECT ok, rows, message, created_at
-- FROM timetable_sync_log ORDER BY id DESC LIMIT 3;
--    -> 방금 시각으로 새 기록이 생겼으면 완료
--
-- SELECT jobname, schedule, active FROM cron.job;
--    -> sync-timetable-daily / 30 23 * * 0-4 / true
