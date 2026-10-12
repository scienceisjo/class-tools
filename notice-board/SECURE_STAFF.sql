-- ═══════════════════════════════════════════════════════════════════
-- 🔒 해누리 공지 — 「등록된 선생님만 쓰기」 보안 보강 (SECURE_STAFF.sql)
-- -------------------------------------------------------------------
-- 지금까지는 「로그인만 하면」 공지·호출·영상을 쓸 수 있었습니다.
-- 교실 화면 소스에 들어 있는 공개 키로 누구나 가입만 하면 글을 올릴 수 있고,
-- 스스로 승인·관리 담당자 표시를 켤 수도 있었습니다.
--
-- 이 SQL 을 실행하면
--   · 글쓰기·고치기·지우기 = 관리 담당자가 「승인」한 선생님만
--   · 선생님 등록은 서버가 가입 코드를 확인하는 함수로만 (스스로 승인 불가)
--   · 학교 설정(학교명·가입 코드)은 관리 담당자만,
--     반마다 쓰는 조 편성·역할 목록은 승인된 선생님 누구나
--   · 쪽지는 지금처럼 개인 계정 선생님만 읽음(공동계정 X)
-- 공지 표 20개의 권한 규칙만 새로 만들고, 데이터는 그대로 둡니다.
-- 같은 프로젝트의 다른 앱 표·사진 보관함은 건드리지 않습니다.
-- 여러 번 실행해도 같은 결과입니다.
-- ═══════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────
-- 2. 판별 함수 (정책 안에서 표를 직접 보면 무한 반복이 나므로 함수로)
-- ───────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_notice_staff()               -- 승인된 선생님인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = auth.uid() AND approved);
$fn$;

CREATE OR REPLACE FUNCTION is_notice_owner()               -- 관리 담당자인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = auth.uid() AND approved AND is_owner);
$fn$;

CREATE OR REPLACE FUNCTION is_shared_account()             -- 공동계정인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT COALESCE((SELECT is_shared FROM notice_admins WHERE auth_id = auth.uid()), false);
$fn$;

CREATE OR REPLACE FUNCTION is_homeroom_of(p_grade int, p_class int)   -- 그 반 담임인가
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM notice_admins
                 WHERE auth_id = auth.uid() AND approved
                   AND hr_grade = p_grade AND hr_class = p_class);
$fn$;

-- 가입 코드가 맞는지만 대답 (코드 값은 밖으로 안 나감)
CREATE OR REPLACE FUNCTION check_admin_code(code text)
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT EXISTS (SELECT 1 FROM display_config WHERE key = 'admin_code' AND value = code);
$fn$;

-- 선생님 등록 — 서버가 가입 코드를 확인하고 등록. 이 학교 첫 가입자는 관리 담당자.
CREATE OR REPLACE FUNCTION register_notice_admin(
  p_code text, p_name text, p_subject text, p_dept text, p_hr_grade int, p_hr_class int)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $fn$
DECLARE
  v_uid   uuid := auth.uid();
  v_first boolean;
BEGIN
  IF v_uid IS NULL THEN RETURN 'no_session'; END IF;
  IF NOT EXISTS (SELECT 1 FROM display_config WHERE key = 'admin_code' AND value = p_code) THEN
    RETURN 'bad_code';
  END IF;
  IF EXISTS (SELECT 1 FROM notice_admins WHERE auth_id = v_uid) THEN
    RETURN CASE WHEN (SELECT approved FROM notice_admins WHERE auth_id = v_uid) THEN 'approved' ELSE 'pending' END;
  END IF;
  PERFORM pg_advisory_xact_lock(424242);                   -- 첫 가입자 판정이 겹치지 않게
  v_first := NOT EXISTS (SELECT 1 FROM notice_admins WHERE is_owner);
  INSERT INTO notice_admins (auth_id, name, subject, dept, hr_grade, hr_class, approved, is_owner)
  VALUES (v_uid, btrim(p_name), NULLIF(btrim(COALESCE(p_subject, '')), ''), NULLIF(btrim(COALESCE(p_dept, '')), ''),
          CASE WHEN p_hr_grade IS NOT NULL AND p_hr_class IS NOT NULL THEN p_hr_grade END,
          CASE WHEN p_hr_grade IS NOT NULL AND p_hr_class IS NOT NULL THEN p_hr_class END,
          v_first, v_first);
  RETURN CASE WHEN v_first THEN 'owner' ELSE 'pending' END;
END
$fn$;

-- 청소당번 한 반 통째로 바꾸기
CREATE OR REPLACE FUNCTION replace_cleaning(p_grade int, p_class int, p_rows jsonb, p_author uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $fn$
BEGIN
  IF NOT is_notice_staff() THEN RAISE EXCEPTION '승인된 선생님만 바꿀 수 있습니다'; END IF;
  DELETE FROM cleaning_duties WHERE grade = p_grade AND class_no = p_class;
  INSERT INTO cleaning_duties (grade, class_no, area, members, note, sort_order, author_id)
  SELECT p_grade, p_class, COALESCE(r->>'area', ' '), COALESCE(r->>'members', ' '),
         NULLIF(r->>'note', ''), COALESCE((r->>'sort_order')::int, 0), auth.uid()
  FROM jsonb_array_elements(p_rows) r;
END
$fn$;

-- 공동계정 이름 명단에 기록
CREATE OR REPLACE FUNCTION touch_poster(p_name text, p_subject text, p_dept text)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $fn$
  INSERT INTO shared_posters (name, subject, dept, uses, used_at)
  SELECT btrim(p_name), NULLIF(btrim(COALESCE(p_subject, '')), ''), NULLIF(btrim(COALESCE(p_dept, '')), ''), 1, now()
  WHERE is_notice_staff() AND btrim(COALESCE(p_name, '')) <> ''
  ON CONFLICT (name) DO UPDATE
    SET subject = COALESCE(EXCLUDED.subject, shared_posters.subject),
        dept    = COALESCE(EXCLUDED.dept,    shared_posters.dept),
        uses    = shared_posters.uses + 1,
        used_at = now();
$fn$;

REVOKE ALL ON FUNCTION is_notice_staff()                         FROM public;
REVOKE ALL ON FUNCTION is_notice_owner()                         FROM public;
REVOKE ALL ON FUNCTION is_shared_account()                       FROM public;
REVOKE ALL ON FUNCTION is_homeroom_of(int, int)                  FROM public;
REVOKE ALL ON FUNCTION check_admin_code(text)                    FROM public;
REVOKE ALL ON FUNCTION register_notice_admin(text, text, text, text, int, int) FROM public;
REVOKE ALL ON FUNCTION replace_cleaning(int, int, jsonb, uuid)   FROM public;
REVOKE ALL ON FUNCTION touch_poster(text, text, text)            FROM public;
GRANT EXECUTE ON FUNCTION is_notice_staff()                        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_notice_owner()                        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_shared_account()                      TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_homeroom_of(int, int)                 TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_admin_code(text)                   TO anon, authenticated;
GRANT EXECUTE ON FUNCTION register_notice_admin(text, text, text, text, int, int) TO authenticated;
GRANT EXECUTE ON FUNCTION replace_cleaning(int, int, jsonb, uuid)  TO authenticated;
GRANT EXECUTE ON FUNCTION touch_poster(text, text, text)           TO authenticated;


-- ───────────────────────────────────────────────────────────────────
-- 3. 스스로 승인 막기
-- ───────────────────────────────────────────────────────────────────
-- 스스로 승인·관리자·공동계정 표시를 바꾸지 못하게 (관리 담당자와 SQL 편집기는 가능)
CREATE OR REPLACE FUNCTION notice_admins_guard()
RETURNS trigger LANGUAGE plpgsql AS $fn$
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_notice_owner() THEN
    NEW.auth_id   := OLD.auth_id;
    NEW.approved  := OLD.approved;
    NEW.is_owner  := OLD.is_owner;
    NEW.is_shared := OLD.is_shared;
  END IF;
  RETURN NEW;
END
$fn$;
DROP TRIGGER IF EXISTS trg_notice_admins_guard ON notice_admins;
CREATE TRIGGER trg_notice_admins_guard BEFORE UPDATE ON notice_admins
  FOR EACH ROW EXECUTE FUNCTION notice_admins_guard();


-- ───────────────────────────────────────────────────────────────────
-- 4. 권한 규칙 (RLS) — 공지 표 20개만
--    읽기: 교실 화면(로그인 없음)이 읽어야 하는 것은 누구나
--    쓰기: 승인된 선생님만 / 고치기·지우기: 본인 · 관리 담당자 · 그 반 담임
-- ───────────────────────────────────────────────────────────────────
DO $rls$
DECLARE
  t text;
  pol record;
BEGIN
  -- 이 설치가 다루는 표는 기존 규칙을 모두 지우고 새로 만듭니다 (다시 실행해도 같은 결과)
  FOR pol IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public' AND tablename IN (
      'display_config','notice_admins','notices','schedules','timetable_changes','ddays','assessments',
      'calls','cleaning_duties','lost_items','class_roles','class_locations','messages','message_reads',
      'audit_log','timetables','timetable_sync_log','videos','birthdays','shared_posters')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
  END LOOP;

  FOREACH t IN ARRAY ARRAY[
      'display_config','notice_admins','notices','schedules','timetable_changes','ddays','assessments',
      'calls','cleaning_duties','lost_items','class_roles','class_locations','messages','message_reads',
      'audit_log','timetables','timetable_sync_log','videos','birthdays','shared_posters']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;

  -- 교실 화면이 읽는 표: 누구나 읽기
  FOREACH t IN ARRAY ARRAY['notices','schedules','timetable_changes','ddays','assessments','calls',
                           'cleaning_duties','lost_items','class_roles','class_locations',
                           'timetables','timetable_sync_log','videos']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (true)', t || '_read', t);
  END LOOP;

  -- 학년·반이 있는 표: 승인된 선생님이 쓰고, 본인·관리 담당자·그 반 담임이 고치고 지움
  FOREACH t IN ARRAY ARRAY['notices','schedules','ddays','assessments','class_locations','videos']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (is_notice_staff())', t || '_ins', t);
    EXECUTE format($p$CREATE POLICY %I ON %I FOR UPDATE USING (
        is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()
          OR (grade IS NOT NULL AND class_no IS NOT NULL AND is_homeroom_of(grade, class_no))))$p$, t || '_upd', t);
    EXECUTE format($p$CREATE POLICY %I ON %I FOR DELETE USING (
        is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()
          OR (grade IS NOT NULL AND class_no IS NOT NULL AND is_homeroom_of(grade, class_no))))$p$, t || '_del', t);
  END LOOP;

  -- 학년·반이 없는 표: 본인·관리 담당자
  FOREACH t IN ARRAY ARRAY['timetable_changes','lost_items']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (is_notice_staff())', t || '_ins', t);
    EXECUTE format($p$CREATE POLICY %I ON %I FOR DELETE USING (
        is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()))$p$, t || '_del', t);
  END LOOP;
  CREATE POLICY timetable_changes_upd ON timetable_changes FOR UPDATE
    USING (is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()));
  CREATE POLICY lost_items_upd ON lost_items FOR UPDATE USING (is_notice_staff());      -- 「찾아감」은 누구나

  -- 반 운영(호출·청소·1인1역)·명단·기록: 승인된 선생님 누구나
  FOREACH t IN ARRAY ARRAY['calls','cleaning_duties','class_roles','shared_posters']
  LOOP
    EXECUTE format('CREATE POLICY %I ON %I FOR ALL USING (is_notice_staff()) WITH CHECK (is_notice_staff())', t || '_staff', t);
  END LOOP;
  CREATE POLICY shared_posters_read ON shared_posters FOR SELECT USING (is_notice_staff());
  CREATE POLICY audit_log_read ON audit_log FOR SELECT USING (is_notice_staff());
  CREATE POLICY audit_log_ins  ON audit_log FOR INSERT WITH CHECK (is_notice_staff());

  -- 🎂 생일: 선생님은 전부, 교실 화면은 이번 달만 (태어난 해는 저장 안 함)
  CREATE POLICY birthdays_read ON birthdays FOR SELECT USING (
    is_notice_staff() OR month = EXTRACT(MONTH FROM (now() AT TIME ZONE 'Asia/Seoul'))::int);
  CREATE POLICY birthdays_ins  ON birthdays FOR INSERT WITH CHECK (is_notice_staff());
  CREATE POLICY birthdays_del  ON birthdays FOR DELETE USING (
    is_notice_staff() AND (author_id IS NULL OR author_id = auth.uid() OR is_notice_owner()
      OR is_homeroom_of(grade, class_no)));

  -- 📮 쪽지: 학생은 보내기만, 읽기는 승인된 개인 계정 선생님만 (공동계정·교실 화면 X)
  CREATE POLICY messages_send ON messages FOR INSERT WITH CHECK (true);
  CREATE POLICY messages_read ON messages FOR SELECT USING (is_notice_staff() AND NOT is_shared_account());
  CREATE POLICY messages_upd  ON messages FOR UPDATE USING (is_notice_staff() AND NOT is_shared_account());
  CREATE POLICY messages_del  ON messages FOR DELETE USING (is_notice_staff() AND NOT is_shared_account());
  CREATE POLICY message_reads_self ON message_reads FOR ALL
    USING (auth.uid() = reader_id) WITH CHECK (auth.uid() = reader_id);

  -- 🔑 선생님 명단: 본인 것만 보이고, 관리 담당자는 전부 (등록은 register_notice_admin 함수로만)
  CREATE POLICY notice_admins_self_read  ON notice_admins FOR SELECT USING (auth.uid() = auth_id);
  CREATE POLICY notice_admins_owner_read ON notice_admins FOR SELECT USING (is_notice_owner());
  CREATE POLICY notice_admins_self_upd   ON notice_admins FOR UPDATE USING (auth.uid() = auth_id);
  CREATE POLICY notice_admins_owner_upd  ON notice_admins FOR UPDATE USING (is_notice_owner());

  -- ⚙️ 설정: 가입 코드는 선생님만 보고, 바꾸기는 관리 담당자만
  --          (반마다 쓰는 조 편성·역할 목록은 승인된 선생님 누구나)
  CREATE POLICY display_config_read  ON display_config FOR SELECT USING (key <> 'admin_code' OR is_notice_staff());
  CREATE POLICY display_config_write ON display_config FOR ALL
    USING (is_notice_owner()) WITH CHECK (is_notice_owner());
  CREATE POLICY display_config_class ON display_config FOR ALL
    USING      (is_notice_staff() AND (key LIKE 'clean\_squad\_%' OR key LIKE 'roles\_%'))
    WITH CHECK (is_notice_staff() AND (key LIKE 'clean\_squad\_%' OR key LIKE 'roles\_%'));
END
$rls$;

-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT
  (SELECT COUNT(*) FROM notice_admins WHERE approved)              AS 승인된선생님,
  (SELECT COUNT(*) FROM notice_admins WHERE approved AND is_owner) AS 관리담당자,
  (SELECT COUNT(*) FROM notice_admins WHERE NOT approved)          AS 승인대기,
  (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public'
     AND policyname IN ('notices_ins', 'display_config_class', 'notice_admins_self_upd')) AS 새규칙_3이면_성공;
