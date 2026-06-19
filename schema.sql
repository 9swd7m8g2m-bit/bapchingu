-- ═══════════════════════════════════════════════════════════
-- 밥친구 / 엔도가이드 — Supabase 스키마
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 RUN
-- ═══════════════════════════════════════════════════════════

-- ── 1. 멤버 명단 ──
create table if not exists members (
  id         bigint generated always as identity primary key,
  name       text not null,
  dept       text,
  is_leader  boolean not null default false,  -- 팀장 풀 포함 여부
  active     boolean not null default true,   -- 재직 여부
  lead_count integer not null default 0,      -- 팀장 누적 횟수(공평 로테이션용)
  created_at timestamptz not null default now()
);

-- ── 2. 주간 페어 기록 (3주 연속 회피용 — 최근 2주만 조회) ──
create table if not exists pair_history (
  id         bigint generated always as identity primary key,
  start_date date,
  pairs      jsonb not null default '[]',     -- ["김철수|이영희", ...]
  memo       text,
  created_at timestamptz not null default now()
);

-- ── 3. 엔도가이드 (맛집) ──
create table if not exists restaurants (
  id         bigint generated always as identity primary key,
  name       text not null,
  cat        text,
  price      text,
  walk       integer,
  menu       text,
  rating     integer not null default 0,
  review     text,
  link       text,
  created_at timestamptz not null default now()
);

-- ── 4. 조별 회의실: 식당 후보 ──
create table if not exists team_candidates (
  id         bigint generated always as identity primary key,
  team_no    integer not null,
  rest_id    bigint references restaurants(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- ── 5. 조별 회의실: 감정표현(투표) ──
create table if not exists team_reactions (
  id           bigint generated always as identity primary key,
  candidate_id bigint references team_candidates(id) on delete cascade,
  emoji        text not null,
  person       text not null,
  created_at   timestamptz not null default now(),
  unique (candidate_id, emoji, person)        -- 한 사람당 한 후보-이모지 1표
);

-- ── 6. 조별 회의실: 채팅 ──
create table if not exists team_chat (
  id         bigint generated always as identity primary key,
  team_no    integer not null,
  author     text not null,
  text       text not null,
  created_at timestamptz not null default now()
);

-- ═══════════════════════════════════════════════════════════
-- RLS: 사내 도구라 anon(공개 키)에게 전체 읽기/쓰기 허용
-- (로그인 없이 누구나 조작 = 요구사항. 외부 노출은 아래 주의 참고)
-- ═══════════════════════════════════════════════════════════
alter table members         enable row level security;
alter table pair_history    enable row level security;
alter table restaurants     enable row level security;
alter table team_candidates enable row level security;
alter table team_reactions  enable row level security;
alter table team_chat       enable row level security;

do $$
declare t text;
begin
  foreach t in array array['members','pair_history','restaurants','team_candidates','team_reactions','team_chat']
  loop
    execute format('drop policy if exists "allow_all" on %I;', t);
    execute format('create policy "allow_all" on %I for all using (true) with check (true);', t);
  end loop;
end $$;

-- ── 실시간(채팅·투표 즉시 반영) ──
alter publication supabase_realtime add table team_chat;
alter publication supabase_realtime add table team_reactions;
alter publication supabase_realtime add table team_candidates;

-- ═══════════════════════════════════════════════════════════
-- 시드: 현재 임시 명단 (나중에 멤버 관리 화면/실제 명단으로 교체)
-- ═══════════════════════════════════════════════════════════
insert into members (name, dept, is_leader) values
  ('김지환','생산팀',true),('김병곤','생산팀',false),('김은경','생산팀',false),
  ('양세하','생산팀',false),('최선호','생산팀',false),('박동진','생산팀',false),
  ('서예찬','SW개발팀',true),('곽재범','SW개발팀',true),('서유창','SW개발팀',false),
  ('강은혁','SW개발팀',false),('김승현','SW개발팀',false),('Erkhes','SW개발팀',true),
  ('이현표','기구설계팀',true),('김경한','기구설계팀',false),('권결호','기구설계팀',false),
  ('박상희','기구설계팀',false),('권형식','기구설계팀',false),('이재현','기구설계팀',false),
  ('김나연','기구설계팀',false),
  ('김민나','임상지원팀',true),('홍대희','임상지원팀',true),('배소현','임상지원팀',false),
  ('고영주','임상지원팀',false),('이창준','임상지원팀',false),('서용태','임상지원팀',false),
  ('박지후','품질인허가팀',true),('안병두','품질인허가팀',true),('김유송','품질인허가팀',false),
  ('정지윤','품질인허가팀',false),('탁민경','품질인허가팀',false),('양종근','품질인허가팀',false),
  ('최소웅','경영지원팀',true),('장은진','경영지원팀',true),('김나래','경영지원팀',true),
  ('정승호','경영지원팀',true),('최승목','경영지원팀',false),('임종영','경영지원팀',false),
  ('김지수','경영지원팀',false),('반영조','경영지원팀',false),('윤석현','경영지원팀',false),
  ('강은비','경영지원팀',false),('김은비','경영지원팀',false),('탁민지','경영지원팀',false);
