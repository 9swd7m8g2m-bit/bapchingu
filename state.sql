-- 공유 상태 1행 테이블: 현재 조편성표 / 이번주 상태 / 메모 / 주 시작일
-- (누가 조작하든 모두 같은 화면을 보게 하는 "공유 화이트보드")
create table if not exists app_state (
  id         int primary key default 1,
  week_start date,
  memo       text,
  groups     jsonb,          -- 현재 조편성 [{no, members:[...]}]
  status     jsonb,          -- 이번 주 상태 {이름: 'in'|'leave'|'salad'}
  updated_at timestamptz not null default now(),
  constraint single_row check (id = 1)
);

insert into app_state (id) values (1) on conflict (id) do nothing;

alter table app_state enable row level security;
drop policy if exists "allow_all" on app_state;
create policy "allow_all" on app_state for all using (true) with check (true);

alter publication supabase_realtime add table app_state;
