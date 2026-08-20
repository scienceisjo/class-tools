-- ═══════════════════════════════════════════════════════════════════
-- 🔑 가입 코드 변경
-- ───────────────────────────────────────────────────────────────────
-- 이 파일만 단독으로 실행해도 됩니다.
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO display_config (key, value)
VALUES ('admin_code', 'hnrnotice26!')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();

-- 확인 — 현재 가입 코드가 무엇인지 보여줍니다
SELECT value AS 현재_가입코드 FROM display_config WHERE key = 'admin_code';
