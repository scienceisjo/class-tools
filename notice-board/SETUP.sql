-- ═══════════════════════════════════════════════════════════════════
-- 📺 해누리중학교 전자칠판 공지 시스템 — 마이그레이션
-- 📅 2026.06
-- ───────────────────────────────────────────────────────────────────
-- Supabase SQL Editor에서 한 번에 실행하세요.
-- 모든 문이 IF NOT EXISTS / CREATE OR REPLACE 라 여러 번 실행해도 안전합니다.
-- 기존 질문나무 프로젝트(profiles/teachers)와 같은 DB에서 동작합니다.
-- ═══════════════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────────────────────────
-- 1. 📢 notices — 공지사항 (긴급 / 교과 / 학년 / 일반 통합)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notices (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category    text NOT NULL DEFAULT '일반'
              CHECK (category IN ('긴급','교과','학년','일반')),
  title       text NOT NULL,
  body        text,
  grade       int,            -- 해당 학년 (NULL = 전교)
  subject     text,           -- 교과명 (category='교과'일 때)
  pinned      boolean DEFAULT false,   -- 항상 상단 고정
  start_at    date DEFAULT CURRENT_DATE,  -- 노출 시작일
  end_at      date,           -- 노출 종료일 (NULL = 무기한)
  author_id   uuid,           -- 작성 교사 auth.uid
  author_name text,
  created_at  timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 2. 📅 schedules — 주요일정
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS schedules (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title       text NOT NULL,
  start_date  date NOT NULL,
  end_date    date,           -- 기간 일정 (NULL = 하루)
  location    text,
  icon        text DEFAULT '📌',
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 3. 🔄 timetable_changes — 시간표 변경사항
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS timetable_changes (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  change_date   date NOT NULL,
  grade         int,
  class_no      int,
  period        int,            -- 교시
  before_subj   text,           -- 원래 과목
  after_subj    text,           -- 변경 과목
  note          text,
  author_id     uuid,
  created_at    timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 4. ⚙️ display_config — 디스플레이 설정 (key-value)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS display_config (
  key        text PRIMARY KEY,
  value      text,
  updated_at timestamptz DEFAULT now()
);

-- 기본값 시드 (이미 있으면 유지)
INSERT INTO display_config (key, value) VALUES
  ('school_name',   '해누리중학교'),
  ('slide_seconds', '12'),       -- 공지 카드 자동 전환 간격(초)
  ('neis_atpt',     'B10'),      -- 서울특별시교육청
  ('neis_school',   '7130256'),  -- 해누리중학교 표준학교코드
  ('weather_lat',   '37.4989'),  -- 송파구 가락동 위도
  ('weather_lon',   '127.1180'), -- 경도
  ('admin_code',    'haenuri2026') -- 🔑 공지 관리자 가입 코드 (꼭 바꾸세요)
ON CONFLICT (key) DO NOTHING;


-- ───────────────────────────────────────────────────────────────────
-- 5. 🎯 ddays — 디데이 (시험 / 평가 / 방학 등 카운트다운)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ddays (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title       text NOT NULL,           -- 예: 1학기 기말고사
  target_date date NOT NULL,           -- 목표일
  type        text NOT NULL DEFAULT '기타'
              CHECK (type IN ('시험','평가','방학','기타')),
  icon        text DEFAULT '🎯',
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 6. 📋 assessments — 평가일정 (수행평가 / 지필평가, 과목별)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assessments (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  subject     text NOT NULL,           -- 과목
  title       text NOT NULL,           -- 평가명 (예: 함수 단원 수행평가)
  assess_type text NOT NULL DEFAULT '수행평가'
              CHECK (assess_type IN ('지필평가','수행평가','기타')),
  assess_date date NOT NULL,           -- 평가일
  grade       int,                     -- 대상 학년 (NULL = 전교)
  scope       text,                    -- 시험범위 / 비고
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 7. 📣 calls — 학생 호출 (교무실 호출 등). profiles(학생 DB)와 연계
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS calls (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_name  text NOT NULL,          -- 호출 대상 학생 이름
  grade         int,
  class_no      int,
  student_id    uuid,                   -- profiles.id (DB에서 선택 시)
  teacher_name  text NOT NULL,          -- 호출한 선생님
  location      text DEFAULT '교무실',  -- 오라는 장소
  reason        text,                   -- 사유 (선택)
  status        text NOT NULL DEFAULT 'active'
                CHECK (status IN ('active','done')),
  author_id     uuid,
  created_at    timestamptz DEFAULT now(),
  done_at       timestamptz
);


-- notices 에 링크(QR) 컬럼 추가
ALTER TABLE notices ADD COLUMN IF NOT EXISTS link text;  -- 신청서/설문 등 URL → 화면에 QR 표시


-- ───────────────────────────────────────────────────────────────────
-- 8. 🧹 cleaning_duties — 청소당번 (반별, 교실 보드용)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cleaning_duties (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade       int NOT NULL,
  class_no    int NOT NULL,
  area        text NOT NULL,          -- 구분 (조만 쓸 때는 '청소당번')
  members     text NOT NULL,          -- 청소 조 (예: 3조)
  note        text,                   -- 비고 (예: 이번 주 / 복도까지)
  sort_order  int DEFAULT 0,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);
-- 이전 버전에서 만든 표에도 note 컬럼 보강
ALTER TABLE cleaning_duties ADD COLUMN IF NOT EXISTS note text;


-- ───────────────────────────────────────────────────────────────────
-- 9. 🔍 lost_items — 분실물 (습득물, 전교 보드용)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lost_items (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  item_name   text NOT NULL,          -- 물건 (예: 검정 우산)
  found_place text,                   -- 발견 장소 (예: 3층 복도)
  keep_place  text DEFAULT '교무실',  -- 보관/찾아가는 곳
  photo_url   text,                   -- 사진 (Supabase Storage)
  status      text NOT NULL DEFAULT 'active'
              CHECK (status IN ('active','returned')),
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 10. 🙋 class_roles — 1인1역 (반별 역할 배정, 교실 보드용)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS class_roles (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade       int NOT NULL,
  class_no    int NOT NULL,
  role        text NOT NULL,          -- 역할 (예: 우유당번, 칠판, 전기)
  member      text NOT NULL,          -- 담당 학생 (예: 김OO)
  icon        text DEFAULT '🙋',
  sort_order  int DEFAULT 0,
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 11. 📍 class_locations — 수업 장소 안내 ("오늘 체육 어디서?")
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS class_locations (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  loc_date    date NOT NULL DEFAULT CURRENT_DATE,  -- 해당 날짜에만 표시
  grade       int,             -- NULL = 전체
  class_no    int,             -- NULL = 전체
  period      int,             -- 교시 (선택)
  subject     text NOT NULL,   -- 과목 (예: 체육)
  location    text NOT NULL,   -- 장소 (예: 체육관, 운동장)
  note        text,            -- 비고 (예: 비 와서 실내수업)
  author_id   uuid,
  created_at  timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- 13. 📬 messages — 학생 → 선생님 쪽지 (전자칠판에는 절대 표시 안 됨)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  to_teacher    text,                    -- 받는 선생님 (비우면 아무 선생님)
  student_name  text,                    -- 보낸 학생 (익명이면 NULL)
  grade         int,
  class_no      int,
  category      text NOT NULL DEFAULT '하고 싶은 말'
                CHECK (category IN ('하고 싶은 말','질문','건의','고민·상담','도움 요청')),
  body          text NOT NULL CHECK (length(body) BETWEEN 1 AND 1000),
  is_anonymous  boolean DEFAULT false,
  status        text NOT NULL DEFAULT 'unread'
                CHECK (status IN ('unread','read','done')),
  created_at    timestamptz DEFAULT now(),
  read_at       timestamptz
);


-- ───────────────────────────────────────────────────────────────────
-- 14. 🔑 notice_admins — 공지 전용 관리자 계정 (질문나무 teachers 와 별개)
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notice_admins (
  auth_id    uuid PRIMARY KEY,        -- Supabase Auth user id
  name       text NOT NULL,
  subject    text,                    -- 담당 과목 (교과 공지 자동입력용, 선택)
  created_at timestamptz DEFAULT now()
);


-- ───────────────────────────────────────────────────────────────────
-- ⚡ 인덱스
-- ───────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_notices_window   ON notices(start_at, end_at);
CREATE INDEX IF NOT EXISTS idx_notices_category ON notices(category);
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


-- ═══════════════════════════════════════════════════════════════════
-- 🔐 RLS — 디스플레이는 익명 읽기 가능, 작성/수정은 로그인 교사만
-- ═══════════════════════════════════════════════════════════════════

-- 공통: 누구나(익명 포함) SELECT 허용 / 인증 사용자만 쓰기
-- notices ----------------------------------------------------------
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notices_public_read"   ON notices;
CREATE POLICY "notices_public_read"   ON notices FOR SELECT USING (true);
DROP POLICY IF EXISTS "notices_auth_insert"   ON notices;
CREATE POLICY "notices_auth_insert"   ON notices FOR INSERT WITH CHECK (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "notices_auth_update"   ON notices;
CREATE POLICY "notices_auth_update"   ON notices FOR UPDATE USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "notices_auth_delete"   ON notices;
CREATE POLICY "notices_auth_delete"   ON notices FOR DELETE USING (auth.role() = 'authenticated');

-- schedules --------------------------------------------------------
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "schedules_public_read" ON schedules;
CREATE POLICY "schedules_public_read" ON schedules FOR SELECT USING (true);
DROP POLICY IF EXISTS "schedules_auth_write"  ON schedules;
CREATE POLICY "schedules_auth_write"  ON schedules FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- timetable_changes ------------------------------------------------
ALTER TABLE timetable_changes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ttc_public_read" ON timetable_changes;
CREATE POLICY "ttc_public_read" ON timetable_changes FOR SELECT USING (true);
DROP POLICY IF EXISTS "ttc_auth_write"  ON timetable_changes;
CREATE POLICY "ttc_auth_write"  ON timetable_changes FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- ddays ------------------------------------------------------------
ALTER TABLE ddays ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ddays_public_read" ON ddays;
CREATE POLICY "ddays_public_read" ON ddays FOR SELECT USING (true);
DROP POLICY IF EXISTS "ddays_auth_write"  ON ddays;
CREATE POLICY "ddays_auth_write"  ON ddays FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- assessments ------------------------------------------------------
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "assess_public_read" ON assessments;
CREATE POLICY "assess_public_read" ON assessments FOR SELECT USING (true);
DROP POLICY IF EXISTS "assess_auth_write"  ON assessments;
CREATE POLICY "assess_auth_write"  ON assessments FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- calls ------------------------------------------------------------
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "calls_public_read" ON calls;
CREATE POLICY "calls_public_read" ON calls FOR SELECT USING (true);
DROP POLICY IF EXISTS "calls_auth_write"  ON calls;
CREATE POLICY "calls_auth_write"  ON calls FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- cleaning_duties --------------------------------------------------
ALTER TABLE cleaning_duties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "clean_public_read" ON cleaning_duties;
CREATE POLICY "clean_public_read" ON cleaning_duties FOR SELECT USING (true);
DROP POLICY IF EXISTS "clean_auth_write"  ON cleaning_duties;
CREATE POLICY "clean_auth_write"  ON cleaning_duties FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- lost_items -------------------------------------------------------
ALTER TABLE lost_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lost_public_read" ON lost_items;
CREATE POLICY "lost_public_read" ON lost_items FOR SELECT USING (true);
DROP POLICY IF EXISTS "lost_auth_write"  ON lost_items;
CREATE POLICY "lost_auth_write"  ON lost_items FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- class_roles ------------------------------------------------------
ALTER TABLE class_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "roles_public_read" ON class_roles;
CREATE POLICY "roles_public_read" ON class_roles FOR SELECT USING (true);
DROP POLICY IF EXISTS "roles_auth_write"  ON class_roles;
CREATE POLICY "roles_auth_write"  ON class_roles FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- class_locations --------------------------------------------------
ALTER TABLE class_locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "loc_public_read" ON class_locations;
CREATE POLICY "loc_public_read" ON class_locations FOR SELECT USING (true);
DROP POLICY IF EXISTS "loc_auth_write"  ON class_locations;
CREATE POLICY "loc_auth_write"  ON class_locations FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- 📬 messages (학생→교사 쪽지) ⚠️ 보안 핵심 ------------------------
--   · 학생(익명)은 '보내기(INSERT)'만 가능
--   · 읽기(SELECT)는 로그인한 교사만 → 학생끼리 남의 쪽지 못 봄
--   · 전자칠판(익명)도 읽을 수 없으므로 화면에 노출될 일이 없음
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "msg_anyone_insert" ON messages;
CREATE POLICY "msg_anyone_insert" ON messages FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "msg_teacher_read"  ON messages;
CREATE POLICY "msg_teacher_read"  ON messages FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "msg_teacher_update" ON messages;
CREATE POLICY "msg_teacher_update" ON messages FOR UPDATE USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "msg_teacher_delete" ON messages;
CREATE POLICY "msg_teacher_delete" ON messages FOR DELETE USING (auth.role() = 'authenticated');

-- notice_admins (본인 행만 조회/등록) -------------------------------
ALTER TABLE notice_admins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "na_self_read"   ON notice_admins;
CREATE POLICY "na_self_read"   ON notice_admins FOR SELECT USING (auth.uid() = auth_id);
DROP POLICY IF EXISTS "na_self_insert" ON notice_admins;
CREATE POLICY "na_self_insert" ON notice_admins FOR INSERT WITH CHECK (auth.uid() = auth_id);
DROP POLICY IF EXISTS "na_self_update" ON notice_admins;
CREATE POLICY "na_self_update" ON notice_admins FOR UPDATE USING (auth.uid() = auth_id);

-- display_config ---------------------------------------------------
ALTER TABLE display_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "cfg_public_read" ON display_config;
CREATE POLICY "cfg_public_read" ON display_config FOR SELECT USING (true);
DROP POLICY IF EXISTS "cfg_auth_write"  ON display_config;
CREATE POLICY "cfg_auth_write"  ON display_config FOR ALL
  USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');


-- ═══════════════════════════════════════════════════════════════════
-- 🔔 실시간(Realtime) 활성화 — 공지 올리면 전자칠판에 즉시 반영
-- ═══════════════════════════════════════════════════════════════════
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END$$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notices;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE schedules;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE timetable_changes;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE display_config;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE ddays;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE assessments;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE calls;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE cleaning_duties;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE lost_items;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE class_locations;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE class_roles;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;
-- messages 는 RLS로 교사만 읽히므로 전자칠판엔 전달되지 않음 (관리자 실시간 알림용)
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION WHEN duplicate_object THEN NULL; END$$;


-- ═══════════════════════════════════════════════════════════════════
-- 📋 확인 쿼리
-- ═══════════════════════════════════════════════════════════════════
SELECT
  (SELECT COUNT(*) FROM notices)            AS 공지수,
  (SELECT COUNT(*) FROM schedules)          AS 일정수,
  (SELECT COUNT(*) FROM timetable_changes)  AS 시간표변경수,
  (SELECT COUNT(*) FROM ddays)              AS 디데이수,
  (SELECT COUNT(*) FROM assessments)        AS 평가일정수,
  (SELECT COUNT(*) FROM calls)              AS 호출수,
  (SELECT COUNT(*) FROM cleaning_duties)    AS 청소당번수,
  (SELECT COUNT(*) FROM lost_items)         AS 분실물수,
  (SELECT COUNT(*) FROM class_locations)    AS 장소안내수,
  (SELECT COUNT(*) FROM class_roles)        AS 일인일역수,
  (SELECT COUNT(*) FROM messages)           AS 받은쪽지수,
  (SELECT COUNT(*) FROM display_config)     AS 설정수;
