-- ═══════════════════════════════════════════════════════════════════
-- 🎂 이달의 생일
-- -------------------------------------------------------------------
-- 담임 선생님이 우리 반 학생 생일을 넣어두면, 교실 전자칠판
-- 청소당번 칸의 [🎂 생일] 에 이번 달 생일이 나옵니다.
-- 생일 당일에는 위쪽 디데이 줄에 「🎂 오늘 생일」 이 뜹니다.
--
-- 개인정보를 생각해서 이렇게 해두었습니다.
--   · 태어난 해는 저장하지 않습니다 (월·일만)
--   · 로그인 없이 보는 교실 화면에는 "이번 달" 것만 읽힙니다
--     (지난 달·다음 달 생일은 서버가 내주지 않습니다)
--   · 넣고 고치는 것은 로그인한 선생님만, 지우는 것은 본인·관리담당자·그 반 담임만
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


CREATE TABLE IF NOT EXISTS birthdays (
  id          bigserial PRIMARY KEY,
  grade       int  NOT NULL,
  class_no    int  NOT NULL,
  name        text NOT NULL,
  month       int  NOT NULL CHECK (month BETWEEN 1 AND 12),
  day         int  NOT NULL CHECK (day   BETWEEN 1 AND 31),
  author_id   uuid,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grade, class_no, name, month, day)
);

CREATE INDEX IF NOT EXISTS idx_birthdays_class ON birthdays(grade, class_no, month, day);

ALTER TABLE birthdays ENABLE ROW LEVEL SECURITY;

-- 읽기 : 로그인한 선생님은 전부, 로그인 없는 교실 화면은 이번 달(한국시간)만
DROP POLICY IF EXISTS "bd_read" ON birthdays;
CREATE POLICY "bd_read" ON birthdays FOR SELECT
  USING (
    auth.role() = 'authenticated'
    OR month = EXTRACT(MONTH FROM (now() AT TIME ZONE 'Asia/Seoul'))::int
  );

DROP POLICY IF EXISTS "bd_insert" ON birthdays;
CREATE POLICY "bd_insert" ON birthdays FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "bd_delete" ON birthdays;
CREATE POLICY "bd_delete" ON birthdays FOR DELETE
  USING (
    auth.role() = 'authenticated'
    AND ( author_id IS NULL
       OR author_id = auth.uid()
       OR is_notice_owner()
       OR is_homeroom_of(grade, class_no) )
  );


-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'birthdays'
ORDER BY cmd;
--   -> DELETE / INSERT / SELECT 세 줄이 보이면 정상입니다
