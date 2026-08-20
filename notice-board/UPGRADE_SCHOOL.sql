-- ═══════════════════════════════════════════════════════════════════
-- 🏫 전 교사 배포용 보완 — 이 SQL 하나만 실행하면 됩니다
-- ───────────────────────────────────────────────────────────────────
-- 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════

-- ① 쪽지: 교사별 읽음 처리 + 받는 교사 지정
--    (한 명이 열었다고 다른 선생님 알림이 사라지지 않게)
CREATE TABLE IF NOT EXISTS message_reads (
  message_id bigint NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  reader_id  uuid   NOT NULL,
  read_at    timestamptz DEFAULT now(),
  PRIMARY KEY (message_id, reader_id)
);
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "mr_self" ON message_reads;
CREATE POLICY "mr_self" ON message_reads FOR ALL
  USING (auth.uid() = reader_id) WITH CHECK (auth.uid() = reader_id);

-- 받는 교사 계정을 지정할 수 있게 (학생이 이름으로 고르면 여기에 매칭)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS to_auth_id uuid;
CREATE INDEX IF NOT EXISTS idx_msg_to ON messages(to_auth_id);


-- ② 삭제 권한: 본인이 올린 것만 지울 수 있게
--    (author_id 가 없는 예전 자료는 누구나 정리 가능하도록 허용)
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['notices','schedules','timetable_changes','ddays',
                           'assessments','class_locations','lost_items']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t||'_auth_delete', t);
    EXECUTE format($f$
      CREATE POLICY %I ON %I FOR DELETE
      USING (auth.role() = 'authenticated'
             AND (author_id IS NULL OR author_id = auth.uid()))
    $f$, t||'_auth_delete', t);
  END LOOP;
END$$;

-- 위 정책이 먹으려면 기존의 '전부 허용' 정책을 걷어내야 합니다
DROP POLICY IF EXISTS "schedules_auth_write"  ON schedules;
DROP POLICY IF EXISTS "ttc_auth_write"        ON timetable_changes;
DROP POLICY IF EXISTS "ddays_auth_write"      ON ddays;
DROP POLICY IF EXISTS "assess_auth_write"     ON assessments;
DROP POLICY IF EXISTS "loc_auth_write"        ON class_locations;
DROP POLICY IF EXISTS "lost_auth_write"       ON lost_items;

-- 쓰기(INSERT)·수정(UPDATE)은 계속 모든 교사에게 허용
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['schedules','timetable_changes','ddays',
                           'assessments','class_locations','lost_items']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t||'_ins', t);
    EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (auth.role() = ''authenticated'')', t||'_ins', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t||'_upd', t);
    EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE USING (auth.role() = ''authenticated'')', t||'_upd', t);
  END LOOP;
END$$;


-- ②-2 공지 수정도 본인 것만 (다른 선생님 공지를 바꿔 쓰지 못하게)
DROP POLICY IF EXISTS "notices_auth_update" ON notices;
CREATE POLICY "notices_auth_update" ON notices FOR UPDATE
  USING (auth.role() = 'authenticated'
         AND (author_id IS NULL OR author_id = auth.uid()));


-- ③ 가입 승인제: 가입은 되지만 승인 전에는 글을 못 올림
ALTER TABLE notice_admins ADD COLUMN IF NOT EXISTS approved boolean DEFAULT false;
ALTER TABLE notice_admins ADD COLUMN IF NOT EXISTS is_owner boolean DEFAULT false;

-- 이미 가입해 쓰고 계신 분들은 모두 승인 처리 (기존 사용 끊기지 않도록)
UPDATE notice_admins SET approved = true WHERE approved IS DISTINCT FROM true;

-- 첫 번째 계정(가장 먼저 가입한 사람)을 관리자로 지정
UPDATE notice_admins SET is_owner = true
WHERE auth_id = (SELECT auth_id FROM notice_admins ORDER BY created_at LIMIT 1);

-- 관리자는 다른 교사 계정을 조회·승인할 수 있어야 함
DROP POLICY IF EXISTS "na_owner_read" ON notice_admins;
CREATE POLICY "na_owner_read" ON notice_admins FOR SELECT
  USING (EXISTS (SELECT 1 FROM notice_admins o
                 WHERE o.auth_id = auth.uid() AND o.is_owner));
DROP POLICY IF EXISTS "na_owner_update" ON notice_admins;
CREATE POLICY "na_owner_update" ON notice_admins FOR UPDATE
  USING (EXISTS (SELECT 1 FROM notice_admins o
                 WHERE o.auth_id = auth.uid() AND o.is_owner));


-- ④ 긴급공지 자동 만료: 종료일을 안 넣으면 당일까지만
CREATE OR REPLACE FUNCTION notices_urgent_default_end()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.category = '긴급' AND NEW.end_at IS NULL THEN
    NEW.end_at := CURRENT_DATE;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_urgent_end ON notices;
CREATE TRIGGER trg_urgent_end BEFORE INSERT OR UPDATE ON notices
  FOR EACH ROW EXECUTE FUNCTION notices_urgent_default_end();


-- ⑤ 변경 기록 (누가 무엇을 지웠는지)
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
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "audit_read"   ON audit_log;
CREATE POLICY "audit_read"   ON audit_log FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "audit_insert" ON audit_log;
CREATE POLICY "audit_insert" ON audit_log FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_log(created_at DESC);


-- ⑥ 청소당번 동시 편집 유실 방지용 — 반 단위로 한 번에 바꾸는 함수
CREATE OR REPLACE FUNCTION replace_cleaning(
  p_grade int, p_class int, p_rows jsonb, p_author uuid
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM cleaning_duties WHERE grade = p_grade AND class_no = p_class;
  INSERT INTO cleaning_duties (grade, class_no, area, members, note, sort_order, author_id)
  SELECT p_grade, p_class,
         COALESCE(r->>'area',' '), COALESCE(r->>'members',' '),
         NULLIF(r->>'note',''), COALESCE((r->>'sort_order')::int, 0), p_author
  FROM jsonb_array_elements(p_rows) r;
END $$;
REVOKE ALL ON FUNCTION replace_cleaning(int,int,jsonb,uuid) FROM public;
GRANT EXECUTE ON FUNCTION replace_cleaning(int,int,jsonb,uuid) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════
-- ✅ 확인
-- ═══════════════════════════════════════════════════════════════════
SELECT
  (SELECT COUNT(*) FROM notice_admins)                          AS 교사계정수,
  (SELECT COUNT(*) FROM notice_admins WHERE approved)           AS 승인됨,
  (SELECT COUNT(*) FROM notice_admins WHERE is_owner)           AS 관리자수,
  (SELECT COUNT(*) FROM message_reads)                          AS 읽음기록,
  (SELECT COUNT(*) FROM audit_log)                              AS 변경기록;
