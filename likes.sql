-- 엔도가이드 좋아요 (사람별 1표, 중복 방지)
create table if not exists restaurant_likes (
  id         bigint generated always as identity primary key,
  rest_id    bigint references restaurants(id) on delete cascade,
  person     text not null,
  created_at timestamptz not null default now(),
  unique (rest_id, person)
);

alter table restaurant_likes enable row level security;
drop policy if exists "allow_all" on restaurant_likes;
create policy "allow_all" on restaurant_likes for all using (true) with check (true);

alter publication supabase_realtime add table restaurant_likes;
