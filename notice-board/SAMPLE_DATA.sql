-- ═══════════════════════════════════════════════════════════════════
-- 📺 전자칠판 공지 — 샘플 데이터 (선택 사항)
-- ───────────────────────────────────────────────────────────────────
-- notice_migration.sql 을 먼저 실행한 뒤, 이 파일을 실행하면
-- 화면이 어떻게 보이는지 바로 확인할 수 있는 예시 데이터가 들어갑니다.
-- 날짜는 실행한 날(CURRENT_DATE)을 기준으로 자동 계산됩니다.
--
-- 🧹 나중에 지우려면 맨 아래 "샘플 삭제" 블록의 주석을 풀고 실행하세요.
-- ═══════════════════════════════════════════════════════════════════

-- ── 📢 공지사항 ──
INSERT INTO notices (category, title, body, grade, subject, pinned, start_at, end_at, author_name) VALUES
  ('긴급', '5교시 후 화재 대피 훈련', '전교생은 안내방송에 따라 운동장으로 신속히 대피해 주세요.',
     NULL, NULL, false, CURRENT_DATE, CURRENT_DATE, '관리자'),
  ('교과', '2학년 수학 수행평가 안내', '함수 단원 수행평가를 실시합니다. 교과서 3단원 복습 및 계산기를 준비하세요.',
     2, '수학', false, CURRENT_DATE, CURRENT_DATE + 7, '김수학'),
  ('학년', '3학년 진로체험의 날 신청', '희망 직업군 사전조사서를 담임 선생님께 제출하세요. (신청 마감 임박)',
     3, NULL, false, CURRENT_DATE, CURRENT_DATE + 5, '이진로'),
  ('일반', '도서관 여름 운영시간 변경', '7월부터 도서관은 오전 8시 30분 ~ 오후 5시까지 운영합니다.',
     NULL, NULL, true, CURRENT_DATE, CURRENT_DATE + 30, '도서관');

-- ── 📅 주요일정 ──
INSERT INTO schedules (title, start_date, end_date, location, icon) VALUES
  ('2학기 등록금 납부 마감', CURRENT_DATE + 3, NULL, NULL, '💳'),
  ('동아리 발표회',          CURRENT_DATE + 6, NULL, '강당', '🎭'),
  ('1학기 기말고사',         CURRENT_DATE + 11, CURRENT_DATE + 13, NULL, '📝'),
  ('여름방학식',             CURRENT_DATE + 23, NULL, NULL, '🏖️');

-- ── 🔄 시간표 변경 (오늘) ──
INSERT INTO timetable_changes (change_date, grade, class_no, period, before_subj, after_subj, note) VALUES
  (CURRENT_DATE, 2, 3, 4, '국어', '체육', '운동장'),
  (CURRENT_DATE, 1, 2, 6, '미술', '자율', NULL);

-- ── 🎯 디데이 ──
INSERT INTO ddays (title, target_date, type, icon) VALUES
  ('수행평가(과학)', CURRENT_DATE + 3,  '평가', '📊'),
  ('1학기 기말고사', CURRENT_DATE + 11, '시험', '📝'),
  ('여름방학',       CURRENT_DATE + 23, '방학', '🏖️');

-- ── 📋 평가일정 ──
INSERT INTO assessments (subject, title, assess_type, assess_date, grade, scope) VALUES
  ('과학', '광합성 단원 수행평가', '수행평가', CURRENT_DATE + 3,  2, '교과서 4단원, 보고서 지참'),
  ('영어', '말하기 수행평가',      '수행평가', CURRENT_DATE + 5,  1, 'Unit 5 대본 암기'),
  ('수학', '1학기 기말고사(수학)', '지필평가', CURRENT_DATE + 11, NULL, '함수~통계 전 단원'),
  ('국어', '1학기 기말고사(국어)', '지필평가', CURRENT_DATE + 12, NULL, '교과서 + 보충자료');

-- ── 📣 학생 호출 (활성) ──
INSERT INTO calls (student_name, grade, class_no, teacher_name, location, reason, status) VALUES
  ('홍길동', 2, 3, '김영희', '교무실', '상담', 'active'),
  ('이순신', 1, 2, '박철수', '과학실', NULL, 'active');

-- ── 🔗 QR 공지 (링크 포함) ──
INSERT INTO notices (category, title, body, grade, link, start_at, end_at, author_name) VALUES
  ('일반', '독서골든벨 참가 신청', '아래 QR을 휴대폰으로 스캔해 신청서를 작성하세요. (마감 금요일)',
     NULL, 'https://forms.gle/example', CURRENT_DATE, CURRENT_DATE + 5, '도서관');

-- ── 🧹 청소당번 (2학년 3반 예시 — notice.html?class=2-3 에서 표시) ──
INSERT INTO cleaning_duties (grade, class_no, area, members, sort_order) VALUES
  (2, 3, '교실 앞',    '1모둠',        1),
  (2, 3, '복도·계단',  '2모둠',        2),
  (2, 3, '칠판·교탁',  '김OO·이OO',    3);

-- ── 🙋 1인1역 (2학년 3반 예시 — notice.html?class=2-3 에서 토글로 표시) ──
INSERT INTO class_roles (grade, class_no, role, member, icon, sort_order) VALUES
  (2, 3, '우유당번',     '김OO', '🥛', 1),
  (2, 3, '전기·에어컨', '이OO', '💡', 2),
  (2, 3, '알림장',       '박OO', '📋', 3),
  (2, 3, '창문·환기',   '최OO', '🪟', 4),
  (2, 3, '재활용',       '정OO', '♻️', 5);

-- ── 📍 수업 장소 안내 (오늘) ──
INSERT INTO class_locations (loc_date, grade, class_no, period, subject, location, note) VALUES
  (CURRENT_DATE, 2, NULL, 3, '체육', '체육관', '미세먼지로 실내수업'),
  (CURRENT_DATE, 1, 2, NULL, '음악', '음악실', NULL);

-- ── 🔍 분실물 (습득물) ──
INSERT INTO lost_items (item_name, found_place, keep_place, status) VALUES
  ('검정 우산',     '3층 복도',   '교무실', 'active'),
  ('파란 텀블러',   '체육관',     '분실물보관함', 'active');


-- ═══════════════════════════════════════════════════════════════════
-- 🧹 샘플 삭제 (필요할 때 아래 주석을 풀고 실행)
-- ───────────────────────────────────────────────────────────────────
-- DELETE FROM notices           WHERE author_name IN ('관리자','김수학','이진로','도서관');
-- DELETE FROM schedules         WHERE title IN ('2학기 등록금 납부 마감','동아리 발표회','1학기 기말고사','여름방학식');
-- DELETE FROM timetable_changes WHERE note = '운동장' OR (before_subj='미술' AND after_subj='자율');
-- DELETE FROM ddays             WHERE title IN ('수행평가(과학)','1학기 기말고사','여름방학');
-- DELETE FROM assessments       WHERE title IN ('광합성 단원 수행평가','말하기 수행평가','1학기 기말고사(수학)','1학기 기말고사(국어)');
-- DELETE FROM calls             WHERE student_name IN ('홍길동','이순신');
-- DELETE FROM notices           WHERE title = '독서골든벨 참가 신청';
-- DELETE FROM cleaning_duties    WHERE grade=2 AND class_no=3;
-- DELETE FROM class_locations    WHERE subject IN ('체육','음악');
-- DELETE FROM class_roles        WHERE grade=2 AND class_no=3;
-- DELETE FROM lost_items         WHERE item_name IN ('검정 우산','파란 텀블러');
