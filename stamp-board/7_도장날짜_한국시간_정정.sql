-- ═══════════════════════════════════════════════════════════════════════════
--  🕘 도장 관찰일(observed_on)을 한국 시간 기준으로 되돌리기
--
--  왜 —
--    앱이 관찰일을 만들 때 `new Date().toISOString()` 을 썼다. 이건 UTC 라서
--    한국 시간 오전 9시 이전에 도장을 찍으면 날짜가 **하루 앞으로 밀린다**.
--    1교시는 8:50 에 시작하고 「수업 여는 골든벨」은 정확히 그 구간에 걸리므로,
--    1교시에 준 도장이 어제 자로 쌓여 「오늘 N개」에도 안 잡히고
--    날짜별로 훑어봐도 어긋나 보인다.
--    앱은 2026-09-04 에 한국 시간(todayStr)으로 고쳤다. 이 파일은 **그전에 쌓인 기록**을 정리한다.
--
--  쓰는 법 — ①만 먼저 돌려 몇 건인지 보고, 눈으로 확인한 뒤 ②를 돌린다.
--            도장 개수는 하나도 안 변한다(날짜만 바로잡는다).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── ① 진단: 기록된 관찰일과 실제로 찍은 한국 시간 날짜가 다른 건 ──────────
select
  o.id,
  o.observed_on                                   as 기록된_날짜,
  (o.created_at at time zone 'Asia/Seoul')::date  as 실제_한국날짜,
  to_char(o.created_at at time zone 'Asia/Seoul', 'HH24:MI') as 찍은시각_KST,
  o.class_no_snap || '-' || o.number_snap         as 반번호,
  left(o.behavior, 40)                            as 행동
from public.observations o
where o.voided_at is null
  and o.observed_on <> (o.created_at at time zone 'Asia/Seoul')::date
order by o.created_at desc;

-- 요약 — 며칠 치가 밀렸는지 한눈에
select
  (o.created_at at time zone 'Asia/Seoul')::date as 실제_한국날짜,
  o.observed_on                                  as 기록된_날짜,
  count(*)                                       as 건수
from public.observations o
where o.voided_at is null
  and o.observed_on <> (o.created_at at time zone 'Asia/Seoul')::date
group by 1, 2
order by 1 desc;


-- ── ② 정정: 관찰일을 실제 한국 시간 날짜로 되돌린다 ───────────────────────
--    ①에서 나온 건수와 아래 UPDATE 가 알려주는 건수가 같아야 한다.
--    ※ 주석을 풀고 실행하세요.
--
-- update public.observations o
--    set observed_on = (o.created_at at time zone 'Asia/Seoul')::date,
--        updated_at  = now()
--  where o.voided_at is null
--    and o.observed_on <> (o.created_at at time zone 'Asia/Seoul')::date;


-- ── ③ 확인: 정정 뒤에는 ①이 0건이어야 한다 ───────────────────────────────
select count(*) as 아직_어긋난_건수
from public.observations o
where o.voided_at is null
  and o.observed_on <> (o.created_at at time zone 'Asia/Seoul')::date;


-- ── ④ 참고: 오늘(한국 시간) 찍힌 도장 — 골든벨이 잘 들어갔는지 바로 보기 ──
select
  to_char(o.created_at at time zone 'Asia/Seoul', 'HH24:MI') as 시각,
  o.class_no_snap || '반 ' || o.number_snap || '번'          as 학생,
  o.category,
  o.lesson_note,
  left(o.behavior, 45)                                       as 행동
from public.observations o
where o.voided_at is null
  and (o.created_at at time zone 'Asia/Seoul')::date
      = (now() at time zone 'Asia/Seoul')::date
order by o.created_at desc;
