-- ═══════════════════════════════════════════════════════════════════
-- 공동계정 — "지금 쓰시는 선생님" 명단
-- -------------------------------------------------------------------
-- 공동계정은 여러 선생님이 함께 쓰는 계정이라, 그냥 올리면 전자칠판에
-- 모두 "공동계정 선생님"으로 표시됩니다.
-- 그래서 올리실 때 이름을 한 번 고르시면, 그 이름으로 올라가게 합니다.
--
-- 이 표는 그 이름 목록입니다. 선생님이 한 번 쓰시면 자동으로 쌓이므로
-- 따로 명단을 관리하실 필요가 없습니다.
--
-- 담기는 것 : 선생님 성함, 담당 과목, 소속 부서 (교직원 정보)
-- 담기지 않는 것 : 학생 정보는 하나도 들어가지 않습니다.
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


CREATE TABLE IF NOT EXISTS shared_posters (
  name    text PRIMARY KEY,
  subject text,
  dept    text,
  uses    int  NOT NULL DEFAULT 0,
  used_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE shared_posters ENABLE ROW LEVEL SECURITY;

-- 전자칠판 화면(로그인 없이 보는 쪽)에는 필요 없는 정보라
-- 로그인한 선생님에게만 보이게 합니다.
DROP POLICY IF EXISTS "sp_read"  ON shared_posters;
CREATE POLICY "sp_read"  ON shared_posters FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "sp_write" ON shared_posters;
CREATE POLICY "sp_write" ON shared_posters FOR ALL
  USING      (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- 이름을 쓸 때마다 불러 주는 함수
-- (같은 이름이면 새로 만들지 않고 과목·부서만 최신으로 채웁니다)
CREATE OR REPLACE FUNCTION touch_poster(p_name text, p_subject text, p_dept text)
RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $fn$
  INSERT INTO shared_posters (name, subject, dept, uses, used_at)
  VALUES (
    btrim(p_name),
    NULLIF(btrim(COALESCE(p_subject, '')), ''),
    NULLIF(btrim(COALESCE(p_dept,    '')), ''),
    1, now()
  )
  ON CONFLICT (name) DO UPDATE
    SET subject = COALESCE(EXCLUDED.subject, shared_posters.subject),
        dept    = COALESCE(EXCLUDED.dept,    shared_posters.dept),
        uses    = shared_posters.uses + 1,
        used_at = now();
$fn$;

REVOKE ALL ON FUNCTION touch_poster(text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION touch_poster(text, text, text) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════
-- 이미 올라간 공지에서 이름을 모아 명단을 채워 둡니다
-- ("공동계정" 같은 이름은 빼고 담습니다)
-- ═══════════════════════════════════════════════════════════════════
INSERT INTO shared_posters (name, uses, used_at)
SELECT author_name, count(*), max(created_at)
FROM notices
WHERE author_name IS NOT NULL
  AND btrim(author_name) <> ''
  AND author_name NOT IN ('공동계정', '공용계정', '둘러보기')
GROUP BY author_name
ON CONFLICT (name) DO NOTHING;


-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT name, subject, dept, uses, used_at
FROM shared_posters ORDER BY uses DESC, name;
