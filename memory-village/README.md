# 🏡 우리 반 추억 마을

학기말 회고·다짐을 담는 학급 추억 공간. 학생이 자기 캐릭터(이모지 약 90종 중 선택)로 마을을 돌아다니며 다짐·명장면·행사·응원·1인1역을 남기고, 친구 마음에 ❤️ 공감하는 갤러리 워크형 웹앱입니다.

- **바로 열기:** https://scienceisjo.github.io/class-tools/memory-village/
- **반 구분:** 링크 끝에 `?room=2-3` 처럼 방 코드를 붙이면 반별로 분리됩니다. 앱 메뉴의 "학생 참여 링크 복사" 사용.

## 다섯 공간 × 일곱 카테고리
- 🌳 다짐 나무 — 🍎 나의 다짐 / 🌸 우리 반의 모습
- ⭐ 별빛 갤러리 — 기억에 남는 순간
- 🎪 추억 광장 — 기억에 남는 행사
- 📮 마음 우체국 — 친구에게 한마디
- 🌱 도전 온실 — 🌱 도전하고 싶은 것 / 🤝 우리 반 1인1역

## 특징
- **익명 없음** — 모든 마음은 입장 때 정한 캐릭터·별명으로 기록돼요.
- **교사 대시보드** — 앱 메뉴(⋯) → 교사 대시보드에서 부적절한 답변을 검색·삭제할 수 있어요. (비밀번호 잠금은 아직 없음)

## 온라인 실시간(Supabase) 설정
`index.html` 상단에 과학이조선생 프로젝트(`vbvtnmnodeoocbbjauap`)의 URL/anon key가 이미 들어 있습니다.
처음 한 번 아래 SQL을 **Supabase 대시보드 → SQL Editor**에 붙여넣고 Run 하세요. (모두 idempotent — 다시 실행해도 안전)

```sql
-- 테이블 + likes + avatar 컬럼
create table if not exists public.dajim_entries (
  id text primary key,
  room text not null default 'default',
  category text not null,
  author text,
  content text not null,
  x double precision not null,
  y double precision not null,
  created_at timestamptz not null default now()
);
alter table public.dajim_entries add column if not exists likes integer not null default 0;
alter table public.dajim_entries add column if not exists avatar text;
create index if not exists dajim_entries_room_idx on public.dajim_entries (room, created_at);

-- RLS + 익명 접근
alter table public.dajim_entries enable row level security;
drop policy if exists "read"   on public.dajim_entries;
drop policy if exists "insert" on public.dajim_entries;
drop policy if exists "update" on public.dajim_entries;
drop policy if exists "delete" on public.dajim_entries;
create policy "read"   on public.dajim_entries for select using (true);
create policy "insert" on public.dajim_entries for insert with check (true);
create policy "update" on public.dajim_entries for update using (true) with check (true);
create policy "delete" on public.dajim_entries for delete using (true);

-- 공감(❤️) 원자적 증가 함수
create or replace function public.dajim_like(entry_id text)
returns integer language sql security definer set search_path = public as $$
  update public.dajim_entries set likes = likes + 1 where id = entry_id returning likes;
$$;
grant execute on function public.dajim_like(text) to anon;

-- 실시간 켜기
do $$ begin
  alter publication supabase_realtime add table public.dajim_entries;
exception when duplicate_object then null; end $$;
```

> 미설정(오프라인) 상태로 열어도 이 기기에만 저장되는 방식으로 작동합니다.
> 학생 사진은 수 KB로 압축되어 저장되며, 익명으로 남기면 사진·이름 모두 숨겨집니다.
