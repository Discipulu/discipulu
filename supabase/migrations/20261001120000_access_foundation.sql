create schema if not exists rls;

revoke all on schema rls from public, anon;
grant usage on schema rls to authenticated;

alter default privileges in schema rls revoke execute on functions from public;
alter default privileges in schema app revoke execute on functions from public;

-- Utilities

create function app.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table app.audit_log (
  id bigint generated always as identity primary key,
  church_id uuid,
  actor_id uuid,
  table_name text not null,
  record_id uuid,
  action text not null check (action in ('insert', 'update', 'delete')),
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

create index audit_log_church_created_idx on app.audit_log (church_id, created_at);

alter table app.audit_log enable row level security;

-- TG_ARGV[0] names the column used as record_id (default 'id').
create function app.audit_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  id_column text := coalesce(tg_argv[0], 'id');
  old_row jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  new_row jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  ref_row jsonb := coalesce(new_row, old_row);
begin
  insert into app.audit_log (church_id, actor_id, table_name, record_id, action, old_data, new_data)
  values (
    (ref_row ->> 'church_id')::uuid,
    auth.uid(),
    tg_table_name,
    (ref_row ->> id_column)::uuid,
    lower(tg_op),
    old_row,
    new_row
  );
  return null;
end;
$$;

-- Tables

create table public.churches (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  document text,
  city text,
  state text check (state ~ '^[A-Z]{2}$'),
  denomination text,
  timezone text not null default 'America/Sao_Paulo',
  logo_path text,
  religious_fields_enabled boolean not null default true,
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.user_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  active_church_id uuid references public.churches (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.congregations (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches (id),
  name text not null check (length(trim(name)) > 0),
  is_headquarters boolean not null default false,
  address_line text,
  neighborhood text,
  city text,
  state text check (state ~ '^[A-Z]{2}$'),
  postal_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (church_id, id)
);

create unique index congregations_one_headquarters_idx
  on public.congregations (church_id) where is_headquarters;

create table public.church_members (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches (id),
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'secretary', 'teacher', 'viewer')),
  all_congregations boolean not null default true,
  status text not null default 'active' check (status in ('active', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (church_id, user_id),
  unique (church_id, id)
);

create index church_members_user_idx on public.church_members (user_id, created_at);

create table public.church_member_congregations (
  church_id uuid not null,
  member_id uuid not null,
  congregation_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (member_id, congregation_id),
  foreign key (church_id, member_id)
    references public.church_members (church_id, id) on delete cascade,
  foreign key (church_id, congregation_id)
    references public.congregations (church_id, id)
);

create index church_member_congregations_congregation_idx
  on public.church_member_congregations (church_id, congregation_id);

create table app.role_capabilities (
  role text not null check (role in ('owner', 'admin', 'secretary', 'teacher', 'viewer')),
  capability text not null,
  primary key (role, capability)
);

alter table app.role_capabilities enable row level security;

insert into app.role_capabilities (role, capability)
select r.role, c.capability
from (values ('owner'), ('admin')) as r (role)
cross join (
  values
    ('church.manage'), ('church.billing'), ('members.manage'), ('members.manage_owners'),
    ('congregations.manage'), ('people.read'), ('people.write'), ('people.read_sensitive'),
    ('people.export'), ('classes.manage'), ('enrollments.manage'), ('attendance.record'),
    ('sunday.close'), ('reports.read'), ('audit.read')
) as c (capability)
where r.role = 'owner' or c.capability not in ('church.billing', 'members.manage_owners')
union all
select 'secretary', capability
from (
  values
    ('people.read'), ('people.write'), ('people.read_sensitive'), ('people.export'),
    ('classes.manage'), ('enrollments.manage'), ('attendance.record'), ('sunday.close'),
    ('reports.read')
) as c (capability)
union all
select 'teacher', capability
from (values ('people.read'), ('attendance.record'), ('reports.read')) as c (capability)
union all
select 'viewer', 'reports.read';

-- RLS helpers. security definer so policies on church_members can call them without recursing.

create function rls.active_church_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select nullif(auth.jwt() ->> 'active_church_id', '')::uuid
$$;

create function rls.current_member(church uuid)
returns public.church_members
language sql
stable
security definer
set search_path = ''
as $$
  select m.*
  from public.church_members m
  where m.church_id = church
    and m.user_id = auth.uid()
    and m.status = 'active'
$$;

create function rls.is_member(church uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.church_members m
    where m.church_id = church
      and m.user_id = auth.uid()
      and m.status = 'active'
  )
$$;

create function rls.has_capability(church uuid, cap text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.church_members m
    join app.role_capabilities rc on rc.role = m.role
    where m.church_id = church
      and m.user_id = auth.uid()
      and m.status = 'active'
      and rc.capability = cap
  )
$$;

create function rls.can_access_congregation(church uuid, congregation uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.church_members m
    where m.church_id = church
      and m.user_id = auth.uid()
      and m.status = 'active'
      and (
        m.all_congregations
        or exists (
          select 1
          from public.church_member_congregations s
          where s.member_id = m.id
            and s.congregation_id = congregation
        )
      )
  )
$$;

revoke execute on all functions in schema rls from public, anon, authenticated;
grant execute on function
  rls.active_church_id(),
  rls.current_member(uuid),
  rls.is_member(uuid),
  rls.has_capability(uuid, text),
  rls.can_access_congregation(uuid, uuid)
to authenticated;

revoke execute on all functions in schema app from public, anon, authenticated;

-- Profile creation on sign-up

create function app.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.user_profiles (user_id, full_name)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''));
  return new;
end;
$$;

revoke execute on function app.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();

-- Triggers

create trigger set_updated_at before update on public.user_profiles
  for each row execute function app.set_updated_at();
create trigger set_updated_at before update on public.churches
  for each row execute function app.set_updated_at();
create trigger set_updated_at before update on public.congregations
  for each row execute function app.set_updated_at();
create trigger set_updated_at before update on public.church_members
  for each row execute function app.set_updated_at();

create trigger audit_row after insert or update or delete on public.church_members
  for each row execute function app.audit_row();
create trigger audit_row after insert or update or delete on public.church_member_congregations
  for each row execute function app.audit_row('member_id');

-- Grants: the app never deletes churches, congregations or profiles.

revoke all on table
  public.user_profiles, public.churches, public.congregations,
  public.church_members, public.church_member_congregations
from anon, authenticated;

grant select, update (full_name, active_church_id) on public.user_profiles to authenticated;
grant select, update on public.churches to authenticated;
grant select, insert, update on public.congregations to authenticated;
grant select, insert, update, delete on public.church_members to authenticated;
grant select, insert, delete on public.church_member_congregations to authenticated;

-- Policies

alter table public.user_profiles enable row level security;
alter table public.churches enable row level security;
alter table public.congregations enable row level security;
alter table public.church_members enable row level security;
alter table public.church_member_congregations enable row level security;

create policy user_profiles_select_own on public.user_profiles
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy user_profiles_update_own on public.user_profiles
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (active_church_id is null or rls.is_member(active_church_id))
  );

-- Every church the user belongs to is listed (church switcher); everything else is scoped to the active church.
create policy churches_select_member on public.churches
  for select to authenticated
  using (rls.is_member(id));

create policy churches_update on public.churches
  for update to authenticated
  using (id = (select rls.active_church_id()) and rls.has_capability(id, 'church.manage'))
  with check (id = (select rls.active_church_id()) and rls.has_capability(id, 'church.manage'));

create policy congregations_select on public.congregations
  for select to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.can_access_congregation(church_id, id)
  );

create policy congregations_insert on public.congregations
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'congregations.manage')
  );

create policy congregations_update on public.congregations
  for update to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'congregations.manage')
  )
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'congregations.manage')
  );

-- Members never change their own row (no self-promotion, no last-owner lockout);
-- owner rows need members.manage_owners.
create policy church_members_select on public.church_members
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (
      church_id = (select rls.active_church_id())
      and rls.has_capability(church_id, 'members.manage')
    )
  );

create policy church_members_insert on public.church_members
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'members.manage')
    and user_id <> (select auth.uid())
    and (role <> 'owner' or rls.has_capability(church_id, 'members.manage_owners'))
  );

create policy church_members_update on public.church_members
  for update to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'members.manage')
    and user_id <> (select auth.uid())
    and (role <> 'owner' or rls.has_capability(church_id, 'members.manage_owners'))
  )
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'members.manage')
    and user_id <> (select auth.uid())
    and (role <> 'owner' or rls.has_capability(church_id, 'members.manage_owners'))
  );

create policy church_members_delete on public.church_members
  for delete to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'members.manage')
    and user_id <> (select auth.uid())
    and (role <> 'owner' or rls.has_capability(church_id, 'members.manage_owners'))
  );

create policy church_member_congregations_select on public.church_member_congregations
  for select to authenticated
  using (
    church_id = (select rls.active_church_id())
    and (
      member_id = (rls.current_member(church_id)).id
      or rls.has_capability(church_id, 'members.manage')
    )
  );

create policy church_member_congregations_insert on public.church_member_congregations
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'members.manage')
    and member_id is distinct from (rls.current_member(church_id)).id
  );

create policy church_member_congregations_delete on public.church_member_congregations
  for delete to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'members.manage')
    and member_id is distinct from (rls.current_member(church_id)).id
  );

-- Custom access token hook. Runs as supabase_auth_admin, which does NOT bypass RLS:
-- without the policies below the claim silently comes out null.

grant usage on schema app to supabase_auth_admin;
grant select on public.user_profiles, public.church_members to supabase_auth_admin;

create policy user_profiles_select_auth_admin on public.user_profiles
  for select to supabase_auth_admin
  using (true);

create policy church_members_select_auth_admin on public.church_members
  for select to supabase_auth_admin
  using (true);

create function app.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  uid uuid;
  church uuid;
begin
  begin
    uid := (event ->> 'user_id')::uuid;

    select p.active_church_id into church
    from public.user_profiles p
    where p.user_id = uid;

    if church is null or not exists (
      select 1 from public.church_members m
      where m.church_id = church and m.user_id = uid and m.status = 'active'
    ) then
      select m.church_id into church
      from public.church_members m
      where m.user_id = uid and m.status = 'active'
      order by m.created_at, m.id
      limit 1;
    end if;

    return jsonb_set(
      event,
      '{claims,active_church_id}',
      coalesce(to_jsonb(church::text), 'null'::jsonb)
    );
  exception when others then
    return event;
  end;
end;
$$;

revoke execute on function app.custom_access_token_hook(jsonb) from public, anon, authenticated;
grant execute on function app.custom_access_token_hook(jsonb) to supabase_auth_admin;

update app.app_meta set value = '20261001120000' where key = 'schema_version';
