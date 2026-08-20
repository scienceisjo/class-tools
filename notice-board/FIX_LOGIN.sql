-- ═══════════════════════════════════════════════════════════════════
-- 로그인 불가 긴급 수정  (infinite recursion in policy)
-- -------------------------------------------------------------------
-- 증상 : 로그인하면 "공지 관리 권한이 없는 계정입니다" 라고 나옴
-- 원인 : 관리자 승인 정책이 notice_admins 를 다시 조회해서 무한 반복
-- 조치 : 조회를 정책 밖(보안 함수)으로 빼서 반복을 끊습니다
--
-- 이 파일만 실행하면 됩니다. 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════


-- 1) 문제가 된 정책 제거
DROP POLICY IF EXISTS "na_owner_read"   ON notice_admins;
DROP POLICY IF EXISTS "na_owner_update" ON notice_admins;


-- 2) "내가 관리담당자인가" 를 정책 밖에서 판단하는 함수
--    SECURITY DEFINER 라 정책을 타지 않아 무한 반복이 생기지 않습니다.
CREATE OR REPLACE FUNCTION is_notice_owner()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $fn$
  SELECT EXISTS (
    SELECT 1 FROM notice_admins
    WHERE auth_id = auth.uid() AND is_owner
  );
$fn$;

REVOKE ALL ON FUNCTION is_notice_owner() FROM public;
GRANT EXECUTE ON FUNCTION is_notice_owner() TO anon, authenticated;


-- 3) 정책 다시 만들기 (이번엔 함수를 사용)
DROP POLICY IF EXISTS "na_self_read" ON notice_admins;
CREATE POLICY "na_self_read" ON notice_admins FOR SELECT
  USING (auth.uid() = auth_id);

CREATE POLICY "na_owner_read" ON notice_admins FOR SELECT
  USING (is_notice_owner());

CREATE POLICY "na_owner_update" ON notice_admins FOR UPDATE
  USING (is_notice_owner());

DROP POLICY IF EXISTS "na_self_insert" ON notice_admins;
CREATE POLICY "na_self_insert" ON notice_admins FOR INSERT
  WITH CHECK (auth.uid() = auth_id);

DROP POLICY IF EXISTS "na_self_update" ON notice_admins;
CREATE POLICY "na_self_update" ON notice_admins FOR UPDATE
  USING (auth.uid() = auth_id);


-- 4) 내 계정이 관리담당자로 지정되어 있는지 다시 확인/보정
DO $fix$
DECLARE
  v_email text := 'chuseonjae@outlook.kr';
  v_id    uuid;
BEGIN
  SELECT id INTO v_id FROM auth.users WHERE email = v_email;
  IF v_id IS NULL THEN
    RAISE NOTICE 'auth 계정을 찾지 못했습니다 : %', v_email;
    RETURN;
  END IF;

  UPDATE auth.users
     SET email_confirmed_at = COALESCE(email_confirmed_at, now())
   WHERE id = v_id;

  INSERT INTO notice_admins (auth_id, name, subject, approved, is_owner)
  VALUES (v_id, '조승재', '과학', true, true)
  ON CONFLICT (auth_id) DO UPDATE
    SET approved = true, is_owner = true;
END
$fix$;


-- 5) 확인 - 아래 두 가지가 모두 나와야 정상입니다
--    (가) 내 계정이 승인됨=true, 관리담당자=true
SELECT u.email, na.name, na.approved AS approved, na.is_owner AS owner
FROM notice_admins na
JOIN auth.users u ON u.id = na.auth_id
ORDER BY na.is_owner DESC;

--    (나) 정책 목록에 na_self_read / na_owner_read 가 보이면 됨
SELECT policyname FROM pg_policies
WHERE tablename = 'notice_admins'
ORDER BY policyname;
