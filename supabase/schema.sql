-- Nigel Thomas Private Accounting Dashboard V1
-- Run this in Supabase SQL Editor.
-- This schema is designed for one private user initially, but uses user_id
-- and Row Level Security so it can be expanded safely.

create extension if not exists pgcrypto;

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  account_key text not null,
  account_name text not null,
  account_type text not null default 'asset',
  opening_balance numeric(14,2) not null default 0 check (opening_balance >= 0),
  current_balance numeric(14,2) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, account_key)
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_name text not null,
  category_type text not null check (category_type in ('expense','income','transfer')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(user_id, category_name, category_type)
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid not null references public.accounts(id) on delete restrict,
  to_account_id uuid references public.accounts(id) on delete restrict,
  transaction_type text not null check (transaction_type in ('expense','income','transfer')),
  amount numeric(14,2) not null check (amount > 0),
  category text not null,
  description text,
  transaction_date timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (transaction_type = 'transfer' and to_account_id is not null and account_id <> to_account_id)
    or
    (transaction_type <> 'transfer' and to_account_id is null)
  )
);

create index if not exists transactions_user_date_idx
  on public.transactions(user_id, transaction_date desc);

create index if not exists transactions_user_type_idx
  on public.transactions(user_id, transaction_type);

create index if not exists accounts_user_idx
  on public.accounts(user_id);

alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;

drop policy if exists "accounts_owner_select" on public.accounts;
create policy "accounts_owner_select" on public.accounts
for select using (auth.uid() = user_id);

drop policy if exists "accounts_owner_insert" on public.accounts;
create policy "accounts_owner_insert" on public.accounts
for insert with check (auth.uid() = user_id);

drop policy if exists "accounts_owner_update" on public.accounts;
create policy "accounts_owner_update" on public.accounts
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "accounts_owner_delete" on public.accounts;
create policy "accounts_owner_delete" on public.accounts
for delete using (auth.uid() = user_id);

drop policy if exists "categories_owner_all" on public.categories;
create policy "categories_owner_all" on public.categories
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "transactions_owner_all" on public.transactions;
create policy "transactions_owner_all" on public.transactions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Default categories are inserted per user after signup.
-- Default accounts should also be inserted only for the authenticated user.
-- For production, use an authenticated setup page or a secure server-side
-- initialization function rather than putting a user ID in frontend code.
