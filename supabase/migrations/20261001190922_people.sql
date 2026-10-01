create extension if not exists unaccent with schema extensions;

create function app.normalize_name(value text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select lower(regexp_replace(trim(extensions.unaccent('extensions.unaccent'::regdictionary, value)), '\s+', ' ', 'g'))
$$;

-- Teachers read their students through the class roster (enrollments), never the people table.
delete from app.role_capabilities where role = 'teacher' and capability = 'people.read';

-- Tables

create table public.people (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches (id),
  primary_congregation_id uuid,
  full_name text,
  search_name text generated always as (app.normalize_name(full_name)) stored,
  birth_date date,
  gender text check (gender in ('female', 'male')),
  phone text,
  email text,
  address_line text,
  neighborhood text,
  city text,
  state text check (state ~ '^[A-Z]{2}$'),
  postal_code text,
  guardian_person_id uuid,
  invited_by_person_id uuid,
  notes text,
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  anonymized_at timestamptz,
  unique (church_id, id),
  check (
    case when anonymized_at is null then length(trim(full_name)) > 0 else full_name is null end
  ),
  check (guardian_person_id <> id),
  check (invited_by_person_id <> id),
  foreign key (church_id, primary_congregation_id)
    references public.congregations (church_id, id),
  foreign key (church_id, guardian_person_id)
    references public.people (church_id, id),
  foreign key (church_id, invited_by_person_id)
    references public.people (church_id, id)
);

create index people_duplicate_idx on public.people (church_id, search_name, birth_date);
create index people_congregation_idx on public.people (church_id, primary_congregation_id);
create index people_guardian_idx on public.people (church_id, guardian_person_id)
  where guardian_person_id is not null;
create index people_invited_by_idx on public.people (church_id, invited_by_person_id)
  where invited_by_person_id is not null;

create table public.person_religious_info (
  person_id uuid primary key,
  church_id uuid not null,
  is_church_member boolean,
  baptized boolean,
  baptism_date date,
  origin_church text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (baptism_date is null or baptized is true),
  foreign key (church_id, person_id) references public.people (church_id, id)
);

create index audit_log_record_idx on app.audit_log (table_name, record_id);

-- RLS helpers

-- People policies pass the row's own congregation: looking the person up by id would miss
-- the row being inserted (insert ... returning) and lock scoped users out of it.
create function rls.can_read_person(church uuid, person uuid, congregation uuid)
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
      and rc.capability = 'people.read'
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

create function rls.can_read_person(church uuid, person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select rls.can_read_person(p.church_id, p.id, p.primary_congregation_id)
      from public.people p
      where p.church_id = church
        and p.id = person
    ),
    false
  )
$$;

create function rls.can_write_person(church uuid, person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select rls.has_capability(church, 'people.write')
    and exists (
      select 1
      from public.people p
      where p.church_id = church
        and p.id = person
        and p.anonymized_at is null
        and rls.can_read_person(p.church_id, p.id, p.primary_congregation_id)
    )
$$;

create function rls.religious_fields_enabled(church uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select c.religious_fields_enabled from public.churches c where c.id = church),
    false
  )
$$;

revoke execute on function
  app.normalize_name(text),
  rls.can_read_person(uuid, uuid, uuid),
  rls.can_read_person(uuid, uuid),
  rls.can_write_person(uuid, uuid),
  rls.religious_fields_enabled(uuid)
from public, anon, authenticated;

-- authenticated evaluates the generated search_name column on insert/update.
grant execute on function app.normalize_name(text) to authenticated;
grant execute on function
  rls.can_read_person(uuid, uuid, uuid),
  rls.can_read_person(uuid, uuid),
  rls.can_write_person(uuid, uuid),
  rls.religious_fields_enabled(uuid)
to authenticated;

-- Anonymization (Manual/#5 §6): erases identity, keeps the row (and future enrollments) for statistics.

create function public.anonymize_person(person_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  church uuid := rls.active_church_id();
  person uuid := anonymize_person.person_id;
begin
  if church is null or not rls.has_capability(church, 'people.write') then
    raise exception 'not allowed to anonymize people' using errcode = '42501';
  end if;

  if not rls.can_read_person(church, person) then
    raise exception 'person not found' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.people p
    where p.id = person and p.anonymized_at is not null
  ) then
    return;
  end if;

  delete from public.person_religious_info r where r.person_id = person;

  update public.people p
  set
    full_name = null,
    birth_date = date_trunc('year', p.birth_date)::date,
    phone = null,
    email = null,
    address_line = null,
    neighborhood = null,
    city = null,
    state = null,
    postal_code = null,
    guardian_person_id = null,
    invited_by_person_id = null,
    notes = null,
    anonymized_at = now()
  where p.id = person;

  -- Audit payloads would otherwise keep every erased value; only the anonymized snapshot survives.
  update app.audit_log a
  set
    old_data = null,
    new_data = case
      when a.table_name = 'people' and a.new_data ->> 'anonymized_at' is not null then a.new_data
    end
  where a.table_name in ('people', 'person_religious_info')
    and a.record_id = person;
end;
$$;

revoke execute on function public.anonymize_person(uuid) from public, anon, authenticated;
grant execute on function public.anonymize_person(uuid) to authenticated;

-- Triggers

create trigger set_updated_at before update on public.people
  for each row execute function app.set_updated_at();
create trigger set_updated_at before update on public.person_religious_info
  for each row execute function app.set_updated_at();

create trigger audit_row after insert or update or delete on public.people
  for each row execute function app.audit_row();
create trigger audit_row after insert or update or delete on public.person_religious_info
  for each row execute function app.audit_row('person_id');

-- Grants: people are never deleted through the API (anonymize instead), and
-- anonymized_at / created_by are set only by the database.

revoke all on table public.people, public.person_religious_info from anon, authenticated;

grant select on public.people to authenticated;
grant insert (
  church_id, primary_congregation_id, full_name, birth_date, gender, phone, email,
  address_line, neighborhood, city, state, postal_code, guardian_person_id,
  invited_by_person_id, notes
) on public.people to authenticated;
grant update (
  primary_congregation_id, full_name, birth_date, gender, phone, email,
  address_line, neighborhood, city, state, postal_code, guardian_person_id,
  invited_by_person_id, notes
) on public.people to authenticated;

grant select, delete on public.person_religious_info to authenticated;
grant insert (
  person_id, church_id, is_church_member, baptized, baptism_date, origin_church
) on public.person_religious_info to authenticated;
grant update (
  is_church_member, baptized, baptism_date, origin_church
) on public.person_religious_info to authenticated;

-- Policies

alter table public.people enable row level security;
alter table public.person_religious_info enable row level security;

create policy people_select on public.people
  for select to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.can_read_person(church_id, id, primary_congregation_id)
  );

create policy people_insert on public.people
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'people.write')
    and rls.can_access_congregation(church_id, primary_congregation_id)
  );

create policy people_update on public.people
  for update to authenticated
  using (
    church_id = (select rls.active_church_id())
    and anonymized_at is null
    and rls.has_capability(church_id, 'people.write')
    and rls.can_read_person(church_id, id, primary_congregation_id)
  )
  with check (
    church_id = (select rls.active_church_id())
    and anonymized_at is null
    and rls.has_capability(church_id, 'people.write')
    and rls.can_access_congregation(church_id, primary_congregation_id)
  );

create policy person_religious_info_select on public.person_religious_info
  for select to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.religious_fields_enabled(church_id)
    and rls.has_capability(church_id, 'people.read_sensitive')
    and rls.can_read_person(church_id, person_id)
  );

create policy person_religious_info_insert on public.person_religious_info
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.religious_fields_enabled(church_id)
    and rls.has_capability(church_id, 'people.read_sensitive')
    and rls.can_write_person(church_id, person_id)
  );

create policy person_religious_info_update on public.person_religious_info
  for update to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.religious_fields_enabled(church_id)
    and rls.has_capability(church_id, 'people.read_sensitive')
    and rls.can_write_person(church_id, person_id)
  )
  with check (
    church_id = (select rls.active_church_id())
    and rls.religious_fields_enabled(church_id)
    and rls.has_capability(church_id, 'people.read_sensitive')
    and rls.can_write_person(church_id, person_id)
  );

create policy person_religious_info_delete on public.person_religious_info
  for delete to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.religious_fields_enabled(church_id)
    and rls.has_capability(church_id, 'people.read_sensitive')
    and rls.can_write_person(church_id, person_id)
  );

update app.app_meta set value = '20261001190922' where key = 'schema_version';
