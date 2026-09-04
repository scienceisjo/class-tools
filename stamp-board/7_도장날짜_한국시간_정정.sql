-- ═══════════════════════════════════════════════════════════════════════════
--  🕘 도장 관찰일(observed_on)을 한국 시간으로 되돌리기
--
--  ▶ 쓰는 법 — 이 파일 전체를 선택해 한 번에 Run 하면 된다. 결과 표가 둘 나온다.
--       ① 날짜를 되돌린 도장이 몇 건인지
--       ② 오늘(한국 시간) 찍힌 도장 목록 — 골든벨이 들어갔는지 여기서 바로 보인다
--
--  ▶ 왜 —
--     앱이 관찰일을 `new Date().toISOString()` 으로 만들고 있었다. 이건 UTC 라서
--     한국 시간 오전 9시 이전에 도장을 찍으면 날짜가 **하루 앞으로 밀린다**.
--     1교시는 8:50 에 시작하고 「수업 여는 골든벨」이 정확히 그 구간에 걸리므로,
--     1교시에 준 도장이 어제 자로 쌓여 「오늘 N개」에도 안 잡히고 날짜별로도 어긋났다.
--     앱은 2026-09-04 에 한국 시간(todayStr)으로 고쳤다. 이 파일은 **그전에 쌓인 기록**을 정리한다.
--
--  ▶ 무엇«만» 고치나 — UTC 버그의 지문이 찍힌 행만 고른다.
--       · 기록된 관찰일이 실제 저장 시각(한국 시간)보다 «정확히 하루» 앞서고
--       · 그 저장 시각이 한국 시간 오전 9시 이전인 것
--     두 조건을 함께 걸어야 «일부러 과거 날짜로 넣은 기록»을 건드리지 않는다.
--     (20반 예시 학생 데이터는 3·6·9일 전으로 넣는다 — 하루 전이 아니라서 걸리지 않는다)
--
--  ▶ 안전 — 도장 «개수»는 하나도 변하지 않는다. 날짜만 제자리로 돌아간다.
--     되돌리고 싶으면 같은 조건에서 observed_on 을 하루 빼면 원래대로 간다.
-- ═══════════════════════════════════════════════════════════════════════════

-- ① 날짜 정정 + 몇 건을 고쳤는지
with fixed as (
  update public.observations o
     set observed_on = (o.created_at at time zone 'Asia/Seoul')::date,
         updated_at  = now()
   where o.voided_at is null
     and o.observed_on = (o.created_at at time zone 'Asia/Seoul')::date - 1
     and (o.created_at at time zone 'Asia/Seoul')::time < time '09:00'
  returning o.id
)
select count(*) as 날짜를_되돌린_도장 from fixed;


-- ② 오늘(한국 시간) 찍힌 도장 — 골든벨이 실제로 들어갔는지 확인
select
  to_char(o.created_at at time zone 'Asia/Seoul', 'HH24:MI')     as 시각,
  o.class_no_snap || '반 ' || o.number_snap || '번'               as 학생,
  o.observed_on                                                   as 관찰일,
  o.category,
  o.lesson_note,
  left(o.behavior, 45)                                            as 행동
from public.observations o
where o.voided_at is null
  and (o.created_at at time zone 'Asia/Seoul')::date
      = (now() at time zone 'Asia/Seoul')::date
order by o.created_at desc;


-- ═══════════════════════════════════════════════════════════════════════════
--  아래는 필요할 때만 따로 돌리는 것들 (전체 Run 에는 영향 없음 — 주석)
-- ═══════════════════════════════════════════════════════════════════════════
--
-- ▷ 되돌리기 — ①을 취소하고 싶을 때 (오늘 되돌린 것만)
-- update public.observations o
--    set observed_on = o.observed_on - 1
--  where o.voided_at is null
--    and o.updated_at::date = current_date
--    and o.observed_on = (o.created_at at time zone 'Asia/Seoul')::date
--    and (o.created_at at time zone 'Asia/Seoul')::time < time '09:00';
--
-- ▷ 아직 어긋난 게 있는지 (①을 돌린 뒤에는 0건이어야 한다)
-- select count(*) as 아직_어긋난_건수
--   from public.observations o
--  where o.voided_at is null
--    and o.observed_on = (o.created_at at time zone 'Asia/Seoul')::date - 1
--    and (o.created_at at time zone 'Asia/Seoul')::time < time '09:00';
--
-- ▷ 날짜별 도장 수 — 정정이 잘 됐는지 눈으로 보기
-- select observed_on, count(*) as 건수
--   from public.observations
--  where voided_at is null
--  group by observed_on order by observed_on desc limit 20;
