-- ═══════════════════════════════════════════════════════════════════
-- 🌡️ 해누리 공지 — 마음온도 체크인 (MOOD.sql)
-- -------------------------------------------------------------------
-- 학생이 교실 전자칠판이나 내 폰(mood.html)에서 마음온도를 체크인합니다.
--   · 이름은 받지 않음 — 반·단계(1~5)·느낌 낱말·시각만
--   · 넣기·읽기는 함수로만(교실 화면은 표를 직접 못 봄), 선생님은 표를 봄
--   · 한 반 하루 200번까지(장난으로 몰아 누르기 막기)
-- 기존 데이터·권한 규칙은 그대로 둡니다. 여러 번 실행해도 같은 결과입니다.
-- ⚠️ 붙여넣기 전 브라우저 자동번역을 꺼 주세요
-- ═══════════════════════════════════════════════════════════════════

-- ▼▼ 마음온도 시작
CREATE TABLE IF NOT EXISTS mood_checkins (                  -- 🌡️ 마음온도 체크인 (이름 없음)
  id         bigserial PRIMARY KEY,
  grade      int  NOT NULL,
  class_no   int  NOT NULL,
  level      int  NOT NULL CHECK (level BETWEEN 1 AND 5),
  feeling    text,
  source     text NOT NULL DEFAULT 'board' CHECK (source IN ('board', 'phone')),
  day        date NOT NULL DEFAULT ((now() AT TIME ZONE 'Asia/Seoul')::date),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mood_class_day ON mood_checkins(grade, class_no, day);
ALTER TABLE mood_checkins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mood_staff_read ON mood_checkins;
DROP POLICY IF EXISTS mood_owner_del  ON mood_checkins;
CREATE POLICY mood_staff_read ON mood_checkins FOR SELECT USING (is_notice_staff());
CREATE POLICY mood_owner_del  ON mood_checkins FOR DELETE USING (is_notice_owner());
REVOKE ALL ON mood_checkins FROM anon;
GRANT SELECT, DELETE ON mood_checkins TO authenticated;
GRANT ALL ON mood_checkins TO service_role;
GRANT USAGE, SELECT ON SEQUENCE mood_checkins_id_seq TO service_role;

-- 체크인 — 'ok' | 'bad' | 'full'(한 반 하루 200번까지)
CREATE OR REPLACE FUNCTION mood_checkin(p_grade int, p_class int, p_level int, p_feeling text, p_source text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $fn$
DECLARE v_day date := (now() AT TIME ZONE 'Asia/Seoul')::date;
BEGIN
  IF p_grade NOT BETWEEN 1 AND 6 OR p_class NOT BETWEEN 1 AND 40 OR p_level NOT BETWEEN 1 AND 5 THEN RETURN 'bad'; END IF;
  IF p_feeling IS NOT NULL AND p_feeling NOT IN (
       '피곤해요','속상해요','걱정돼요','화나요','외로워요','아파요','심심해요','졸려요','괜찮아요',
       '편안해요','신나요','설레요','뿌듯해요','고마워요') THEN RETURN 'bad'; END IF;
  IF COALESCE(p_source, 'board') NOT IN ('board', 'phone') THEN RETURN 'bad'; END IF;
  IF (SELECT count(*) FROM mood_checkins WHERE grade = p_grade AND class_no = p_class AND day = v_day) >= 200 THEN
    RETURN 'full'; END IF;
  INSERT INTO mood_checkins (grade, class_no, level, feeling, source, day)
  VALUES (p_grade, p_class, p_level, p_feeling, COALESCE(p_source, 'board'), v_day);
  RETURN 'ok';
END
$fn$;

-- 오늘 우리 반 (교실 화면 그래프·표정용, 이름 없음)
CREATE OR REPLACE FUNCTION mood_today(p_grade int, p_class int)
RETURNS TABLE (level int, feeling text, at timestamptz)
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT m.level, m.feeling, m.created_at FROM mood_checkins m
   WHERE m.grade = p_grade AND m.class_no = p_class AND m.day = (now() AT TIME ZONE 'Asia/Seoul')::date
   ORDER BY m.created_at;
$fn$;

-- 지난 며칠 우리 반 (하루 평균·인원·힘든 친구 수)
CREATE OR REPLACE FUNCTION mood_days(p_grade int, p_class int, p_days int)
RETURNS TABLE (day date, n int, avg_level numeric, low int)
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $fn$
  SELECT m.day, count(*)::int, round(avg(m.level), 2), count(*) FILTER (WHERE m.level <= 2)::int
    FROM mood_checkins m
   WHERE m.grade = p_grade AND m.class_no = p_class
     AND m.day > (now() AT TIME ZONE 'Asia/Seoul')::date - LEAST(GREATEST(COALESCE(p_days, 7), 1), 31)
   GROUP BY m.day ORDER BY m.day;
$fn$;

REVOKE ALL ON FUNCTION mood_checkin(int, int, int, text, text) FROM public;
REVOKE ALL ON FUNCTION mood_today(int, int)                    FROM public;
REVOKE ALL ON FUNCTION mood_days(int, int, int)                FROM public;
GRANT EXECUTE ON FUNCTION mood_checkin(int, int, int, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION mood_today(int, int)                    TO anon, authenticated;
GRANT EXECUTE ON FUNCTION mood_days(int, int, int)                TO anon, authenticated;

-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT
  (SELECT count(*) FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mood_checkins')                 AS 마음온도표_1이면_정상,
  (SELECT count(*) FROM pg_proc WHERE proname IN ('mood_checkin','mood_today','mood_days'))  AS 함수_3이면_정상;
