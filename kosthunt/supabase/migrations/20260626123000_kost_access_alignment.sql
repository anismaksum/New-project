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
