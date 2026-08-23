-- ═══════════════════════════════════════════════════════════════════
-- 시간표 "마지막 갱신 시각" 이 안 바뀌던 문제 수정
-- -------------------------------------------------------------------
-- 원인 : DEFAULT now() 는 새로 넣을 때만 적용되고,
--        기존 행을 덮어쓸 때는 예전 시각이 그대로 남습니다.
-- 조치 : 값이 바뀌든 안 바뀌든 갱신될 때마다 시각을 새로 기록합니다.
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION touch_timetable_updated()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END
$fn$;

DROP TRIGGER IF EXISTS trg_timetables_touch ON timetables;
CREATE TRIGGER trg_timetables_touch
  BEFORE UPDATE ON timetables
  FOR EACH ROW EXECUTE FUNCTION touch_timetable_updated();


-- 확인용 : 지금 시각으로 한 번 맞춰 둡니다
UPDATE timetables SET updated_at = now();

SELECT max(updated_at) AS last_updated, count(*) AS rows
FROM timetables;
