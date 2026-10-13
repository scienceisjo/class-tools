-- ═══════════════════════════════════════════════════════════════════
-- 📺 전자칠판 알리미 — 새 학교 설치 (한 번에 전부)
-- -------------------------------------------------------------------
-- 새로 만든 Supabase 프로젝트의 SQL Editor 에 통째로 붙여넣고 Run.
-- 여러 번 실행해도 안전합니다.
--
-- 이 파일 하나로:
--   표 20개 · 권한 규칙 · 가입 코드 확인 · 첫 가입자 = 관리 담당자
--   · 컴시간 시간표 매일 08:30 자동 받기 예약까지 끝납니다.
--
-- 🔒 해누리 초기판보다 단단하게:
--   글쓰기·고치기는 "승인된 선생님"만 됩니다(로그인만으로는 안 됨).
--   가입 코드도 서버가 직접 확인하고, 스스로 승인·관리자 권한을
--   올리는 것을 막아 둡니다.
--
-- ⚠️ 붙여넣기 전 브라우저 자동번역을 꺼 주세요 (SQL 글자가 바뀌어 오류가 납니다)
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
-- 0. 확장 기능 (시간표 예약 실행용)
-- ───────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;


-- ───────────────────────────────────────────────────────────────────
-- 1. 표
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS display_config (
  key        text PRIMARY KEY,
  value      text,
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notice_admins (                 -- 공지 관리 선생님
  auth_id    uuid PRIMARY KEY,
  name       text NOT NULL,
  subject    text,
  dept       text,
  hr_grade   int,                                          -- 담임 학년·반
  hr_class   int,
  approved   boolean DEFAULT false,
  is_owner   boolean DEFAULT false,                        -- 관리 담당자
  is_shared  boolean DEFAULT false,                        -- 공동계정
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notices (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category    text NOT NULL DEFAULT '일반' CHECK (category IN ('긴급','교과','학년','일반')),
  title       text NOT NULL,
  body        text,
  grade       int,
  class_no    int,
  subject     text,
  dept        text,
  link        text,
  pinned      boolean DEFAULT false,
  start_at    date DEFAULT CURRENT_DATE,
  end_at      date,
  author_id   uuid,
  author_name text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS schedules (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title       text NOT NULL,
  start_date  date NOT NULL,
  end_date    date,
  location    text,
  icon        text DEFAULT '📌',
  grade       int,
  class_no    int,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS timetable_changes (             -- 예전 수동 변경(지금은 컴시간 자동)
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  change_date date NOT NULL,
  grade       int,
  class_no    int,
  period      int,
  before_subj text,
  after_subj  text,
  note        text,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ddays (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title       text NOT NULL,
  target_date date NOT NULL,
  type        text NOT NULL DEFAULT '기타' CHECK (type IN ('시험','평가','방학','기타')),
  icon        text DEFAULT '🎯',
  grade       int,
  class_no    int,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assessments (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  subject     text NOT NULL,
  title       text NOT NULL,
  assess_type text NOT NULL DEFAULT '수행평가' CHECK (assess_type IN ('지필평가','수행평가','기타')),
  assess_date date NOT NULL,
  grade       int,
  class_no    int,
  scope       text,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS calls (                          -- 학생 호출
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_name text NOT NULL,
  grade        int,
  class_no     int,
  student_id   uuid,
  teacher_name text NOT NULL,
  location     text DEFAULT '교무실',
  reason       text,
  status       text NOT NULL DEFAULT 'active' CHECK (status IN ('active','done')),
  author_id    uuid,
  created_at   timestamptz DEFAULT now(),
  done_at      timestamptz
);

CREATE TABLE IF NOT EXISTS cleaning_duties (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade      int NOT NULL,
  class_no   int NOT NULL,
  area       text NOT NULL,
  members    text NOT NULL,
  note       text,
  sort_order int DEFAULT 0,
  author_id  uuid,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lost_items (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  item_name   text NOT NULL,
  found_place text,
  keep_place  text DEFAULT '교무실',
  photo_url   text,
  status      text NOT NULL DEFAULT 'active' CHECK (status IN ('active','returned')),
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS class_roles (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade      int NOT NULL,
  class_no   int NOT NULL,
  role       text NOT NULL,
  member     text NOT NULL,
  icon       text DEFAULT '🙋',
  sort_order int DEFAULT 0,
  author_id  uuid,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS class_locations (               -- 수업 장소
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  loc_date   date NOT NULL DEFAULT CURRENT_DATE,
  grade      int,
  class_no   int,
  period     int,
  subject    text NOT NULL,
  location   text NOT NULL,
  note       text,
  author_id  uuid,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS messages (                       -- 학생 → 선생님 쪽지
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  to_teacher   text,
  to_auth_id   uuid,
  student_name text,
  grade        int,
  class_no     int,
  category     text NOT NULL DEFAULT '하고 싶은 말'
               CHECK (category IN ('하고 싶은 말','질문','건의','고민·상담','도움 요청')),
  body         text NOT NULL CHECK (length(body) BETWEEN 1 AND 1000),
  is_anonymous boolean DEFAULT false,
  status       text NOT NULL DEFAULT 'unread' CHECK (status IN ('unread','read','done')),
  created_at   timestamptz DEFAULT now(),
  read_at      timestamptz
);

CREATE TABLE IF NOT EXISTS message_reads (
  message_id bigint NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  reader_id  uuid   NOT NULL,
  read_at    timestamptz DEFAULT now(),
  PRIMARY KEY (message_id, reader_id)
);

CREATE TABLE IF NOT EXISTS audit_log (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name text,
  action     text,
  row_id     bigint,
  summary    text,
  actor_id   uuid,
  actor_name text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS timetables (                     -- 컴시간에서 받은 시간표
  class_key  text NOT NULL,
  weekday    int  NOT NULL,
  periods    jsonb NOT NULL,
  changed    int[] NOT NULL DEFAULT '{}',
  source     text,
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (class_key, weekday)
);

CREATE TABLE IF NOT EXISTS timetable_sync_log (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ok         boolean,
  rows       int,
  message    text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS videos (
  id          bigserial PRIMARY KEY,
  title       text NOT NULL,
  url         text NOT NULL,
  note        text,
  grade       int,
  class_no    int,
  start_at    date NOT NULL DEFAULT current_date,
  end_at      date,
  sort_order  int  NOT NULL DEFAULT 0,
  author_id   uuid,
  author_name text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS birthdays (
  id         bigserial PRIMARY KEY,
  grade      int  NOT NULL,
  class_no   int  NOT NULL,
  name       text NOT NULL,
  month      int  NOT NULL CHECK (month BETWEEN 1 AND 12),
  day        int  NOT NULL CHECK (day   BETWEEN 1 AND 31),
  author_id  uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grade, class_no, name, month, day)
);

CREATE TABLE IF NOT EXISTS shared_posters (                 -- 공동계정 「지금 쓰시는 선생님」 명단
  name    text PRIMARY KEY,
  subject text,
  dept    text,
  uses    int NOT NULL DEFAULT 0,
  used_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notices_window   ON notices(start_at, end_at);
CREATE INDEX IF NOT EXISTS idx_notices_created  ON notices(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_schedules_date   ON schedules(start_date);
CREATE INDEX IF NOT EXISTS idx_ttc_date         ON timetable_changes(change_date);
CREATE INDEX IF NOT EXISTS idx_ddays_date       ON ddays(target_date);
CREATE INDEX IF NOT EXISTS idx_assess_date      ON assessments(assess_date);
CREATE INDEX IF NOT EXISTS idx_calls_status     ON calls(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_clean_class      ON cleaning_duties(grade, class_no, sort_order);
CREATE INDEX IF NOT EXISTS idx_lost_status      ON lost_items(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_loc_date         ON class_locations(loc_date);
CREATE INDEX IF NOT EXISTS idx_roles_class      ON class_roles(grade, class_no, sort_order);
CREATE INDEX IF NOT EXISTS idx_msg_status       ON messages(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_msg_to           ON messages(to_auth_id);
CREATE INDEX IF NOT EXISTS idx_audit_created    ON audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tt_updated       ON timetables(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_videos_class     ON videos(grade, class_no);
CREATE INDEX IF NOT EXISTS idx_birthdays_class  ON birthdays(grade, class_no, month, day);


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
-- 3. 자동 처리
-- ───────────────────────────────────────────────────────────────────
-- 긴급 공지는 종료일을 안 넣으면 그날만
CREATE OR REPLACE FUNCTION notices_urgent_default_end()
RETURNS trigger LANGUAGE plpgsql AS $fn$
BEGIN
  IF NEW.category = '긴급' AND NEW.end_at IS NULL THEN NEW.end_at := CURRENT_DATE; END IF;
  RETURN NEW;
END
$fn$;
DROP TRIGGER IF EXISTS trg_urgent_end ON notices;
CREATE TRIGGER trg_urgent_end BEFORE INSERT OR UPDATE ON notices
  FOR EACH ROW EXECUTE FUNCTION notices_urgent_default_end();

-- 시간표를 덮어쓸 때도 갱신 시각 바꾸기
CREATE OR REPLACE FUNCTION touch_timetable_updated()
RETURNS trigger LANGUAGE plpgsql AS $fn$
BEGIN NEW.updated_at := now(); RETURN NEW; END
$fn$;
DROP TRIGGER IF EXISTS trg_timetables_touch ON timetables;
CREATE TRIGGER trg_timetables_touch BEFORE UPDATE ON timetables
  FOR EACH ROW EXECUTE FUNCTION touch_timetable_updated();

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
-- 4. 권한 규칙 (RLS)
--    읽기: 교실 화면(로그인 없음)이 읽어야 하는 것은 누구나
--    쓰기: 승인된 선생님만 / 고치기·지우기: 본인 · 관리 담당자 · 그 반 담임
-- ───────────────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

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
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO anon, authenticated', t);   -- 이 앱 표만
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


-- ───────────────────────────────────────────────────────────────────
-- 5. 사진 보관함 (분실물 사진)
-- ───────────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;
DROP POLICY IF EXISTS "attachments_read"   ON storage.objects;
DROP POLICY IF EXISTS "attachments_upload" ON storage.objects;
CREATE POLICY "attachments_read"   ON storage.objects FOR SELECT USING (bucket_id = 'attachments');
CREATE POLICY "attachments_upload" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'attachments' AND public.is_notice_staff());


-- ───────────────────────────────────────────────────────────────────
-- 6. 실시간 반영 (공지를 올리면 교실 화면에 바로)
-- ───────────────────────────────────────────────────────────────────
DO $rt$
DECLARE t text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
  FOREACH t IN ARRAY ARRAY['notices','schedules','timetable_changes','display_config','ddays','assessments',
                           'calls','cleaning_duties','lost_items','class_locations','class_roles','messages','videos']
  LOOP
    BEGIN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I', t);
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END LOOP;
END
$rt$;


-- ───────────────────────────────────────────────────────────────────
-- 7. 학교 정보 (처음 한 번만 들어감 — 나중에는 관리 화면 ⚙️ 설정에서 바꿈)
-- ───────────────────────────────────────────────────────────────────
INSERT INTO display_config (key, value) VALUES
  ('school_name',   '__SCHOOL_NAME__'),
  ('slide_seconds', '12'),
  ('neis_atpt',     '__NEIS_ATPT__'),
  ('neis_school',   '__NEIS_SCHOOL__'),
  ('weather_lat',   '__LAT__'),
  ('weather_lon',   '__LON__'),
  ('comcigan_code', '__COMCIGAN__'),
  ('admin_code',    '__SIGNUP_CODE__')
ON CONFLICT (key) DO NOTHING;


-- ───────────────────────────────────────────────────────────────────
-- 8. 컴시간 시간표 매일 아침 8시 30분(한국시간) 자동 받기
--    (sync-timetable 함수를 먼저 올려 두어야 실제로 받아집니다)
-- ───────────────────────────────────────────────────────────────────
DO $cron$
BEGIN
  PERFORM cron.unschedule('sync-timetable-daily');
EXCEPTION WHEN OTHERS THEN NULL;
END
$cron$;
SELECT cron.schedule(
  'sync-timetable-daily',
  '30 23 * * 0-4',                                         -- 23:30 UTC = 다음날 08:30 / 월~금
  $job$
  SELECT net.http_post(
    url     := '__PROJECT_URL__/functions/v1/sync-timetable',
    headers := '{"Content-Type":"application/json","apikey":"__ANON_KEY__","Authorization":"Bearer __ANON_KEY__"}'::jsonb,
    body    := '{}'::jsonb
  );
  $job$
);


-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT
  (SELECT count(*) FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name IN (
      'display_config','notice_admins','notices','schedules','timetable_changes','ddays','assessments',
      'calls','cleaning_duties','lost_items','class_roles','class_locations','messages','message_reads',
      'audit_log','timetables','timetable_sync_log','videos','birthdays','shared_posters')) AS 표_20개면_정상,
  (SELECT value FROM display_config WHERE key = 'school_name')                          AS 학교,
  (SELECT count(*) FROM cron.job WHERE jobname = 'sync-timetable-daily')               AS 예약_1이면_정상;
