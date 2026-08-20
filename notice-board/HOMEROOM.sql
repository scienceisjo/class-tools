-- ═══════════════════════════════════════════════════════════════════
-- 담임 선생님 기능 - 이 SQL 하나만 실행하면 됩니다
-- 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════

-- 1) 가입할 때 담임 학급을 저장할 칸
ALTER TABLE notice_admins ADD COLUMN IF NOT EXISTS hr_grade int;
ALTER TABLE notice_admins ADD COLUMN IF NOT EXISTS hr_class int;


-- 2) 주요일정에도 학년/반을 지정할 수 있게 (우리 반만의 일정)
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS grade    int;
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS class_no int;
ALTER TABLE ddays     ADD COLUMN IF NOT EXISTS grade    int;
ALTER TABLE ddays     ADD COLUMN IF NOT EXISTS class_no int;


-- 2-2) 공지에 부서 표시 (선택 사항)
ALTER TABLE notices      ADD COLUMN IF NOT EXISTS dept text;
-- 가입할 때 소속 부서를 저장해 두면 공지 작성 시 자동으로 채워집니다
ALTER TABLE notice_admins ADD COLUMN IF NOT EXISTS dept text;


-- 3) "이 사람이 그 반 담임인가" 를 판단하는 함수
--    정책 안에서 notice_admins 를 직접 조회하면 무한 반복이 나므로 함수로 분리합니다.
CREATE OR REPLACE FUNCTION is_homeroom_of(p_grade int, p_class int)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $fn$
  SELECT EXISTS (
    SELECT 1 FROM notice_admins
    WHERE auth_id = auth.uid()
      AND approved
      AND hr_grade = p_grade
      AND hr_class = p_class
  );
$fn$;
REVOKE ALL ON FUNCTION is_homeroom_of(int,int) FROM public;
GRANT EXECUTE ON FUNCTION is_homeroom_of(int,int) TO anon, authenticated;


-- 4) 담임은 자기 반 자료를 남이 올린 것이라도 정리할 수 있게
--    (공지 / 주요일정 / 디데이 / 평가일정 / 수업장소)
DO $blk$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['notices','schedules','ddays','assessments','class_locations']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t||'_auth_delete', t);
    EXECUTE format($f$
      CREATE POLICY %I ON %I FOR DELETE
      USING (
        auth.role() = 'authenticated'
        AND (
          author_id IS NULL
          OR author_id = auth.uid()
          OR is_notice_owner()
          OR (grade IS NOT NULL AND class_no IS NOT NULL
              AND is_homeroom_of(grade, class_no))
        )
      )
    $f$, t||'_auth_delete', t);
  END LOOP;
END
$blk$;


-- 5) 확인
SELECT
  (SELECT COUNT(*) FROM notice_admins WHERE hr_grade IS NOT NULL) AS homeroom_teachers,
  (SELECT COUNT(*) FROM schedules) AS schedules;
