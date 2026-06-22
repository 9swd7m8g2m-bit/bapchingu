-- 버그 제보 / 건의 게시판
create table if not exists bug_reports (
  id         bigint generated always as identity primary key,
  author     text,
  text       text not null,
  created_at timestamptz not null default now()
);

alter table bug_reports enable row level security;
drop policy if exists "allow_all" on bug_reports;
create policy "allow_all" on bug_reports for all using (true) with check (true);

alter publication supabase_realtime add table bug_reports;
