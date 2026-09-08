-- ═══════════════════════════════════════════════════════════════════
-- 🔁 시간표 변경 표시 칸 추가
-- -------------------------------------------------------------------
-- 컴시간은 바뀐 교시를 ">6011" 처럼 앞에 기호를 붙여 알려주는데,
-- 그동안 그 기호를 못 읽어서 그 교시가 빈칸이 되고 있었습니다.
-- (빈칸이 되니 화면은 NEIS 의 옛 시간표를 대신 보여주고 있었습니다)
--
-- 이제 바뀐 교시를 제대로 읽어서, 어느 교시가 바뀌었는지도 함께
-- 저장합니다. 교실 화면에서 그 교시에 🔁 변경 표시가 붙습니다.
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE timetables
  ADD COLUMN IF NOT EXISTS changed int[] NOT NULL DEFAULT '{}';


-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'timetables'
ORDER BY ordinal_position;
--   -> 목록에 changed 가 보이면 정상입니다.
--
-- 그다음 sync-timetable 함수를 새 코드로 한 번 배포하고,
-- Supabase 대시보드에서 함수를 한 번 실행(또는 아래 줄 실행)하면
-- 바로 반영됩니다.
--
-- SELECT net.http_post(
--   url     := 'https://hmzklbrksfdhzsgwzfyg.supabase.co/functions/v1/sync-timetable',
--   headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtemtsYnJrc2ZkaHpzZ3d6ZnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MTY4NDcsImV4cCI6MjA5NTA5Mjg0N30.LuTEeJyu-mtkNzUTNaA8IigmdtWPWXS2ucVgXDeevPA"}'::jsonb,
--   body    := '{}'::jsonb
-- );
