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
