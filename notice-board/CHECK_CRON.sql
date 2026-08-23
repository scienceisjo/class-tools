-- ═══════════════════════════════════════════════════════════════════
-- 시간표 자동 갱신이 도는지 점검
-- -------------------------------------------------------------------
-- 1단계만 실행해서 결과를 보시고, 필요하면 2단계를 실행하세요.
-- ═══════════════════════════════════════════════════════════════════


-- ═══ 1단계 : 진단 ═══════════════════════════════════════════════

-- (가) 예약이 등록되어 있는가
SELECT jobid, jobname, schedule, active
FROM cron.job
WHERE jobname = 'sync-timetable-daily';
--   -> 0행이면 예약 자체가 없습니다 (TIMETABLE_SYNC.sql 을 실행해야 함)


-- (나) 예약이 실제로 실행됐는가 (최근 10회)
SELECT start_time, status, return_message
FROM cron.job_run_details
WHERE jobname = 'sync-timetable-daily'
ORDER BY start_time DESC
LIMIT 10;
--   -> 0행이면 한 번도 안 돌았습니다
--   -> status 가 failed 면 실행은 됐으나 실패


-- (다) 서버가 보낸 요청의 응답 (가장 중요)
SELECT id, status_code, LEFT(content, 200) AS response, created
FROM net._http_response
ORDER BY id DESC
LIMIT 10;
--   -> 401 이면 service_role 키가 잘못 들어갔습니다  ← 가장 흔한 원인
--   -> 200 이면 정상 호출된 것


-- ═══ 2단계 : 예약 다시 등록 ═════════════════════════════════════
-- 아래 SERVICE_ROLE_KEY_HERE 를 실제 키로 바꾼 뒤 실행하세요.
-- 키 위치 : Supabase - Settings - API - service_role (secret)
-- 따옴표는 지우지 말고 글자만 바꿔주세요.

DO $clean$
BEGIN
  PERFORM cron.unschedule('sync-timetable-daily');
EXCEPTION WHEN OTHERS THEN
  NULL;
END
$clean$;

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


-- ═══ 3단계 : 지금 바로 한 번 실행해서 확인 ═══════════════════════
-- 위와 같은 키로 바꾼 뒤 실행하면, 예약을 기다리지 않고 즉시 갱신됩니다.
SELECT net.http_post(
  url     := 'https://hmzklbrksfdhzsgwzfyg.supabase.co/functions/v1/sync-timetable',
  headers := '{"Content-Type":"application/json","Authorization":"Bearer SERVICE_ROLE_KEY_HERE"}'::jsonb,
  body    := '{}'::jsonb
);

-- 10초쯤 뒤에 아래를 실행해 결과를 확인하세요.
-- SELECT status_code, LEFT(content,200) FROM net._http_response ORDER BY id DESC LIMIT 1;
-- SELECT ok, rows, message, created_at FROM timetable_sync_log ORDER BY id DESC LIMIT 3;
