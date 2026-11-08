-- پیش‌نویس، اجرا و آزمایش نشده. برای Supabase (PostgreSQL).
create table profiles(id uuid primary key references auth.users, full_name text, referral_code text unique, referred_by uuid references profiles(id), created_at timestamptz default now());
create table chapters(n int primary key, title text not null, is_free boolean not null default false, price_toman bigint);
create table orders(id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), kind text not null check (kind in ('chapter','bundle_3_8')), chapter_n int references chapters(n),
  amount_paid_toman bigint not null, gateway text, gateway_ref text unique, status text not null default 'pending' check (status in ('pending','paid','failed','refunded')), created_at timestamptz default now(), paid_at timestamptz);
create table entitlements(user_id uuid references profiles(id), chapter_n int references chapters(n), order_id uuid references orders(id), granted_at timestamptz default now(), primary key(user_id,chapter_n));  -- دائمی؛ بدون تاریخ انقضا
create table commissions(id uuid primary key default gen_random_uuid(), order_id uuid not null unique references orders(id), affiliate_id uuid not null references profiles(id), rate numeric not null, base_toman bigint not null, amount_toman bigint not null,
  status text not null default 'wallet' check (status in ('wallet','transfer_requested','paid_out','needs_review','reversed')));
create table wallet_ledger(id uuid primary key default gen_random_uuid(), affiliate_id uuid not null references profiles(id), commission_id uuid references commissions(id), delta_toman bigint not null, idempotency_key text not null unique, note text, created_at timestamptz default now());
create table payouts(id uuid primary key default gen_random_uuid(), commission_id uuid not null references commissions(id), idempotency_key text not null unique, status text not null, provider_ref text, error text, created_at timestamptz default now());
create table settings(key text primary key, value text);  -- مثلاً commission_rate = 0.20
-- RLS: کاربر فقط ردیف‌های خودش را بخواند؛ نوشتن در orders/entitlements/commissions/wallet فقط با service role (Edge Function).
alter table entitlements enable row level security;
create policy own_entitlements on entitlements for select using (auth.uid()=user_id);
