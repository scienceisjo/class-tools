-- ═══════════════════════════════════════════════════════════════════
-- 🎬 영상 — 교실 화면에서 바로 재생
-- -------------------------------------------------------------------
-- 선생님이 유튜브 주소를 넣어두시면, 교실 전자칠판에서
-- [🎬 영상] 을 눌러 바로 보실 수 있습니다.
--
-- 대상 학년·반은 공지와 똑같이 동작합니다.
--   비워두면 전교 / 학년만 넣으면 그 학년 / 학년+반이면 그 반에만
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


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

CREATE INDEX IF NOT EXISTS idx_videos_class ON videos(grade, class_no);
CREATE INDEX IF NOT EXISTS idx_videos_when  ON videos(start_at, end_at);


-- ═══ 권한 ═════════════════════════════════════════════════════════
-- 교실 화면은 로그인 없이 보므로 읽기는 누구나,
-- 올리고 지우는 것은 로그인한 선생님만 (공지와 같은 규칙)
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "videos_public_read" ON videos;
CREATE POLICY "videos_public_read" ON videos FOR SELECT USING (true);

DROP POLICY IF EXISTS "videos_auth_insert" ON videos;
CREATE POLICY "videos_auth_insert" ON videos FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- 고치고 지우는 것은 본인 것 · 관리담당자 · 그 반 담임만
DROP POLICY IF EXISTS "videos_auth_update" ON videos;
CREATE POLICY "videos_auth_update" ON videos FOR UPDATE
  USING (
    auth.role() = 'authenticated'
    AND ( author_id IS NULL
       OR author_id = auth.uid()
       OR is_notice_owner()
       OR (grade IS NOT NULL AND class_no IS NOT NULL AND is_homeroom_of(grade, class_no)) )
  );

DROP POLICY IF EXISTS "videos_auth_delete" ON videos;
CREATE POLICY "videos_auth_delete" ON videos FOR DELETE
  USING (
    auth.role() = 'authenticated'
    AND ( author_id IS NULL
       OR author_id = auth.uid()
       OR is_notice_owner()
       OR (grade IS NOT NULL AND class_no IS NOT NULL AND is_homeroom_of(grade, class_no)) )
  );


-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'videos'
ORDER BY cmd;
--   -> SELECT / INSERT / UPDATE / DELETE 네 줄이 보이면 정상입니다
