-- ═══════════════════════════════════════════════════════════════════
-- 🧑‍🎓 해누리 공지 — 학생 도우미 (STUDENT_HELPER.sql)
-- -------------------------------------------------------------------
-- 1인1역 학생이 학생용 페이지(student.html)에서 「우리 반」의
-- 🧠 암기 카드 · 🧹 청소당번 · 🙋 1인1역 만 고치게 합니다.
--   · 반마다 코드 하나 (담임·교과 선생님이 관리 화면 🙋 1인1역 탭에서 만들고 끔)
--   · 학생은 표에 직접 못 쓰고, 코드·반·글자 수를 확인하는 함수로만 씀
--   · 공지·호출·쪽지·생일·설정·다른 반은 못 건드림
--   · 코드는 암호로 바꿔 저장, 10번 틀리면 10분 잠김, 고친 학생 이름을 기록에 남김
-- 기존 데이터·권한 규칙은 그대로 둡니다. 여러 번 실행해도 같은 결과입니다.
-- ⚠️ 붙여넣기 전 브라우저 자동번역을 꺼 주세요
-- ═══════════════════════════════════════════════════════════════════

-- ▼▼ 학생 도우미 시작
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS class_codes (                    -- 반마다 학생 도우미 코드
  grade        int  NOT NULL,
  class_no     int  NOT NULL,
  code_hash    text NOT NULL,
  fails        int  NOT NULL DEFAULT 0,
  locked_until timestamptz,
  updated_by   text,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (grade, class_no)
);
ALTER TABLE class_codes ENABLE ROW LEVEL SECURITY;           -- 규칙 없음 = 화면에서 직접 못 봄(함수로만)
REVOKE ALL ON class_codes FROM anon, authenticated;

ALTER TABLE memo_decks ADD COLUMN IF NOT EXISTS by_student boolean NOT NULL DEFAULT false;

-- 코드 확인 (안에서만 씀) — 'ok' | 'bad' | 'locked' | 'none'
CREATE OR REPLACE FUNCTION class_code_check(p_grade int, p_class int, p_code text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $fn$
DECLARE r class_codes%ROWTYPE;
BEGIN
  SELECT * INTO r FROM class_codes WHERE grade = p_grade AND class_no = p_class FOR UPDATE;
  IF NOT FOUND THEN RETURN 'none'; END IF;
  IF r.locked_until IS NOT NULL AND r.locked_until > now() THEN RETURN 'locked'; END IF;
  IF r.code_hash = crypt(COALESCE(p_code, ''), r.code_hash) THEN
    IF r.fails <> 0 THEN UPDATE class_codes SET fails = 0 WHERE grade = p_grade AND class_no = p_class; END IF;
    RETURN 'ok';
  END IF;
  UPDATE class_codes
     SET fails        = CASE WHEN r.fails + 1 >= 10 THEN 0 ELSE r.fails + 1 END,
         locked_until = CASE WHEN r.fails + 1 >= 10 THEN now() + interval '10 minutes' ELSE r.locked_until END
   WHERE grade = p_grade AND class_no = p_class;
  RETURN 'bad';
END
$fn$;

-- 선생님: 코드 만들기·바꾸기 (빈 코드 = 끄기)
CREATE OR REPLACE FUNCTION set_class_code(p_grade int, p_class int, p_code text, p_by text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $fn$
BEGIN
  IF NOT is_notice_staff() THEN RETURN 'not_staff'; END IF;
  IF p_grade IS NULL OR p_class IS NULL THEN RETURN 'no_class'; END IF;
  IF btrim(COALESCE(p_code, '')) = '' THEN
    DELETE FROM class_codes WHERE grade = p_grade AND class_no = p_class;
    RETURN 'cleared';
  END IF;
  IF length(btrim(p_code)) NOT BETWEEN 4 AND 12 THEN RETURN 'bad_format'; END IF;
  INSERT INTO class_codes (grade, class_no, code_hash, fails, locked_until, updated_by, updated_at)
  VALUES (p_grade, p_class, crypt(btrim(p_code), gen_salt('bf')), 0, NULL, left(btrim(COALESCE(p_by, '')), 30), now())
  ON CONFLICT (grade, class_no) DO UPDATE
    SET code_hash = EXCLUDED.code_hash, fails = 0, locked_until = NULL,
        updated_by = EXCLUDED.updated_by, updated_at = now();
  RETURN 'set';
END
$fn$;

-- 선생님: 코드가 켜진 반 목록 (코드 자체는 안 보임)
CREATE OR REPLACE FUNCTION list_class_codes()
RETURNS TABLE (grade int, class_no int, updated_by text, updated_at timestamptz, locked boolean)
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT c.grade, c.class_no, c.updated_by, c.updated_at, (c.locked_until IS NOT NULL AND c.locked_until > now())
    FROM class_codes c WHERE is_notice_staff() ORDER BY c.grade, c.class_no;
$fn$;

-- 학생: 들어가기
CREATE OR REPLACE FUNCTION student_login(p_grade int, p_class int, p_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $fn$
DECLARE s text := class_code_check(p_grade, p_class, p_code);
BEGIN
  RETURN CASE WHEN s = 'ok' THEN jsonb_build_object('ok', true)
              ELSE jsonb_build_object('ok', false, 'err', s) END;
END
$fn$;

-- 학생: 암기 카드 만들기·고치기 (우리 반, 학생이 만든 것만)
CREATE OR REPLACE FUNCTION student_save_memo(
  p_grade int, p_class int, p_code text, p_name text,
  p_id bigint, p_subject text, p_title text, p_cards jsonb, p_end date)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $fn$
DECLARE
  s text := class_code_check(p_grade, p_class, p_code);
  v_name text := btrim(COALESCE(p_name, ''));
  v_title text := btrim(COALESCE(p_title, ''));
  v_cards jsonb := '[]'::jsonb;
  c jsonb;
  v_id bigint;
BEGIN
  IF s <> 'ok' THEN RETURN jsonb_build_object('ok', false, 'err', s); END IF;
  IF length(v_name) NOT BETWEEN 1 AND 20 THEN RETURN jsonb_build_object('ok', false, 'err', 'name'); END IF;
  IF length(v_title) NOT BETWEEN 1 AND 60 THEN RETURN jsonb_build_object('ok', false, 'err', 'title'); END IF;
  IF jsonb_typeof(p_cards) <> 'array' OR jsonb_array_length(p_cards) NOT BETWEEN 1 AND 100 THEN
    RETURN jsonb_build_object('ok', false, 'err', 'cards'); END IF;
  FOR c IN SELECT * FROM jsonb_array_elements(p_cards) LOOP
    IF length(btrim(COALESCE(c->>'q', ''))) NOT BETWEEN 1 AND 120 OR length(COALESCE(c->>'a', '')) > 200 THEN
      RETURN jsonb_build_object('ok', false, 'err', 'card_len'); END IF;
    v_cards := v_cards || jsonb_build_array(jsonb_build_object('q', btrim(c->>'q'), 'a', btrim(COALESCE(c->>'a', ''))));
  END LOOP;
  IF p_end IS NOT NULL AND (p_end < current_date OR p_end > current_date + 60) THEN
    RETURN jsonb_build_object('ok', false, 'err', 'end'); END IF;
  IF p_id IS NULL THEN
    IF (SELECT count(*) FROM memo_decks WHERE grade = p_grade AND class_no = p_class AND by_student) >= 15 THEN
      RETURN jsonb_build_object('ok', false, 'err', 'too_many'); END IF;
    INSERT INTO memo_decks (subject, title, cards, grade, class_no, end_at, author_name, by_student)
    VALUES (NULLIF(left(btrim(COALESCE(p_subject, '')), 20), ''), v_title, v_cards, p_grade, p_class,
            COALESCE(p_end, current_date + 30), '학생 ' || v_name, true)
    RETURNING id INTO v_id;
  ELSE
    UPDATE memo_decks
       SET subject = NULLIF(left(btrim(COALESCE(p_subject, '')), 20), ''), title = v_title, cards = v_cards,
           end_at = COALESCE(p_end, current_date + 30), author_name = '학생 ' || v_name
     WHERE id = p_id AND grade = p_grade AND class_no = p_class AND by_student
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN RETURN jsonb_build_object('ok', false, 'err', 'not_yours'); END IF;
  END IF;
  INSERT INTO audit_log (table_name, action, row_id, summary, actor_name)
  VALUES ('memo_decks', CASE WHEN p_id IS NULL THEN 'student_insert' ELSE 'student_update' END, v_id,
          v_title, '학생 ' || v_name || ' (' || p_grade || '-' || p_class || ')');
  RETURN jsonb_build_object('ok', true, 'id', v_id);
END
$fn$;

-- 학생: 암기 카드 지우기 (우리 반, 학생이 만든 것만)
CREATE OR REPLACE FUNCTION student_delete_memo(p_grade int, p_class int, p_code text, p_name text, p_id bigint)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $fn$
DECLARE
  s text := class_code_check(p_grade, p_class, p_code);
  v_title text;
BEGIN
  IF s <> 'ok' THEN RETURN jsonb_build_object('ok', false, 'err', s); END IF;
  DELETE FROM memo_decks WHERE id = p_id AND grade = p_grade AND class_no = p_class AND by_student
  RETURNING title INTO v_title;
  IF v_title IS NULL THEN RETURN jsonb_build_object('ok', false, 'err', 'not_yours'); END IF;
  INSERT INTO audit_log (table_name, action, row_id, summary, actor_name)
  VALUES ('memo_decks', 'student_delete', p_id, v_title,
          '학생 ' || left(btrim(COALESCE(p_name, '')), 20) || ' (' || p_grade || '-' || p_class || ')');
  RETURN jsonb_build_object('ok', true);
END
$fn$;

-- 학생: 청소당번 통째로 바꾸기 (우리 반)
CREATE OR REPLACE FUNCTION student_replace_cleaning(p_grade int, p_class int, p_code text, p_name text, p_rows jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $fn$
DECLARE
  s text := class_code_check(p_grade, p_class, p_code);
  v_name text := btrim(COALESCE(p_name, ''));
  r jsonb;
BEGIN
  IF s <> 'ok' THEN RETURN jsonb_build_object('ok', false, 'err', s); END IF;
  IF length(v_name) NOT BETWEEN 1 AND 20 THEN RETURN jsonb_build_object('ok', false, 'err', 'name'); END IF;
  IF jsonb_typeof(p_rows) <> 'array' OR jsonb_array_length(p_rows) > 30 THEN
    RETURN jsonb_build_object('ok', false, 'err', 'rows'); END IF;
  FOR r IN SELECT * FROM jsonb_array_elements(p_rows) LOOP
    IF length(COALESCE(r->>'area', '')) > 20 OR length(COALESCE(r->>'members', '')) > 40
       OR length(COALESCE(r->>'note', '')) > 30 THEN
      RETURN jsonb_build_object('ok', false, 'err', 'row_len'); END IF;
  END LOOP;
  DELETE FROM cleaning_duties WHERE grade = p_grade AND class_no = p_class;
  INSERT INTO cleaning_duties (grade, class_no, area, members, note, sort_order)
  SELECT p_grade, p_class, COALESCE(NULLIF(btrim(x->>'area'), ''), ' '), COALESCE(NULLIF(btrim(x->>'members'), ''), ' '),
         NULLIF(btrim(COALESCE(x->>'note', '')), ''), COALESCE((x->>'sort_order')::int, 0)
    FROM jsonb_array_elements(p_rows) x;
  INSERT INTO audit_log (table_name, action, summary, actor_name)
  VALUES ('cleaning_duties', 'student_replace', jsonb_array_length(p_rows) || '줄',
          '학생 ' || v_name || ' (' || p_grade || '-' || p_class || ')');
  RETURN jsonb_build_object('ok', true);
END
$fn$;

-- 학생: 1인1역 통째로 바꾸기 (우리 반)
CREATE OR REPLACE FUNCTION student_replace_roles(p_grade int, p_class int, p_code text, p_name text, p_rows jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $fn$
DECLARE
  s text := class_code_check(p_grade, p_class, p_code);
  v_name text := btrim(COALESCE(p_name, ''));
  r jsonb;
BEGIN
  IF s <> 'ok' THEN RETURN jsonb_build_object('ok', false, 'err', s); END IF;
  IF length(v_name) NOT BETWEEN 1 AND 20 THEN RETURN jsonb_build_object('ok', false, 'err', 'name'); END IF;
  IF jsonb_typeof(p_rows) <> 'array' OR jsonb_array_length(p_rows) > 40 THEN
    RETURN jsonb_build_object('ok', false, 'err', 'rows'); END IF;
  FOR r IN SELECT * FROM jsonb_array_elements(p_rows) LOOP
    IF length(btrim(COALESCE(r->>'role', ''))) NOT BETWEEN 1 AND 20 OR length(btrim(COALESCE(r->>'member', ''))) NOT BETWEEN 1 AND 40
       OR length(COALESCE(r->>'icon', '')) > 8 THEN
      RETURN jsonb_build_object('ok', false, 'err', 'row_len'); END IF;
  END LOOP;
  DELETE FROM class_roles WHERE grade = p_grade AND class_no = p_class;
  INSERT INTO class_roles (grade, class_no, role, member, icon, sort_order)
  SELECT p_grade, p_class, btrim(x->>'role'), btrim(x->>'member'),
         COALESCE(NULLIF(btrim(COALESCE(x->>'icon', '')), ''), '🙋'), COALESCE((x->>'sort_order')::int, 0)
    FROM jsonb_array_elements(p_rows) x;
  INSERT INTO audit_log (table_name, action, summary, actor_name)
  VALUES ('class_roles', 'student_replace', jsonb_array_length(p_rows) || '줄',
          '학생 ' || v_name || ' (' || p_grade || '-' || p_class || ')');
  RETURN jsonb_build_object('ok', true);
END
$fn$;

REVOKE ALL ON FUNCTION class_code_check(int, int, text)                FROM public;
REVOKE ALL ON FUNCTION set_class_code(int, int, text, text)            FROM public;
REVOKE ALL ON FUNCTION list_class_codes()                              FROM public;
REVOKE ALL ON FUNCTION student_login(int, int, text)                   FROM public;
REVOKE ALL ON FUNCTION student_save_memo(int, int, text, text, bigint, text, text, jsonb, date) FROM public;
REVOKE ALL ON FUNCTION student_delete_memo(int, int, text, text, bigint) FROM public;
REVOKE ALL ON FUNCTION student_replace_cleaning(int, int, text, text, jsonb) FROM public;
REVOKE ALL ON FUNCTION student_replace_roles(int, int, text, text, jsonb)    FROM public;
GRANT EXECUTE ON FUNCTION set_class_code(int, int, text, text)            TO authenticated;
GRANT EXECUTE ON FUNCTION list_class_codes()                              TO authenticated;
GRANT EXECUTE ON FUNCTION student_login(int, int, text)                   TO anon, authenticated;
GRANT EXECUTE ON FUNCTION student_save_memo(int, int, text, text, bigint, text, text, jsonb, date) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION student_delete_memo(int, int, text, text, bigint) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION student_replace_cleaning(int, int, text, text, jsonb) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION student_replace_roles(int, int, text, text, jsonb)    TO anon, authenticated;

-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT
  (SELECT count(*) FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'class_codes')                   AS 코드표_1이면_정상,
  (SELECT count(*) FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'memo_decks' AND column_name = 'by_student') AS 학생표시_1이면_정상,
  (SELECT count(*) FROM pg_proc WHERE proname IN ('student_login','student_save_memo','student_delete_memo',
                                                  'student_replace_cleaning','student_replace_roles'))  AS 학생함수_5이면_정상;
