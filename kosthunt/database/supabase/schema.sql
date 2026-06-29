-- KostHunt Supabase/PostgreSQL schema.
-- Run this file in the Supabase SQL editor before connecting the Flutter app.

create extension if not exists pgcrypto;

create table if not exists public.app_users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete set null,
  full_name text not null,
  phone text not null,
  role text not null check (role in ('customer', 'owner', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.owners (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references public.app_users(id) on delete set null,
  display_name text not null,
  phone text not null,
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.kosts (
  id text primary key,
  owner_id uuid references public.owners(id) on delete set null,
  name text not null,
  city text not null,
  address text not null,
  price integer not null check (price >= 0),
  distance_km numeric(8, 2) not null default 0,
  image_url text not null,
  facilities text[] not null default '{}',
  is_verified boolean not null default false,
  is_available boolean not null default true,
  category text not null,
  owner_name text not null,
  owner_phone text not null,
  description text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id text primary key,
  kost_id text not null references public.kosts(id) on delete restrict,
  customer_user_id uuid references public.app_users(id) on delete set null,
  customer_name text not null,
  customer_phone text not null,
  schedule_label text not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled', 'completed')),
  notification_status text not null default 'pending',
  notification_reference text not null default '-',
  notification_message text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.booking_messages (
  id text primary key,
  booking_id text not null references public.bookings(id) on delete cascade,
  sender_role text not null check (sender_role in ('customer', 'admin', 'owner', 'system')),
  sender_name text not null,
  sender_phone text,
  body text not null,
  delivery_status text not null default 'saved',
  notification_reference text not null default '-',
  created_at timestamptz not null default now()
);

create table if not exists public.support_messages (
  id text primary key,
  customer_name text not null,
  customer_phone text not null,
  body text not null,
  sent_by_customer boolean not null default true,
  delivery_status text not null default 'saved',
  notification_reference text not null default '-',
  created_at timestamptz not null default now()
);

create table if not exists public.notification_logs (
  id uuid primary key default gen_random_uuid(),
  related_type text not null check (
    related_type in ('booking', 'booking_message', 'support_message', 'system')
  ),
  related_id text not null,
  event_type text not null,
  channel text not null default 'whatsapp',
  provider text not null default 'fonnte',
  target_phone text not null,
  success boolean not null default false,
  reference text not null default '-',
  message text not null default '',
  raw_response jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.favorite_kosts (
  user_id uuid not null references public.app_users(id) on delete cascade,
  kost_id text not null references public.kosts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, kost_id)
);

create index if not exists idx_kosts_owner_id on public.kosts(owner_id);
create index if not exists idx_kosts_city on public.kosts(city);
create index if not exists idx_kosts_is_available on public.kosts(is_available);
create index if not exists idx_bookings_kost_id on public.bookings(kost_id);
create index if not exists idx_bookings_status on public.bookings(status);
create index if not exists idx_booking_messages_booking_id
  on public.booking_messages(booking_id);
create index if not exists idx_support_messages_created_at
  on public.support_messages(created_at);
create index if not exists idx_notification_logs_related
  on public.notification_logs(related_type, related_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_app_users_updated_at on public.app_users;
create trigger set_app_users_updated_at
before update on public.app_users
for each row execute function public.set_updated_at();

drop trigger if exists set_owners_updated_at on public.owners;
create trigger set_owners_updated_at
before update on public.owners
for each row execute function public.set_updated_at();

drop trigger if exists set_kosts_updated_at on public.kosts;
create trigger set_kosts_updated_at
before update on public.kosts
for each row execute function public.set_updated_at();

drop trigger if exists set_bookings_updated_at on public.bookings;
create trigger set_bookings_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();

alter table public.app_users enable row level security;
alter table public.owners enable row level security;
alter table public.kosts enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_messages enable row level security;
alter table public.support_messages enable row level security;
alter table public.notification_logs enable row level security;
alter table public.favorite_kosts enable row level security;

drop policy if exists "Users can read their own profile" on public.app_users;
create policy "Users can read their own profile"
on public.app_users for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "Users can create their own profile" on public.app_users;
create policy "Users can create their own profile"
on public.app_users for insert
to authenticated
with check (
  auth_user_id = auth.uid()
  and role in ('customer', 'owner')
);

drop policy if exists "Owners can read their own profile" on public.owners;
create policy "Owners can read their own profile"
on public.owners for select
to authenticated
using (
  user_id in (
    select id from public.app_users where auth_user_id = auth.uid()
  )
);

drop policy if exists "Owners can create their own owner profile" on public.owners;
create policy "Owners can create their own owner profile"
on public.owners for insert
to authenticated
with check (
  user_id in (
    select id
    from public.app_users
    where auth_user_id = auth.uid() and role = 'owner'
  )
);

drop policy if exists "Owners can read their own kosts" on public.kosts;
create policy "Owners can read their own kosts"
on public.kosts for select
to authenticated
using (
  owner_id in (
    select o.id
    from public.owners o
    join public.app_users u on u.id = o.user_id
    where u.auth_user_id = auth.uid() and u.role = 'owner'
  )
);

drop policy if exists "Owners can create their own kosts" on public.kosts;
create policy "Owners can create their own kosts"
on public.kosts for insert
to authenticated
with check (
  owner_id in (
    select o.id
    from public.owners o
    join public.app_users u on u.id = o.user_id
    where u.auth_user_id = auth.uid() and u.role = 'owner'
  )
);

drop policy if exists "Owners can update their own kosts" on public.kosts;
create policy "Owners can update their own kosts"
on public.kosts for update
to authenticated
using (
  owner_id in (
    select o.id
    from public.owners o
    join public.app_users u on u.id = o.user_id
    where u.auth_user_id = auth.uid() and u.role = 'owner'
  )
)
with check (
  owner_id in (
    select o.id
    from public.owners o
    join public.app_users u on u.id = o.user_id
    where u.auth_user_id = auth.uid() and u.role = 'owner'
  )
);

drop policy if exists "Admins can read all kosts" on public.kosts;
create policy "Admins can read all kosts"
on public.kosts for select
to authenticated
using (
  exists (
    select 1
    from public.app_users u
    where u.auth_user_id = auth.uid() and u.role = 'admin'
  )
);

drop policy if exists "Admins can update all kosts" on public.kosts;
create policy "Admins can update all kosts"
on public.kosts for update
to authenticated
using (
  exists (
    select 1
    from public.app_users u
    where u.auth_user_id = auth.uid() and u.role = 'admin'
  )
)
with check (
  exists (
    select 1
    from public.app_users u
    where u.auth_user_id = auth.uid() and u.role = 'admin'
  )
);

drop policy if exists "Public can read verified and available kosts" on public.kosts;
drop policy if exists "Public can read available kosts" on public.kosts;
create policy "Public can read available kosts"
on public.kosts for select
using (is_available = true);

drop policy if exists "Demo can read all kosts" on public.kosts;
drop policy if exists "Demo can update listing moderation" on public.kosts;

drop policy if exists "Demo can read bookings" on public.bookings;
create policy "Demo can read bookings"
on public.bookings for select
to anon
using (true);

drop policy if exists "Demo can create bookings" on public.bookings;
create policy "Demo can create bookings"
on public.bookings for insert
to anon
with check (true);

drop policy if exists "Demo can update bookings" on public.bookings;
create policy "Demo can update bookings"
on public.bookings for update
to anon
using (true)
with check (true);

drop policy if exists "Demo can read booking messages" on public.booking_messages;
create policy "Demo can read booking messages"
on public.booking_messages for select
to anon
using (true);

drop policy if exists "Demo can create booking messages" on public.booking_messages;
create policy "Demo can create booking messages"
on public.booking_messages for insert
to anon
with check (true);

drop policy if exists "Demo can update booking messages" on public.booking_messages;
create policy "Demo can update booking messages"
on public.booking_messages for update
to anon
using (true)
with check (true);

drop policy if exists "Demo can read support messages" on public.support_messages;
create policy "Demo can read support messages"
on public.support_messages for select
to anon
using (true);

drop policy if exists "Demo can create support messages" on public.support_messages;
create policy "Demo can create support messages"
on public.support_messages for insert
to anon
with check (true);

drop policy if exists "Demo can update support messages" on public.support_messages;
create policy "Demo can update support messages"
on public.support_messages for update
to anon
using (true)
with check (true);

drop policy if exists "Demo can create notification logs" on public.notification_logs;
create policy "Demo can create notification logs"
on public.notification_logs for insert
to anon
with check (true);

drop policy if exists "Authenticated users can create bookings" on public.bookings;
create policy "Authenticated users can create bookings"
on public.bookings for insert
to authenticated
with check (true);

drop policy if exists "Customers can read their own bookings" on public.bookings;
create policy "Customers can read their own bookings"
on public.bookings for select
to authenticated
using (
  customer_user_id in (
    select id from public.app_users where auth_user_id = auth.uid()
  )
);

drop policy if exists "Customers can read their booking messages" on public.booking_messages;
create policy "Customers can read their booking messages"
on public.booking_messages for select
to authenticated
using (
  booking_id in (
    select b.id
    from public.bookings b
    join public.app_users u on u.id = b.customer_user_id
    where u.auth_user_id = auth.uid()
  )
);

drop policy if exists "Customers can add booking messages" on public.booking_messages;
create policy "Customers can add booking messages"
on public.booking_messages for insert
to authenticated
with check (
  sender_role = 'customer'
  and booking_id in (
    select b.id
    from public.bookings b
    join public.app_users u on u.id = b.customer_user_id
    where u.auth_user_id = auth.uid()
  )
);

drop policy if exists "Users can manage their favorites" on public.favorite_kosts;
create policy "Users can manage their favorites"
on public.favorite_kosts for all
to authenticated
using (
  user_id in (
    select id from public.app_users where auth_user_id = auth.uid()
  )
)
with check (
  user_id in (
    select id from public.app_users where auth_user_id = auth.uid()
  )
);
