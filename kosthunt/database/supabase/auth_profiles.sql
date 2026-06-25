-- Run this after creating users in Supabase Auth.
-- Kamu bisa pakai set lama (.test) atau set baru (.com).
-- Password yang disarankan: KostHunt212

insert into public.app_users (auth_user_id, full_name, phone, role)
select id, 'Customer KostHunt', '628129990001', 'customer'
from auth.users
where email in ('customer@kosthunt.test', 'customer@kosthunt.com')
on conflict (auth_user_id) do update set
  full_name = excluded.full_name,
  phone = excluded.phone,
  role = excluded.role;

insert into public.app_users (auth_user_id, full_name, phone, role)
select id, 'Owner KostHunt', '628122220002', 'owner'
from auth.users
where email in ('owner@kosthunt.test', 'owner@kosthunt.com')
on conflict (auth_user_id) do update set
  full_name = excluded.full_name,
  phone = excluded.phone,
  role = excluded.role;

insert into public.app_users (auth_user_id, full_name, phone, role)
select id, 'Admin KostHunt', '6285701054362', 'admin'
from auth.users
where email in ('admin@kosthunt.test', 'admin@kosthunt.com')
on conflict (auth_user_id) do update set
  full_name = excluded.full_name,
  phone = excluded.phone,
  role = excluded.role;
