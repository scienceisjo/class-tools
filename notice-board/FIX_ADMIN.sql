-- ═══════════════════════════════════════════════════════════════════
-- 🔧 관리자 계정 진단 & 복구  (chuseonjae@outlook.kr)
-- ───────────────────────────────────────────────────────────────────
-- ① 먼저 [1단계]만 실행해서 상태를 확인하세요.
-- ② 결과를 보고 [2단계]를 실행하면 대부분 해결됩니다.
-- ═══════════════════════════════════════════════════════════════════


-- ═══ 1단계 · 진단 ═══════════════════════════════════════════════
-- (가) 계정이 이 프로젝트에 존재하는가?
SELECT
  id                                   AS 계정ID,
  email                                AS 이메일,
  (email_confirmed_at IS NOT NULL)     AS 이메일인증됨,
  created_at                           AS 가입일시
FROM auth.users
WHERE email = 'chuseonjae@outlook.kr';
--   → 결과가 0행이면: 이 프로젝트에 계정이 없습니다.
--      (예전 프로젝트에 가입하셨거나, 아직 가입 전입니다) → 관리자 화면에서 [가입] 먼저

-- (나) 공지 관리 권한(notice_admins)에 등록·승인되어 있는가?
SELECT
  na.name        AS 이름,
  na.subject     AS 과목,
  na.approved    AS 승인됨,
  na.is_owner    AS 관리담당자,
  u.email        AS 이메일
FROM notice_admins na
LEFT JOIN auth.users u ON u.id = na.auth_id
ORDER BY na.created_at;
--   → 목록에 내 이메일이 없으면: 권한 등록이 안 된 상태
--   → 승인됨 = false 이면: 승인 대기 상태


-- ═══ 2단계 · 복구 ═══════════════════════════════════════════════
-- 아래 블록을 그대로 실행하면
--   · 이메일 인증이 안 되어 있으면 인증 처리
--   · 권한이 없으면 등록
--   · 승인 + 관리담당자(👑)로 지정
-- 까지 한 번에 처리합니다. (계정 자체가 없으면 아무 일도 하지 않습니다)

DO $$
DECLARE
  v_email text := 'chuseonjae@outlook.kr';
  v_id    uuid;
BEGIN
  SELECT id INTO v_id FROM auth.users WHERE email = v_email;

  IF v_id IS NULL THEN
    RAISE NOTICE '⚠️ % 계정이 이 프로젝트에 없습니다. 관리자 화면에서 [가입]을 먼저 해주세요.', v_email;
    RETURN;
  END IF;

  -- 이메일 인증이 안 되어 있으면 인증 처리 (로그인 막힘 방지)
  UPDATE auth.users
     SET email_confirmed_at = COALESCE(email_confirmed_at, now())
   WHERE id = v_id;

  -- 공지 관리 권한 등록 + 승인 + 관리담당자 지정
  INSERT INTO notice_admins (auth_id, name, subject, approved, is_owner)
  VALUES (v_id, '조승재', '과학', true, true)
  ON CONFLICT (auth_id) DO UPDATE
    SET approved = true,
        is_owner = true,
        name     = COALESCE(NULLIF(notice_admins.name,''), '조승재');

  -- 관리담당자는 한 명만 유지
  UPDATE notice_admins SET is_owner = false WHERE auth_id <> v_id;

  RAISE NOTICE '✅ % 관리자 설정 완료', v_email;
END$$;


-- ═══ 3단계 · 확인 ═══════════════════════════════════════════════
SELECT
  u.email     AS 이메일,
  na.name     AS 이름,
  na.approved AS 승인됨,
  na.is_owner AS 관리담당자,
  (u.email_confirmed_at IS NOT NULL) AS 이메일인증됨
FROM notice_admins na
JOIN auth.users u ON u.id = na.auth_id
ORDER BY na.is_owner DESC, na.created_at;
--   → 내 이메일이 승인됨=true, 관리담당자=true 로 나오면 성공입니다.
--     (비밀번호가 기억나지 않으면 Supabase → Authentication → Users
--      → 해당 계정 → Reset password 로 새로 정하실 수 있습니다)
