-- ═══════════════════════════════════════════════════════════════════
-- 공동계정 만들기 - 간단히 쓰실 선생님용
-- -------------------------------------------------------------------
-- 공동계정으로 할 수 있는 것 : 공지, 평가일정, 주요일정, 수업장소,
--                              학생 호출, 분실물, 청소당번, 1인1역
-- 공동계정으로 할 수 없는 것 : 학생이 보낸 쪽지 열람(개인정보),
--                              설정 변경, 교사 계정 승인
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


-- 1) 공동계정 표시용 칸
ALTER TABLE notice_admins ADD COLUMN IF NOT EXISTS is_shared boolean DEFAULT false;


-- 2) 지금 로그인한 계정이 공동계정인지 판단하는 함수
--    (정책 안에서 표를 직접 조회하면 무한 반복이 나므로 함수로 분리)
CREATE OR REPLACE FUNCTION is_shared_account()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $fn$
  SELECT COALESCE(
    (SELECT is_shared FROM notice_admins WHERE auth_id = auth.uid()),
    false
  );
$fn$;
REVOKE ALL ON FUNCTION is_shared_account() FROM public;
GRANT EXECUTE ON FUNCTION is_shared_account() TO anon, authenticated;


-- 3) 학생 쪽지는 공동계정에게 보이지 않게 (가장 중요한 부분)
DROP POLICY IF EXISTS "msg_teacher_read"   ON messages;
CREATE POLICY "msg_teacher_read"   ON messages FOR SELECT
  USING (auth.role() = 'authenticated' AND NOT is_shared_account());

DROP POLICY IF EXISTS "msg_teacher_update" ON messages;
CREATE POLICY "msg_teacher_update" ON messages FOR UPDATE
  USING (auth.role() = 'authenticated' AND NOT is_shared_account());

DROP POLICY IF EXISTS "msg_teacher_delete" ON messages;
CREATE POLICY "msg_teacher_delete" ON messages FOR DELETE
  USING (auth.role() = 'authenticated' AND NOT is_shared_account());


-- 4) 설정(가입 코드 등)도 공동계정은 바꾸지 못하게
DROP POLICY IF EXISTS "cfg_auth_write" ON display_config;
CREATE POLICY "cfg_auth_write" ON display_config FOR ALL
  USING      (auth.role() = 'authenticated' AND NOT is_shared_account())
  WITH CHECK (auth.role() = 'authenticated' AND NOT is_shared_account());


-- ═══════════════════════════════════════════════════════════════════
-- 5) 공동계정을 실제로 만들기
-- -------------------------------------------------------------------
--   ① 먼저 관리자 화면에서 아래 정보로 [가입] 을 한 번 해주세요.
--        이메일   : haenuriboard@haenuri.sen.ms.kr   (원하는 주소로 바꾸셔도 됩니다)
--        이름     : 공동계정
--        비밀번호 : 선생님들께 알려드릴 쉬운 비밀번호
--   ② 그다음 이 아래 블록을 실행하면 승인 + 공동계정 지정이 끝납니다.
-- ═══════════════════════════════════════════════════════════════════
DO $mk$
DECLARE
  v_email text := 'haenuriboard@haenuri.sen.ms.kr';   -- ← 위에서 가입한 이메일
  v_id    uuid;
BEGIN
  SELECT id INTO v_id FROM auth.users WHERE email = v_email;
  IF v_id IS NULL THEN
    RAISE NOTICE '아직 % 계정이 없습니다. 관리자 화면에서 먼저 가입해 주세요.', v_email;
    RETURN;
  END IF;

  UPDATE auth.users
     SET email_confirmed_at = COALESCE(email_confirmed_at, now())
   WHERE id = v_id;

  INSERT INTO notice_admins (auth_id, name, approved, is_shared, is_owner)
  VALUES (v_id, '공동계정', true, true, false)
  ON CONFLICT (auth_id) DO UPDATE
    SET approved = true, is_shared = true, is_owner = false, name = '공동계정';

  RAISE NOTICE '공동계정 설정 완료 : %', v_email;
END
$mk$;


-- ═══ 확인 ═════════════════════════════════════════════════════════
SELECT u.email, na.name,
       na.approved  AS approved,
       na.is_shared AS shared,
       na.is_owner  AS owner
FROM notice_admins na
JOIN auth.users u ON u.id = na.auth_id
ORDER BY na.is_owner DESC, na.is_shared DESC;
