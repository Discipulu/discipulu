-- Teachers read their students only through public.class_roster; viewers never do.
insert into app.role_capabilities (role, capability) values
  ('owner', 'people.read_roster'),
  ('admin', 'people.read_roster'),
  ('secretary', 'people.read_roster'),
  ('teacher', 'people.read_roster');

-- Tables

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches (id),
  congregation_id uuid not null,
  name text not null check (length(trim(name)) > 0),
  min_age integer check (min_age >= 0),
  max_age integer check (max_age >= 0),
  room text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (church_id, id),
  unique (church_id, id, congregation_id),
  check (max_age >= min_age),
  foreign key (church_id, congregation_id)
    references public.congregations (church_id, id)
);

create index classes_congregation_idx on public.classes (church_id, congregation_id);

create table public.class_teachers (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches (id),
  class_id uuid not null,
  person_id uuid not null,
  member_id uuid,
  role text not null default 'lead' check (role in ('lead', 'assistant')),
  started_on date not null,
  ended_on date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ended_on >= started_on),
  foreign key (church_id, class_id)
    references public.classes (church_id, id),
  foreign key (church_id, person_id)
    references public.people (church_id, id),
  foreign key (church_id, member_id)
    references public.church_members (church_id, id) on delete set null (member_id)
);

create unique index class_teachers_one_active_idx
  on public.class_teachers (class_id, person_id) where ended_on is null;
create index class_teachers_member_idx on public.class_teachers (church_id, member_id)
  where member_id is not null;

-- congregation_id is copied from the class (trigger) and kept consistent by the
-- three-column FK, so moving a class with enrollments is refused.
create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  church_id uuid not null references public.churches (id),
  person_id uuid not null,
  class_id uuid not null,
  congregation_id uuid not null,
  started_on date not null,
  ended_on date,
  end_reason text check (end_reason in ('moved_class', 'left', 'deceased', 'other')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (church_id, id),
  check (ended_on >= started_on),
  check ((ended_on is null) = (end_reason is null)),
  foreign key (church_id, person_id)
    references public.people (church_id, id),
  foreign key (church_id, class_id, congregation_id)
    references public.classes (church_id, id, congregation_id)
);

create unique index enrollments_one_active_per_congregation_idx
  on public.enrollments (person_id, congregation_id) where ended_on is null;
create index enrollments_person_idx on public.enrollments (church_id, person_id, congregation_id);
create index enrollments_class_idx on public.enrollments (church_id, class_id)
  where ended_on is null;

-- Calendar dates follow the church's timezone: current_date is UTC on Supabase and
-- is already the next day on Sunday nights in Brazil.
create function app.church_today(church uuid)
returns date
language sql
stable
set search_path = ''
as $$
  select (
    now() at time zone coalesce(
      (select c.timezone from public.churches c where c.id = church),
      'UTC'
    )
  )::date
$$;

-- Trigger functions

create function app.fill_started_on()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.started_on := coalesce(new.started_on, app.church_today(new.church_id));
  return new;
end;
$$;

create function app.prepare_enrollment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  class_church uuid;
  class_congregation uuid;
  class_archived_at timestamptz;
begin
  -- Looked up by id alone: a class of another church still fills congregation_id,
  -- so the composite FK rejects it (23503) instead of a not-null error.
  select c.church_id, c.congregation_id, c.archived_at
  into class_church, class_congregation, class_archived_at
  from public.classes c
  where c.id = new.class_id;

  new.congregation_id := class_congregation;
  new.started_on := coalesce(new.started_on, app.church_today(new.church_id));

  if class_church = new.church_id and class_archived_at is not null then
    raise exception 'class % is archived', new.class_id using errcode = 'check_violation';
  end if;

  if exists (
    select 1 from public.people p
    where p.church_id = new.church_id
      and p.id = new.person_id
      and p.anonymized_at is not null
  ) then
    raise exception 'person % is anonymized', new.person_id using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create function app.lock_enrollment_identity()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.church_id, new.person_id, new.class_id, new.congregation_id)
    is distinct from (old.church_id, old.person_id, old.class_id, old.congregation_id)
  then
    raise exception 'an enrollment keeps its person and class: end it and open another'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create function app.check_class_archive()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.archived_at is not null and old.archived_at is null and exists (
    select 1 from public.enrollments e
    where e.church_id = new.church_id
      and e.class_id = new.id
      and e.ended_on is null
  ) then
    raise exception 'class % still has active enrollments', new.id using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

-- RLS helpers

create function rls.teaches_class(church uuid, class uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.class_teachers t
    join public.church_members m on m.church_id = t.church_id and m.id = t.member_id
    where t.church_id = church
      and t.class_id = class
      and t.ended_on is null
      and m.user_id = auth.uid()
      and m.status = 'active'
  )
$$;

create function rls.can_access_class(church uuid, class uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.classes c
    where c.church_id = church
      and c.id = class
      and rls.can_access_congregation(c.church_id, c.congregation_id)
  )
$$;

-- Scope now also covers people with a current or past enrollment in a class of the scope.
create or replace function rls.can_read_person(church uuid, person uuid, congregation uuid)
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
            and (
              s.congregation_id = congregation
              or exists (
                select 1
                from public.enrollments e
                where e.church_id = church
                  and e.person_id = person
                  and e.congregation_id = s.congregation_id
              )
            )
        )
      )
  )
$$;

-- Writing stays with the person's own congregation: being enrolled in a class of the
-- scope makes a person readable, not editable (nor anonymizable).
create or replace function rls.can_write_person(church uuid, person uuid)
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
        and rls.can_access_congregation(p.church_id, p.primary_congregation_id)
    )
$$;

revoke execute on function
  app.church_today(uuid),
  app.fill_started_on(),
  app.prepare_enrollment(),
  app.lock_enrollment_identity(),
  app.check_class_archive(),
  rls.teaches_class(uuid, uuid),
  rls.can_access_class(uuid, uuid)
from public, anon, authenticated;

grant execute on function
  rls.teaches_class(uuid, uuid),
  rls.can_access_class(uuid, uuid)
to authenticated;

-- Anonymization also closes the person's active enrollments.

create or replace function public.anonymize_person(person_id uuid)
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

  if not rls.can_write_person(church, person) then
    raise exception 'not allowed to anonymize this person' using errcode = '42501';
  end if;

  delete from public.person_religious_info r where r.person_id = person;

  update public.enrollments e
  set
    ended_on = greatest(e.started_on, app.church_today(church)),
    end_reason = 'other'
  where e.church_id = church
    and e.person_id = person
    and e.ended_on is null;

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

-- Triggers

create trigger set_updated_at before update on public.classes
  for each row execute function app.set_updated_at();
create trigger set_updated_at before update on public.class_teachers
  for each row execute function app.set_updated_at();
create trigger set_updated_at before update on public.enrollments
  for each row execute function app.set_updated_at();

create trigger check_archive before update on public.classes
  for each row execute function app.check_class_archive();

create trigger fill_started_on before insert on public.class_teachers
  for each row execute function app.fill_started_on();

create trigger prepare_enrollment before insert on public.enrollments
  for each row execute function app.prepare_enrollment();
create trigger lock_identity before update on public.enrollments
  for each row execute function app.lock_enrollment_identity();

create trigger audit_row after insert or update or delete on public.class_teachers
  for each row execute function app.audit_row();
create trigger audit_row after insert or update or delete on public.enrollments
  for each row execute function app.audit_row();

-- Grants: classes are archived, enrollments and teacher assignments are ended, never deleted.

revoke all on table public.classes, public.class_teachers, public.enrollments from anon, authenticated;

grant select on public.classes to authenticated;
grant insert (
  church_id, congregation_id, name, min_age, max_age, room, sort_order
) on public.classes to authenticated;
grant update (
  congregation_id, name, min_age, max_age, room, sort_order, archived_at
) on public.classes to authenticated;

grant select on public.class_teachers to authenticated;
grant insert (
  church_id, class_id, person_id, member_id, role, started_on, ended_on
) on public.class_teachers to authenticated;
grant update (member_id, role, started_on, ended_on) on public.class_teachers to authenticated;

grant select on public.enrollments to authenticated;
grant insert (
  church_id, person_id, class_id, started_on, ended_on, end_reason
) on public.enrollments to authenticated;
grant update (started_on, ended_on, end_reason) on public.enrollments to authenticated;

-- Policies

alter table public.classes enable row level security;
alter table public.class_teachers enable row level security;
alter table public.enrollments enable row level security;

create policy classes_select on public.classes
  for select to authenticated
  using (
    church_id = (select rls.active_church_id())
    and (
      rls.can_access_congregation(church_id, congregation_id)
      or rls.teaches_class(church_id, id)
    )
  );

create policy classes_insert on public.classes
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'classes.manage')
    and rls.can_access_congregation(church_id, congregation_id)
  );

create policy classes_update on public.classes
  for update to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'classes.manage')
    and rls.can_access_congregation(church_id, congregation_id)
  )
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'classes.manage')
    and rls.can_access_congregation(church_id, congregation_id)
  );

create policy class_teachers_select on public.class_teachers
  for select to authenticated
  using (
    church_id = (select rls.active_church_id())
    and (
      rls.can_access_class(church_id, class_id)
      or rls.teaches_class(church_id, class_id)
    )
  );

create policy class_teachers_insert on public.class_teachers
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'classes.manage')
    and rls.can_access_class(church_id, class_id)
  );

create policy class_teachers_update on public.class_teachers
  for update to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'classes.manage')
    and rls.can_access_class(church_id, class_id)
  )
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'classes.manage')
    and rls.can_access_class(church_id, class_id)
  );

create policy enrollments_select on public.enrollments
  for select to authenticated
  using (
    church_id = (select rls.active_church_id())
    and (
      (
        rls.has_capability(church_id, 'people.read')
        and rls.can_access_congregation(church_id, congregation_id)
      )
      or (
        rls.has_capability(church_id, 'people.read_roster')
        and rls.teaches_class(church_id, class_id)
      )
    )
  );

-- The person must already be readable: enrolling grants read access, so it must not
-- be a way to reach people outside the scope.
create policy enrollments_insert on public.enrollments
  for insert to authenticated
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'enrollments.manage')
    and rls.can_access_congregation(church_id, congregation_id)
    and rls.can_read_person(church_id, person_id)
  );

create policy enrollments_update on public.enrollments
  for update to authenticated
  using (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'enrollments.manage')
    and rls.can_access_congregation(church_id, congregation_id)
  )
  with check (
    church_id = (select rls.active_church_id())
    and rls.has_capability(church_id, 'enrollments.manage')
    and rls.can_access_congregation(church_id, congregation_id)
  );

-- Class roster: the teacher's window on students (teachers have no people.read). The
-- access rule lives in this security definer function; app has no usage for authenticated,
-- so it is reachable only through the public.class_roster view below.
create function app.class_roster()
returns table (
  enrollment_id uuid,
  church_id uuid,
  class_id uuid,
  person_id uuid,
  started_on date,
  full_name text,
  age integer,
  birth_month integer,
  birth_day integer,
  phone text,
  phone_is_guardian boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    e.id,
    e.church_id,
    e.class_id,
    e.person_id,
    e.started_on,
    p.full_name,
    a.age,
    extract(month from p.birth_date)::integer,
    extract(day from p.birth_date)::integer,
    case when a.age < 18 and g.phone is not null then g.phone else p.phone end,
    coalesce(a.age < 18 and g.phone is not null, false)
  from public.enrollments e
  join public.people p on p.church_id = e.church_id and p.id = e.person_id
  left join public.people g
    on g.church_id = p.church_id and g.id = p.guardian_person_id and g.anonymized_at is null
  cross join lateral (
    select extract(year from age(app.church_today(e.church_id), p.birth_date))::integer as age
  ) a
  where e.ended_on is null
    and p.anonymized_at is null
    and e.church_id = rls.active_church_id()
    and rls.has_capability(e.church_id, 'people.read_roster')
    and rls.teaches_class(e.church_id, e.class_id)
$$;

revoke execute on function app.class_roster() from public, anon, authenticated;
grant execute on function app.class_roster() to authenticated;

create view public.class_roster
with (security_invoker = true)
as
select * from app.class_roster();

revoke all on public.class_roster from anon, authenticated;
grant select on public.class_roster to authenticated;

update app.app_meta set value = '20261001193442' where key = 'schema_version';
