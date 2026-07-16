-- ════════════════════════════════════════════════════════════════════
--  롤링페이퍼 · Supabase 준비 SQL   (딱 한 번만 실행하면 됩니다)
--  실행 위치: Supabase 대시보드 → 왼쪽 메뉴 SQL Editor → 붙여넣고 [Run]
--  대상: '과학이조선생' 프로젝트 (앱 CONFIG에 연결돼 있는 그 프로젝트)
-- ════════════════════════════════════════════════════════════════════

-- 1) 메시지를 담을 표 만들기
create table if not exists public.farewell_messages (
  id          text primary key,
  room        text not null default 'dahyun',   -- 반 구분용(?room= 로 바뀜)
  author      text,                             -- 이름/별명(없어도 됨)
  content     text not null,                    -- 편지 내용
  color       text,                             -- 쪽지 색
  sticker     text,                             -- 스티커
  video_url   text,                             -- (미사용, 예비 칸)
  created_at  timestamptz not null default now()
);
create index if not exists farewell_room_idx on public.farewell_messages (room, created_at);

-- 2) 행 보안(RLS): 링크 아는 사람은 '읽기 + 쓰기'만 가능. 삭제는 막음(학생 장난 방지).
--    선생님이 메시지를 지울 일이 있으면 Supabase 대시보드 Table editor에서 하면 됩니다.
alter table public.farewell_messages enable row level security;
drop policy if exists "fw_read"   on public.farewell_messages;
drop policy if exists "fw_insert" on public.farewell_messages;
drop policy if exists "fw_delete" on public.farewell_messages;   -- 예전에 만들었다면 제거
create policy "fw_read"   on public.farewell_messages for select using (true);
create policy "fw_insert" on public.farewell_messages for insert with check (true);

-- 3) 실시간(Realtime) 켜기 — 새 편지가 전시 화면에 바로 뜨게. (여러 번 실행해도 오류 안 남)
do $$
begin
  alter publication supabase_realtime add table public.farewell_messages;
exception when duplicate_object then null;
end $$;

-- ════════════════════════════════════════════════════════════════════
--  끝! 이제 전시 화면(?mode=board)의 노란 안내 배너가 사라지고,
--  학생이 작성한 편지가 실시간으로 모입니다.
-- ════════════════════════════════════════════════════════════════════
