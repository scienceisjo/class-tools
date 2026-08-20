-- ═══════════════════════════════════════════════════════════════════
-- 🔒 가입 코드 감추기 — 이 SQL 하나만 실행하면 됩니다
-- ───────────────────────────────────────────────────────────────────
-- 실행 후에는 F12(개발자도구)로도 가입 코드가 보이지 않습니다.
-- 여러 번 실행해도 안전합니다.
-- ═══════════════════════════════════════════════════════════════════

-- 1) 가입 코드는 로그인한 교사만 읽을 수 있게
--    (전자칠판은 학교명·NEIS코드 등 나머지 설정만 계속 읽습니다)
DROP POLICY IF EXISTS "cfg_public_read" ON display_config;
CREATE POLICY "cfg_public_read" ON display_config FOR SELECT
  USING (key <> 'admin_code' OR auth.role() = 'authenticated');

-- 2) 가입 화면은 로그인 전이라 코드를 읽을 수 없으므로,
--    "입력한 코드가 맞는지"만 서버가 대조해 true/false 로 답하게 함
CREATE OR REPLACE FUNCTION check_admin_code(code text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM display_config
    WHERE key = 'admin_code' AND value = code
  );
$$;

REVOKE ALL ON FUNCTION check_admin_code(text) FROM public;
GRANT EXECUTE ON FUNCTION check_admin_code(text) TO anon, authenticated;


-- 3) (권장) 가입 코드를 추측하기 어려운 값으로 변경
--    아래 줄 앞의 -- 를 지우고, 원하는 코드로 바꿔 실행하세요.
-- UPDATE display_config SET value = '여기에_새코드' WHERE key = 'admin_code';


-- ═══════════════════════════════════════════════════════════════════
-- ✅ 확인 — 아래 결과가 이렇게 나오면 성공
--    익명읽기_차단됨 = true   (익명에게는 admin_code 가 안 보임)
--    코드대조_동작   = true
-- ═══════════════════════════════════════════════════════════════════
SELECT
  (SELECT COUNT(*) = 0 FROM display_config
     WHERE key = 'admin_code'
       AND NOT (key <> 'admin_code' OR 'authenticated' = 'anon')) AS 정책적용됨,
  check_admin_code((SELECT value FROM display_config WHERE key='admin_code')) AS 코드대조_동작,
  check_admin_code('틀린코드아무거나')                              AS 틀린코드는_false;
