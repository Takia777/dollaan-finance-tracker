-- =====================================================================
-- Dollaan · Supabase schema (v1.0)
-- Jalankan sekali di Supabase Dashboard → SQL Editor → New query → Run.
-- =====================================================================

-- ---------- PROFILES ----------------------------------------------------
create table if not exists public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  full_name      text,
  nickname       text,
  email          text,
  language       text not null default 'en',
  currency       text not null default 'IDR',
  monthly_budget numeric not null default 0,
  daily_reminder boolean not null default true,
  setup_done     boolean not null default false,
  created_at     timestamptz not null default now()
);

-- Buat baris profil otomatis setiap ada user baru mendaftar.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- WALLETS -----------------------------------------------------
create table if not exists public.wallets (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name            text not null,
  type            text not null default 'wallet' check (type in ('bank', 'emoney', 'etoll', 'wallet')),
  color           text not null default 'unguTua',
  logo_url        text,
  last4           text not null default '',
  is_main         boolean not null default false,
  initial_balance numeric not null default 0,
  created_at      timestamptz not null default now()
);

-- ---------- GOALS -------------------------------------------------------
create table if not exists public.goals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name        text not null,
  image_url   text,
  target      numeric not null check (target > 0),
  target_date date,
  status      text not null default 'active' check (status in ('active', 'reached', 'packed')),
  auto_save   boolean not null default false,
  created_at  timestamptz not null default now(),
  packed_at   timestamptz
);

-- ---------- TRANSACTIONS ------------------------------------------------
-- kind: topup (pemasukan), expense (pengeluaran), transfer (antar wallet),
--       goal (setor ke saving goal; saldo wallet berkurang).
create table if not exists public.transactions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  wallet_id    uuid not null references public.wallets (id) on delete cascade,
  kind         text not null check (kind in ('topup', 'expense', 'transfer', 'goal')),
  amount       numeric not null check (amount > 0),
  category     text,
  note         text,
  occurred_at  timestamptz not null default now(),
  to_wallet_id uuid references public.wallets (id) on delete cascade,
  goal_id      uuid references public.goals (id) on delete cascade,
  created_at   timestamptz not null default now()
);

create index if not exists transactions_user_time_idx on public.transactions (user_id, occurred_at desc);

-- ---------- CHAT MESSAGES ----------------------------------------------
create table if not exists public.chat_messages (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  role       text not null check (role in ('user', 'bot')),
  content    text not null,
  understood boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------- ROW LEVEL SECURITY -----------------------------------------
-- Setiap pengguna hanya bisa membaca & mengubah datanya sendiri.
alter table public.profiles      enable row level security;
alter table public.wallets       enable row level security;
alter table public.goals         enable row level security;
alter table public.transactions  enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "own wallets" on public.wallets;
create policy "own wallets" on public.wallets
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own goals" on public.goals;
create policy "own goals" on public.goals
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own transactions" on public.transactions;
create policy "own transactions" on public.transactions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own chat" on public.chat_messages;
create policy "own chat" on public.chat_messages
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- STORAGE (foto goal & logo kartu) ---------------------------
insert into storage.buckets (id, name, public)
values ('dollaan-images', 'dollaan-images', true)
on conflict (id) do nothing;

-- File disimpan di folder <user_id>/..., hanya pemiliknya yang boleh upload/hapus.
drop policy if exists "upload own images" on storage.objects;
create policy "upload own images" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'dollaan-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "update own images" on storage.objects;
create policy "update own images" on storage.objects
  for update to authenticated
  using (bucket_id = 'dollaan-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "delete own images" on storage.objects;
create policy "delete own images" on storage.objects
  for delete to authenticated
  using (bucket_id = 'dollaan-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "read images" on storage.objects;
create policy "read images" on storage.objects
  for select using (bucket_id = 'dollaan-images');
