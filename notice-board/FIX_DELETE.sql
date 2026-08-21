-- ═══════════════════════════════════════════════════════════════════
-- 공지 삭제가 안 될 때 - 진단 & 복구
-- -------------------------------------------------------------------
-- 증상 : 삭제를 눌러도 목록에서 사라지지 않음
-- 원인 : 앞선 SQL 이 도중에 실패해 삭제 권한 규칙이 빠졌을 수 있음
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


-- ═══ 1단계 : 지금 상태 확인 ═══════════════════════════════════════
-- (가) 각 표에 삭제 규칙이 있는지
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('notices','schedules','ddays','assessments','class_locations','lost_items')
  AND cmd = 'DELETE'
ORDER BY tablename;
--   -> notices 가 목록에 없으면 삭제 규칙이 아예 없는 상태입니다 (그래서 안 지워짐)

-- (나) 내 공지에 작성자가 기록되어 있는지
SELECT id, title, (author_id IS NOT NULL) AS has_author, author_name, created_at
FROM notices ORDER BY id DESC LIMIT 10;


-- ═══ 2단계 : 복구 ═════════════════════════════════════════════════
-- 필요한 판별 함수부터 확실히 만들어 둡니다.
CREATE OR REPLACE FUNCTION is_notice_owner()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $fn1$
  SELECT EXISTS (
    SELECT 1 FROM notice_admins WHERE auth_id = auth.uid() AND is_owner
  );
$fn1$;
REVOKE ALL ON FUNCTION is_notice_owner() FROM public;
GRANT EXECUTE ON FUNCTION is_notice_owner() TO anon, authenticated;

CREATE OR REPLACE FUNCTION is_homeroom_of(p_grade int, p_class int)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $fn2$
  SELECT EXISTS (
    SELECT 1 FROM notice_admins
    WHERE auth_id = auth.uid()
      AND COALESCE(approved, true)
      AND hr_grade = p_grade AND hr_class = p_class
  );
$fn2$;
REVOKE ALL ON FUNCTION is_homeroom_of(int,int) FROM public;
GRANT EXECUTE ON FUNCTION is_homeroom_of(int,int) TO anon, authenticated;


-- 삭제 규칙 다시 만들기
-- 학년/반 칸이 있는 표만 담임 조건을 넣고, 없는 표는 기본 조건만 넣습니다.
DO $blk$
DECLARE
  t text;
  has_cls boolean;
BEGIN
  FOREACH t IN ARRAY ARRAY['notices','schedules','ddays','assessments','class_locations','lost_items']
  LOOP
    SELECT count(*) = 2 INTO has_cls
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = t
      AND column_name IN ('grade','class_no');

    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t||'_auth_delete', t);

    IF has_cls THEN
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
    ELSE
      EXECUTE format($f$
        CREATE POLICY %I ON %I FOR DELETE
        USING (
          auth.role() = 'authenticated'
          AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner())
        )
      $f$, t||'_auth_delete', t);
    END IF;
  END LOOP;
END
$blk$;


-- ═══ 3단계 : 확인 ═════════════════════════════════════════════════
-- 6개 표 모두 DELETE 규칙이 보이면 정상입니다.
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public' AND cmd = 'DELETE'
  AND tablename IN ('notices','schedules','ddays','assessments','class_locations','lost_items')
ORDER BY tablename;
