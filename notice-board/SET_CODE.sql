-- ═══════════════════════════════════════════════════════════════════
-- 🔑 가입 코드 변경
-- ───────────────────────────────────────────────────────────────────
-- 이 한 줄만 실행하면 됩니다.
-- (관리자 화면 ⚙️ 설정 → 🔑 가입 코드 에서도 바꿀 수 있어요)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO display_config (key, value)
VALUES ('admin_code', 'hnrnotice26!')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();

-- 확인 — 아래가 true 로 나오면 성공
SELECT check_admin_code('hnrnotice26!') AS 새코드_적용됨;
