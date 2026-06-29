do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'owners_user_id_key'
      and conrelid = 'public.owners'::regclass
  ) then
    alter table public.owners
      add constraint owners_user_id_key unique (user_id);
  end if;
end
$$;

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
