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
-- 시드: EndoRobotics 조직도 기준 (2026-06-22) — 팀장 직책 = is_leader
-- ═══════════════════════════════════════════════════════════
insert into members (name, dept, is_leader) values
  ('김경남','기업부설연구소',false),('권태빈','CSO',false),
  ('김병곤','CEO',false),('홍대희','CEO',false),('기성찬','경영관리본부',false),
  ('서예찬','설계1팀',true),('권경호','설계1팀',false),('김원석','설계1팀',false),('유재형','설계1팀',false),
  ('Erkhes','설계2팀',true),('반영조','설계2팀',false),('이동재','설계2팀',false),('정승연','설계2팀',false),
  ('민병두','설계3팀',true),('김준혁','설계3팀',false),('서용태','설계3팀',false),('한지윤','설계3팀',false),
  ('권성일','선행기술팀',true),
  ('김정한','임베디드1팀',true),('안현석','임베디드1팀',false),('양새하','임베디드1팀',false),
  ('엄중영','임베디드1팀',false),('운석현','임베디드1팀',false),('황용현','임베디드1팀',false),
  ('최수용','임베디드2팀',true),
  ('양종근','IP팀',true),
  ('강덕원','생산팀',false),('김승현','생산팀',false),('김지섭','생산팀',false),
  ('방정혁','생산팀',false),('방진형','생산팀',false),('유지용','생산팀',false),
  ('설세민','생산기술팀',true),('고영우','생산기술팀',false),('김지수','생산기술팀',false),
  ('이창준','생산기술팀',false),('조준희','생산기술팀',false),
  ('박준영','생산관리팀',true),('박상명','생산관리팀',false),
  ('이원재','생산관리본부',false),
  ('이제현','생산품질팀',false),('최승현','생산품질팀',false),
  ('김지환','인허가팀',true),('권용식','인허가팀',false),('김나연','인허가팀',false),
  ('김유송','인허가팀',false),('박상희','인허가팀',false),('배소현','인허가팀',false),
  ('김은정','SCM팀',true),
  ('김지민','인사총무팀',true),('강예송','인사총무팀',false),('권민경','인사총무팀',false),
  ('김용진','인사총무팀',false),('김지현','인사총무팀',false),
  ('김한나','마케팅팀',true),
  ('장은진','세일즈팀',true),
  ('허진주','영업지원팀',true),
  ('박동진','전략기획팀',false),('이은상','전략기획팀',false),('최지영','전략기획팀',false),('탁민정','전략기획팀',false),
  ('도훈기','회계팀',true),('서유정','회계팀',false),
  ('김상현','기업부설연구소',false);
