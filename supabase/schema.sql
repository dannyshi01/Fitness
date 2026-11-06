-- 健身菜單庫 Supabase schema
-- 在 Supabase 後台 SQL Editor 貼上整份後按 Run。可重複執行(idempotent)。

-- ============ 資料表 ============

create table if not exists public.exercises (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null,
  cats        text[] not null default '{}',   -- 肌群:胸/背/肩/手臂/腿/臀/核心/全身
  tags        text[] not null default '{}',   -- 特色標籤:爆發跳躍/腳踝穩定/…
  equip       text not null default '',
  source      text not null default '',
  source_url  text not null default '',       -- IG / YouTube 連結
  video_url   text not null default '',       -- 自己託管的影片網址(預留,之後可指向 R2)
  image_path  text not null default '',       -- Storage 內路徑,不存 base64
  notes       text not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.menus (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null,
  notes       text not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.menu_items (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  menu_id      uuid not null references public.menus(id) on delete cascade,
  exercise_id  uuid not null references public.exercises(id) on delete cascade,
  sets         text not null default '',
  reps         text not null default '',
  position     int  not null default 0
);

create index if not exists exercises_user_idx   on public.exercises(user_id);
create index if not exists menus_user_idx       on public.menus(user_id);
create index if not exists menu_items_menu_idx  on public.menu_items(menu_id, position);

-- ============ 權限(RLS):只有本人讀寫自己的資料 ============

alter table public.exercises  enable row level security;
alter table public.menus      enable row level security;
alter table public.menu_items enable row level security;

drop policy if exists "own exercises"  on public.exercises;
drop policy if exists "own menus"      on public.menus;
drop policy if exists "own menu_items" on public.menu_items;

create policy "own exercises"  on public.exercises
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own menus" on public.menus
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own menu_items" on public.menu_items
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- 只開放給登入者;未登入(anon)完全不能碰
grant select, insert, update, delete on public.exercises, public.menus, public.menu_items to authenticated;
revoke all on public.exercises, public.menus, public.menu_items from anon;

-- ============ 圖片儲存 ============
-- 私有 bucket;檔案放在「<user_id>/檔名」底下,只有本人能讀寫

insert into storage.buckets (id, name, public)
values ('exercise-images', 'exercise-images', false)
on conflict (id) do nothing;

drop policy if exists "own images read"   on storage.objects;
drop policy if exists "own images write"  on storage.objects;
drop policy if exists "own images update" on storage.objects;
drop policy if exists "own images delete" on storage.objects;

create policy "own images read" on storage.objects
  for select to authenticated
  using (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "own images write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "own images update" on storage.objects
  for update to authenticated
  using (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "own images delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'exercise-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
