-- KostHunt production baseline schema.
-- Managed by Supabase CLI. Do not paste secrets into Flutter or SQL files.

create extension if not exists pgcrypto;

create table if not exists public.app_users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  full_name text not null,
  email text,
  phone text not null,
  role text not null check (role in ('customer', 'owner', 'admin')),
  status text not null default 'active' check (status in ('active', 'suspended', 'deleted')),
  trust_level integer not null default 0 check (trust_level >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.owner_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.app_users(id) on delete cascade,
  display_name text not null,
  phone text not null,
  bank_name text,
  bank_account_number text,
  bank_account_holder text,
  is_verified_owner boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.kosts (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.app_users(id) on delete restrict,
  title text not null,
  slug text unique,
  description text not null default '',
  address text not null,
  city text not null,
  area text,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  type text not null default 'kost' check (type in ('kost', 'kontrakan')),
  gender_policy text not null default 'mixed' check (gender_policy in ('male', 'female', 'mixed')),
  status text not null default 'published' check (status in ('published', 'paused', 'suspended', 'deleted')),
  min_price integer not null default 0 check (min_price >= 0),
  campus_distance_km numeric(8, 2) not null default 0 check (campus_distance_km >= 0),
  is_premium boolean not null default false,
  premium_until timestamptz,
  ad_credits integer not null default 0 check (ad_credits >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.kost_photos (
  id uuid primary key default gen_random_uuid(),
  kost_id uuid not null references public.kosts(id) on delete cascade,
  storage_path text not null,
  public_url text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.kost_facilities (
  id uuid primary key default gen_random_uuid(),
  kost_id uuid not null references public.kosts(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (kost_id, name)
);

create table if not exists public.kost_rules (
  id uuid primary key default gen_random_uuid(),
  kost_id uuid not null references public.kosts(id) on delete cascade,
  rule text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.kost_units (
  id uuid primary key default gen_random_uuid(),
  kost_id uuid not null references public.kosts(id) on delete cascade,
  name text not null,
  monthly_price integer not null check (monthly_price >= 0),
  deposit_amount integer not null default 0 check (deposit_amount >= 0),
  status text not null default 'available' check (status in ('available', 'occupied', 'maintenance', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid not null references public.app_users(id) on delete cascade,
  kost_id uuid not null references public.kosts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, kost_id)
);

create table if not exists public.listing_promotions (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.app_users(id) on delete restrict,
  kost_id uuid not null references public.kosts(id) on delete cascade,
  package_name text not null,
  amount integer not null check (amount >= 0),
  status text not null default 'active' check (status in ('pending_payment', 'active', 'expired', 'cancelled')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  ad_credits integer not null default 0 check (ad_credits >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_user_id uuid not null references public.app_users(id) on delete restrict,
  owner_user_id uuid not null references public.app_users(id) on delete restrict,
  kost_id uuid not null references public.kosts(id) on delete restrict,
  unit_id uuid not null references public.kost_units(id) on delete restrict,
  start_date date,
  duration_months integer not null default 1 check (duration_months > 0),
  rent_amount integer not null check (rent_amount >= 0),
  status text not null default 'pending_payment' check (
    status in ('draft', 'pending_payment', 'paid', 'confirmed', 'checked_in', 'completed', 'cancelled', 'refunded', 'disputed')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete restrict,
  customer_user_id uuid not null references public.app_users(id) on delete restrict,
  owner_user_id uuid not null references public.app_users(id) on delete restrict,
  kost_id uuid not null references public.kosts(id) on delete restrict,
  amount integer not null check (amount >= 0),
  platform_fee integer not null default 0 check (platform_fee >= 0),
  owner_amount integer not null check (owner_amount >= 0),
  currency text not null default 'IDR',
  gateway text not null default 'duitku' check (gateway in ('duitku')),
  merchant_order_id text not null unique,
  duitku_reference text unique,
  payment_method text,
  status text not null default 'pending' check (
    status in ('pending', 'waiting_payment', 'paid', 'failed', 'expired', 'cancelled', 'refunded', 'partially_refunded')
  ),
  payment_url text,
  raw_callback jsonb,
  expired_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid references public.payments(id) on delete set null,
  merchant_order_id text,
  duitku_reference text,
  event_type text not null,
  signature_valid boolean not null default false,
  amount_match boolean not null default false,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.owner_balances (
  owner_user_id uuid primary key references public.app_users(id) on delete cascade,
  pending_amount integer not null default 0 check (pending_amount >= 0),
  available_amount integer not null default 0 check (available_amount >= 0),
  paid_out_amount integer not null default 0 check (paid_out_amount >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.app_users(id) on delete restrict,
  amount integer not null check (amount > 0),
  status text not null default 'requested' check (status in ('requested', 'approved', 'paid', 'rejected', 'cancelled')),
  bank_snapshot jsonb not null default '{}'::jsonb,
  admin_note text,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.refunds (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete restrict,
  payment_id uuid not null references public.payments(id) on delete restrict,
  amount integer not null check (amount > 0),
  reason text not null,
  status text not null default 'requested' check (status in ('requested', 'approved', 'processed', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  kost_id uuid references public.kosts(id) on delete set null,
  created_by uuid not null references public.app_users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.app_users(id) on delete cascade,
  role text not null check (role in ('customer', 'owner', 'admin')),
  created_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_user_id uuid not null references public.app_users(id) on delete restrict,
  body text not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.message_reads (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.app_users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create table if not exists public.support_threads (
  id uuid primary key default gen_random_uuid(),
  customer_user_id uuid not null references public.app_users(id) on delete restrict,
  booking_id uuid references public.bookings(id) on delete set null,
  payment_id uuid references public.payments(id) on delete set null,
  status text not null default 'open' check (status in ('open', 'pending', 'resolved', 'closed')),
  subject text not null default 'Customer Service',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.support_threads(id) on delete cascade,
  sender_user_id uuid not null references public.app_users(id) on delete restrict,
  body text not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references public.app_users(id) on delete cascade,
  actor_user_id uuid references public.app_users(id) on delete set null,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.app_users(id) on delete cascade,
  push_enabled boolean not null default true,
  booking_enabled boolean not null default true,
  chat_enabled boolean not null default true,
  support_enabled boolean not null default true,
  payment_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_users(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  customer_user_id uuid not null references public.app_users(id) on delete restrict,
  kost_id uuid not null references public.kosts(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  body text,
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references public.app_users(id) on delete restrict,
  target_type text not null check (target_type in ('kost', 'user', 'conversation', 'message', 'booking')),
  target_id uuid not null,
  reason text not null,
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.app_users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'kost-photos',
  'kost-photos',
  true,
  20971520,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'owner-documents',
  'owner-documents',
  false,
  20971520,
  array['image/jpeg', 'image/png', 'application/pdf']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.current_app_user_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.app_users where auth_user_id = auth.uid()
$$;

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.app_users where auth_user_id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_app_role() = 'admin', false)
$$;

create or replace function public.increment_owner_pending_balance(
  p_owner_user_id uuid,
  p_amount integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_amount <= 0 then
    raise exception 'amount must be positive';
  end if;

  insert into public.owner_balances (owner_user_id, pending_amount)
  values (p_owner_user_id, p_amount)
  on conflict (owner_user_id) do update
  set pending_amount = public.owner_balances.pending_amount + excluded.pending_amount,
      updated_at = now();
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'app_users', 'owner_profiles', 'kosts', 'kost_photos', 'kost_facilities',
    'kost_rules', 'kost_units', 'favorites', 'listing_promotions', 'bookings', 'payments',
    'payment_events', 'owner_balances', 'payouts', 'refunds', 'conversations',
    'conversation_participants', 'messages', 'message_reads', 'support_threads',
    'support_messages', 'notifications', 'notification_preferences', 'user_devices',
    'reviews', 'reports', 'audit_logs'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end $$;

create index if not exists idx_app_users_auth_user_id on public.app_users(auth_user_id);
create index if not exists idx_kosts_owner_status on public.kosts(owner_user_id, status);
create index if not exists idx_listing_promotions_owner on public.listing_promotions(owner_user_id, status);
create index if not exists idx_listing_promotions_kost on public.listing_promotions(kost_id, status);
create index if not exists idx_bookings_customer on public.bookings(customer_user_id);
create index if not exists idx_bookings_owner on public.bookings(owner_user_id);
create index if not exists idx_payments_booking on public.payments(booking_id);
create index if not exists idx_payment_events_order on public.payment_events(merchant_order_id);
create index if not exists idx_messages_conversation_created on public.messages(conversation_id, created_at);
create index if not exists idx_notifications_recipient_created on public.notifications(recipient_user_id, created_at desc);

create trigger set_app_users_updated_at before update on public.app_users
for each row execute function public.set_updated_at();
create trigger set_owner_profiles_updated_at before update on public.owner_profiles
for each row execute function public.set_updated_at();
create trigger set_kosts_updated_at before update on public.kosts
for each row execute function public.set_updated_at();
create trigger set_kost_units_updated_at before update on public.kost_units
for each row execute function public.set_updated_at();
create trigger set_listing_promotions_updated_at before update on public.listing_promotions
for each row execute function public.set_updated_at();
create trigger set_bookings_updated_at before update on public.bookings
for each row execute function public.set_updated_at();
create trigger set_payments_updated_at before update on public.payments
for each row execute function public.set_updated_at();
create trigger set_payouts_updated_at before update on public.payouts
for each row execute function public.set_updated_at();
create trigger set_refunds_updated_at before update on public.refunds
for each row execute function public.set_updated_at();
create trigger set_conversations_updated_at before update on public.conversations
for each row execute function public.set_updated_at();
create trigger set_support_threads_updated_at before update on public.support_threads
for each row execute function public.set_updated_at();
create trigger set_reports_updated_at before update on public.reports
for each row execute function public.set_updated_at();

create policy app_users_select_own_or_admin on public.app_users
for select to authenticated
using (id = public.current_app_user_id() or public.is_admin());

create policy app_users_insert_own_customer_or_owner on public.app_users
for insert to authenticated
with check (
  auth_user_id = auth.uid()
  and role in ('customer', 'owner')
);

create policy app_users_update_own_or_admin on public.app_users
for update to authenticated
using (id = public.current_app_user_id() or public.is_admin())
with check (id = public.current_app_user_id() or public.is_admin());

create policy owner_profiles_select_owner_or_admin on public.owner_profiles
for select to authenticated
using (user_id = public.current_app_user_id() or public.is_admin());

create policy owner_profiles_insert_owner on public.owner_profiles
for insert to authenticated
with check (user_id = public.current_app_user_id() and public.current_app_role() = 'owner');

create policy owner_profiles_update_owner on public.owner_profiles
for update to authenticated
using (user_id = public.current_app_user_id() or public.is_admin())
with check (user_id = public.current_app_user_id() or public.is_admin());

create policy kosts_public_read_published on public.kosts
for select to anon, authenticated
using (status = 'published');

create policy kosts_owner_read_all_own on public.kosts
for select to authenticated
using (owner_user_id = public.current_app_user_id() or public.is_admin());

create policy kosts_owner_insert on public.kosts
for insert to authenticated
with check (owner_user_id = public.current_app_user_id() and public.current_app_role() = 'owner');

create policy kosts_owner_update_own on public.kosts
for update to authenticated
using (owner_user_id = public.current_app_user_id() or public.is_admin())
with check (owner_user_id = public.current_app_user_id() or public.is_admin());

create policy kost_children_public_read_published on public.kost_photos
for select to anon, authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and k.status = 'published'));

create policy kost_facilities_public_read_published on public.kost_facilities
for select to anon, authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and k.status = 'published'));

create policy kost_rules_public_read_published on public.kost_rules
for select to anon, authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and k.status = 'published'));

create policy kost_units_public_read_published on public.kost_units
for select to anon, authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and k.status = 'published'));

create policy kost_photos_owner_manage on public.kost_photos
for all to authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())))
with check (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())));

create policy kost_facilities_owner_manage on public.kost_facilities
for all to authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())))
with check (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())));

create policy kost_rules_owner_manage on public.kost_rules
for all to authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())))
with check (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())));

create policy kost_units_owner_manage on public.kost_units
for all to authenticated
using (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())))
with check (exists (select 1 from public.kosts k where k.id = kost_id and (k.owner_user_id = public.current_app_user_id() or public.is_admin())));

create policy favorites_manage_own on public.favorites
for all to authenticated
using (user_id = public.current_app_user_id())
with check (user_id = public.current_app_user_id());

create policy listing_promotions_owner_admin_read on public.listing_promotions
for select to authenticated
using (owner_user_id = public.current_app_user_id() or public.is_admin());

create policy listing_promotions_owner_insert on public.listing_promotions
for insert to authenticated
with check (
  owner_user_id = public.current_app_user_id()
  and exists (
    select 1 from public.kosts k
    where k.id = kost_id and k.owner_user_id = public.current_app_user_id()
  )
);

create policy listing_promotions_admin_update on public.listing_promotions
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy bookings_customer_owner_admin_read on public.bookings
for select to authenticated
using (
  customer_user_id = public.current_app_user_id()
  or owner_user_id = public.current_app_user_id()
  or public.is_admin()
);

create policy bookings_customer_insert_own on public.bookings
for insert to authenticated
with check (
  customer_user_id = public.current_app_user_id()
  and exists (
    select 1 from public.kosts k
    join public.kost_units u on u.kost_id = k.id
    where k.id = kost_id
      and u.id = unit_id
      and k.owner_user_id = owner_user_id
      and k.status = 'published'
      and u.status = 'available'
  )
);

create policy payments_related_read on public.payments
for select to authenticated
using (
  customer_user_id = public.current_app_user_id()
  or owner_user_id = public.current_app_user_id()
  or public.is_admin()
);

create policy owner_balances_owner_admin_read on public.owner_balances
for select to authenticated
using (owner_user_id = public.current_app_user_id() or public.is_admin());

create policy payouts_owner_admin_read on public.payouts
for select to authenticated
using (owner_user_id = public.current_app_user_id() or public.is_admin());

create policy payouts_owner_request on public.payouts
for insert to authenticated
with check (owner_user_id = public.current_app_user_id() and public.current_app_role() = 'owner');

create policy refunds_related_read on public.refunds
for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.bookings b
    where b.id = booking_id
      and (b.customer_user_id = public.current_app_user_id() or b.owner_user_id = public.current_app_user_id())
  )
);

create policy conversation_participants_read_own on public.conversation_participants
for select to authenticated
using (user_id = public.current_app_user_id() or public.is_admin());

create policy conversations_insert_creator on public.conversations
for insert to authenticated
with check (created_by = public.current_app_user_id());

create policy conversation_participants_insert_customer_owner on public.conversation_participants
for insert to authenticated
with check (
  user_id = public.current_app_user_id()
  or public.is_admin()
  or exists (
    select 1
    from public.conversations c
    join public.kosts k on k.id = c.kost_id
    where c.id = conversation_id
      and c.created_by = public.current_app_user_id()
      and k.owner_user_id = user_id
  )
);

create policy conversations_read_participant on public.conversations
for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = id and cp.user_id = public.current_app_user_id()
  )
);

create policy messages_read_participant on public.messages
for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = conversation_id and cp.user_id = public.current_app_user_id()
  )
);

create policy messages_insert_participant on public.messages
for insert to authenticated
with check (
  sender_user_id = public.current_app_user_id()
  and exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = conversation_id and cp.user_id = public.current_app_user_id()
  )
);

create policy message_reads_manage_own on public.message_reads
for all to authenticated
using (user_id = public.current_app_user_id())
with check (
  user_id = public.current_app_user_id()
  and exists (
    select 1
    from public.messages m
    join public.conversation_participants cp on cp.conversation_id = m.conversation_id
    where m.id = message_id and cp.user_id = public.current_app_user_id()
  )
);

create policy support_threads_customer_admin_read on public.support_threads
for select to authenticated
using (customer_user_id = public.current_app_user_id() or public.is_admin());

create policy support_threads_customer_insert on public.support_threads
for insert to authenticated
with check (customer_user_id = public.current_app_user_id());

create policy support_threads_admin_update on public.support_threads
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy support_messages_thread_member_read on public.support_messages
for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.support_threads st
    where st.id = thread_id and st.customer_user_id = public.current_app_user_id()
  )
);

create policy support_messages_thread_member_insert on public.support_messages
for insert to authenticated
with check (
  sender_user_id = public.current_app_user_id()
  and (
    public.is_admin()
    or exists (
      select 1 from public.support_threads st
      where st.id = thread_id and st.customer_user_id = public.current_app_user_id()
    )
  )
);

create policy notifications_recipient_read on public.notifications
for select to authenticated
using (recipient_user_id = public.current_app_user_id() or public.is_admin());

create policy notifications_recipient_update_read_at on public.notifications
for update to authenticated
using (recipient_user_id = public.current_app_user_id())
with check (recipient_user_id = public.current_app_user_id());

create policy notification_preferences_manage_own on public.notification_preferences
for all to authenticated
using (user_id = public.current_app_user_id())
with check (user_id = public.current_app_user_id());

create policy user_devices_manage_own on public.user_devices
for all to authenticated
using (user_id = public.current_app_user_id())
with check (user_id = public.current_app_user_id());

create policy reviews_public_read on public.reviews
for select to anon, authenticated
using (true);

create policy reviews_customer_insert_completed_booking on public.reviews
for insert to authenticated
with check (
  customer_user_id = public.current_app_user_id()
  and exists (
    select 1 from public.bookings b
    where b.id = booking_id and b.customer_user_id = public.current_app_user_id() and b.status = 'completed'
  )
);

create policy reports_insert_own on public.reports
for insert to authenticated
with check (reporter_user_id = public.current_app_user_id());

create policy reports_admin_read on public.reports
for select to authenticated
using (public.is_admin());

create policy reports_admin_update on public.reports
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy audit_logs_admin_read on public.audit_logs
for select to authenticated
using (public.is_admin());

create policy kost_photos_public_read on storage.objects
for select to anon, authenticated
using (bucket_id = 'kost-photos');

create policy kost_photos_owner_upload on storage.objects
for insert to authenticated
with check (
  bucket_id = 'kost-photos'
  and (storage.foldername(name))[1] = public.current_app_user_id()::text
);

create policy kost_photos_owner_update on storage.objects
for update to authenticated
using (
  bucket_id = 'kost-photos'
  and (storage.foldername(name))[1] = public.current_app_user_id()::text
)
with check (
  bucket_id = 'kost-photos'
  and (storage.foldername(name))[1] = public.current_app_user_id()::text
);

create policy owner_documents_owner_read on storage.objects
for select to authenticated
using (
  bucket_id = 'owner-documents'
  and ((storage.foldername(name))[1] = public.current_app_user_id()::text or public.is_admin())
);

create policy owner_documents_owner_upload on storage.objects
for insert to authenticated
with check (
  bucket_id = 'owner-documents'
  and (storage.foldername(name))[1] = public.current_app_user_id()::text
);

-- Deliberately no client insert/update policies for payments, payment_events,
-- owner_balances, admin payout updates, refunds, and audit_logs. Those mutations
-- must happen through Edge Functions or trusted service-role operations.
