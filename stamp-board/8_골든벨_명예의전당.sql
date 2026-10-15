-- ############################################################################
-- 🏆 골든벨 명예의 전당 — 반별 골든벨 기록 (2026-10-16)
--
-- Supabase → SQL Editor 에 통째로 붙여 넣고 Run 한 번. 여러 번 돌려도 안전합니다.
--
-- · 한 줄 = 골든벨 한 판(반·날짜·문제 수·참가 인원·끝까지 남은 수·부활·문제별 탈락)
-- · 학생 이름·번호는 담지 않습니다 — 명예의 전당은 «반 전체 기록»만 보여 줍니다.
-- · 선생님 본인 기록만 읽고 씁니다(다른 선생님 기록과 섞이지 않음).
-- · 이 SQL 을 돌리기 전에도 골든벨은 그대로 됩니다 — 기록은 그 기기에 쌓여 있다가
--   표가 생긴 뒤 명예의 전당을 열면 한꺼번에 서버로 올라갑니다.
-- ############################################################################

create table if not exists public.gb_games (
  owner        uuid        not null default auth.uid(),
  gid          text        not null,                 -- 앱이 만든 판 번호
  school_year  int         not null,
  semester     int         not null,
  grade        int         not null,
  cls          int         not null,
  played_on    date        not null,
  total        int         not null,                 -- 문제 수
  players      int         not null,                 -- 참가 인원(오늘 안 함 제외)
  survivors    int         not null,                 -- 끝까지 남은 수(부활 포함)
  revived      int         not null default 0,       -- 그중 부활해서 남은 수
  rounds       jsonb       not null default '[]',    -- 문제별 탈락 인원
  qids         jsonb       not null default '[]',    -- 낸 문제 id(문제은행)
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  primary key (owner, gid),
  constraint gb_games_counts check (players >= 0 and survivors >= 0 and revived >= 0 and total > 0)
);
create index if not exists idx_gb_games_term on public.gb_games(owner, school_year, semester, grade, cls);

alter table public.gb_games enable row level security;

drop policy if exists "gb_games_teacher_own" on public.gb_games;
create policy "gb_games_teacher_own" on public.gb_games
  for all to authenticated
  using (public.is_teacher() and owner = auth.uid())
  with check (public.is_teacher() and owner = auth.uid());

-- 2026-10-30 부터 새 표에는 권한이 저절로 붙지 않습니다 — 직접 줍니다(RLS 가 실제로 막음)
grant usage on schema public to authenticated, service_role;
grant select, insert, update, delete on public.gb_games to authenticated, service_role;
revoke all on public.gb_games from anon;

-- 확인: 아래가 0 이면 끝(표는 비어 있는 게 정상)
select count(*) as gb_games_rows from public.gb_games;
