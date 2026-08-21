-- ═══════════════════════════════════════════════════════════════════
-- 담임에게 우리 반 자료 수정 권한 주기
-- -------------------------------------------------------------------
-- 지금까지 : 수정은 본인이 올린 것만 가능
-- 앞으로   : 본인 것 + 관리담당자 + 그 반 담임 도 수정 가능
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


-- 판별 함수가 없을 수도 있으니 확실히 만들어 둡니다
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


-- 수정 규칙 다시 만들기
-- 학년/반 칸이 있는 표만 담임 조건을 넣습니다.
DO $blk$
DECLARE
  t text;
  has_cls boolean;
BEGIN
  FOREACH t IN ARRAY ARRAY['notices','schedules','ddays','assessments','class_locations']
  LOOP
    SELECT count(*) = 2 INTO has_cls
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = t
      AND column_name IN ('grade','class_no');

    -- 기존 수정 규칙 정리 (이름이 여러 가지로 남아 있을 수 있음)
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t||'_auth_update', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t||'_upd', t);

    IF has_cls THEN
      EXECUTE format($f$
        CREATE POLICY %I ON %I FOR UPDATE
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
      $f$, t||'_auth_update', t);
    ELSE
      EXECUTE format($f$
        CREATE POLICY %I ON %I FOR UPDATE
        USING (
          auth.role() = 'authenticated'
          AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner())
        )
      $f$, t||'_auth_update', t);
    END IF;
  END LOOP;
END
$blk$;


-- ═══ 확인 ═════════════════════════════════════════════════════════
-- 5개 표 모두 UPDATE 규칙이 보이면 정상입니다.
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public' AND cmd = 'UPDATE'
  AND tablename IN ('notices','schedules','ddays','assessments','class_locations')
ORDER BY tablename;
