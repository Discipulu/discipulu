begin;

-- Fixtures (fictional). Churches A and B have the same shape: Sede + Norte, one user per
-- role (secretary scoped to Norte), people p1 (Sede, class c1), p2 (Norte, class c2),
-- p3 (Sede, teaches c1 with the teacher's login and c2 without one) and p4 (Norte, no
-- enrollment). Ids come from md5 so they never collide with the seed loaded before the tests.

create function pg_temp.fx(church text, key text)
returns uuid
language sql
immutable
as $$
  select md5('isolation:' || church || ':' || key)::uuid
$$;

-- {key} becomes the fixture id of that key in the given church; {self} the acting user.
create function pg_temp.render(statement text, church text, actor uuid)
returns text
language plpgsql
as $$
declare
  key text;
  rendered text := replace(statement, '{self}', coalesce(actor::text, ''));
begin
  for key in select distinct m[1] from regexp_matches(rendered, '\{(\w+)\}', 'g') as m loop
    rendered := replace(rendered, '{' || key || '}', pg_temp.fx(church, key)::text);
  end loop;
  return rendered;
end;
$$;

-- Runs a statement with the given role and claims, then rolls it back: returns the number
-- of rows it touched or returned, or the SQLSTATE it raised.
create function pg_temp.attempt(db_role text, actor uuid, church uuid, statement text)
returns text
language plpgsql
as $$
declare
  affected bigint;
  outcome text;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', actor, 'role', db_role, 'active_church_id', church)::text,
    true
  );
  execute format('set local role %I', db_role);
  begin
    execute statement;
    get diagnostics affected = row_count;
    outcome := affected::text;
    raise sqlstate 'ZZ000';
  exception
    when sqlstate 'ZZ000' then null;
    when others then outcome := sqlstate;
  end;
  reset role;
  perform set_config('request.jwt.claims', '', true);
  return outcome;
end;
$$;

-- Every tenant row the user can see, minus the church list and their own memberships
-- (both are visible by design without an active church).
create function pg_temp.visible_rows()
returns text
language sql
immutable
as $$
  select 'select 1 from public.congregations
    union all select 1 from public.church_members where user_id <> ''{self}''
    union all select 1 from public.church_member_congregations
    union all select 1 from public.people
    union all select 1 from public.person_religious_info
    union all select 1 from public.classes
    union all select 1 from public.class_teachers
    union all select 1 from public.enrollments
    union all select 1 from public.class_roster'
$$;

create temp table actors (church text, other text, role text, ord int, user_id uuid, church_id uuid);

insert into actors
select c.church, c.other, r.role, r.ord, pg_temp.fx(c.church, 'u_' || r.role), pg_temp.fx(c.church, 'church')
from (values ('A', 'B'), ('B', 'A')) as c (church, other)
cross join (values ('owner', 1), ('admin', 2), ('secretary', 3), ('teacher', 4), ('viewer', 5)) as r (role, ord);

insert into auth.users (id, email)
select user_id, format('%s.isolamento-%s@exemplo.test', role, lower(church)) from actors
union all
select pg_temp.fx(c, 'u_loose'), format('sem.vinculo.isolamento-%s@exemplo.test', lower(c))
from (values ('A'), ('B')) as t (c)
union all
select pg_temp.fx('A', 'u_dual'), 'duas.igrejas.isolamento@exemplo.test'
union all
select pg_temp.fx('A', 'u_revoked'), 'revogado.isolamento-a@exemplo.test';

insert into public.churches (id, name, slug)
select pg_temp.fx(c, 'church'), 'Igreja Isolamento ' || c, 'isolamento-' || lower(c)
from (values ('A'), ('B')) as t (c);

insert into public.congregations (id, church_id, name, is_headquarters)
select pg_temp.fx(c, k.key), pg_temp.fx(c, 'church'), k.name, k.hq
from (values ('A'), ('B')) as t (c)
cross join (values ('sede', 'Sede', true), ('norte', 'Congregação Norte', false)) as k (key, name, hq);

insert into public.church_members (id, church_id, user_id, role, all_congregations)
select pg_temp.fx(church, 'm_' || role), church_id, user_id, role, role <> 'secretary'
from actors;

-- The dual member is a viewer in A and an admin in B.
insert into public.church_members (id, church_id, user_id, role, created_at) values
  (pg_temp.fx('A', 'm_dual'), pg_temp.fx('A', 'church'), pg_temp.fx('A', 'u_dual'), 'viewer', '2026-01-01'),
  (pg_temp.fx('B', 'm_dual'), pg_temp.fx('B', 'church'), pg_temp.fx('A', 'u_dual'), 'admin', '2026-02-01');

insert into public.church_member_congregations (church_id, member_id, congregation_id)
select pg_temp.fx(c, 'church'), pg_temp.fx(c, 'm_secretary'), pg_temp.fx(c, 'norte')
from (values ('A'), ('B')) as t (c);

update public.user_profiles p
set active_church_id = a.church_id
from actors a
where p.user_id = a.user_id;

update public.user_profiles
set active_church_id = pg_temp.fx('A', 'church')
where user_id = pg_temp.fx('A', 'u_dual');

insert into public.people (id, church_id, primary_congregation_id, full_name, birth_date, phone, email)
select pg_temp.fx(c, k.key), pg_temp.fx(c, 'church'), pg_temp.fx(c, k.congregation), k.name || ' ' || c,
       '1990-01-01', '(11) 90000-0000', k.key || '.isolamento@exemplo.test'
from (values ('A'), ('B')) as t (c)
cross join (
  values
    ('p1', 'sede', 'Aluno Isolamento Sede'),
    ('p2', 'norte', 'Aluna Isolamento Norte'),
    ('p3', 'sede', 'Professora Isolamento'),
    ('p4', 'norte', 'Pessoa Isolamento Norte')
) as k (key, congregation, name);

insert into public.person_religious_info (person_id, church_id, is_church_member, baptized)
select pg_temp.fx(c, k.key), pg_temp.fx(c, 'church'), true, false
from (values ('A'), ('B')) as t (c)
cross join (values ('p1'), ('p2')) as k (key);

insert into public.classes (id, church_id, congregation_id, name)
select pg_temp.fx(c, k.key), pg_temp.fx(c, 'church'), pg_temp.fx(c, k.congregation), k.name
from (values ('A'), ('B')) as t (c)
cross join (values ('c1', 'sede', 'Adultos Sede'), ('c2', 'norte', 'Adultos Norte')) as k (key, congregation, name);

insert into public.class_teachers (id, church_id, class_id, person_id, member_id)
select pg_temp.fx(c, k.key), pg_temp.fx(c, 'church'), pg_temp.fx(c, k.class), pg_temp.fx(c, 'p3'),
       case when k.with_login then pg_temp.fx(c, 'm_teacher') end
from (values ('A'), ('B')) as t (c)
cross join (values ('t1', 'c1', true), ('t2', 'c2', false)) as k (key, class, with_login);

insert into public.enrollments (id, church_id, person_id, class_id, started_on)
select pg_temp.fx(c, k.key), pg_temp.fx(c, 'church'), pg_temp.fx(c, k.person), pg_temp.fx(c, k.class), '2026-02-01'
from (values ('A'), ('B')) as t (c)
cross join (values ('e1', 'p1', 'c1'), ('e2', 'p2', 'c2')) as k (key, person, class);

-- Matrix: every case runs for the five roles of both churches. "own" targets rows of the
-- actor's church (active in the claim), "other" the same rows of the other church.
-- Expected per role (owner, admin, secretary, teacher, viewer): rows touched or SQLSTATE.

create temp table cases (id serial, tbl text, op text, target text, statement text, expected text[]);

insert into cases (tbl, op, target, statement, expected) values
  ('churches', 'select', 'own', $$select 1 from public.churches where id = '{church}'$$, '{1,1,1,1,1}'),
  ('churches', 'select', 'other', $$select 1 from public.churches where id = '{church}'$$, '{0,0,0,0,0}'),
  ('churches', 'insert', 'own', $$insert into public.churches (name, slug) values ('Igreja Intrusa', 'isolamento-intrusa')$$, '{42501,42501,42501,42501,42501}'),
  ('churches', 'update', 'own', $$update public.churches set name = 'Renomeada' where id = '{church}'$$, '{1,1,0,0,0}'),
  ('churches', 'update', 'other', $$update public.churches set name = 'Renomeada' where id = '{church}'$$, '{0,0,0,0,0}'),
  ('churches', 'delete', 'own', $$delete from public.churches where id = '{church}'$$, '{42501,42501,42501,42501,42501}'),

  ('congregations', 'select', 'own', $$select 1 from public.congregations where church_id = '{church}'$$, '{2,2,1,2,2}'),
  ('congregations', 'select', 'other', $$select 1 from public.congregations where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('congregations', 'insert', 'own', $$insert into public.congregations (church_id, name) values ('{church}', 'Nova')$$, '{1,1,42501,42501,42501}'),
  ('congregations', 'insert', 'other', $$insert into public.congregations (church_id, name) values ('{church}', 'Nova')$$, '{42501,42501,42501,42501,42501}'),
  ('congregations', 'update', 'own', $$update public.congregations set name = 'Renomeada' where id = '{norte}'$$, '{1,1,0,0,0}'),
  ('congregations', 'update', 'other', $$update public.congregations set name = 'Renomeada' where id = '{norte}'$$, '{0,0,0,0,0}'),
  ('congregations', 'delete', 'own', $$delete from public.congregations where id = '{norte}'$$, '{42501,42501,42501,42501,42501}'),

  ('church_members', 'select', 'own', $$select 1 from public.church_members where church_id = '{church}'$$, '{6,6,1,1,1}'),
  ('church_members', 'select', 'other', $$select 1 from public.church_members where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('church_members', 'insert', 'own', $$insert into public.church_members (church_id, user_id, role) values ('{church}', '{u_loose}', 'viewer')$$, '{1,1,42501,42501,42501}'),
  ('church_members', 'insert owner', 'own', $$insert into public.church_members (church_id, user_id, role) values ('{church}', '{u_loose}', 'owner')$$, '{1,42501,42501,42501,42501}'),
  ('church_members', 'insert', 'other', $$insert into public.church_members (church_id, user_id, role) values ('{church}', '{u_loose}', 'viewer')$$, '{42501,42501,42501,42501,42501}'),
  ('church_members', 'update', 'own', $$update public.church_members set all_congregations = false where id = '{m_viewer}'$$, '{1,1,0,0,0}'),
  ('church_members', 'update owner', 'own', $$update public.church_members set all_congregations = true where id = '{m_owner}'$$, '{0,0,0,0,0}'),
  ('church_members', 'update', 'other', $$update public.church_members set all_congregations = false where id = '{m_viewer}'$$, '{0,0,0,0,0}'),
  ('church_members', 'delete', 'own', $$delete from public.church_members where id = '{m_viewer}'$$, '{1,1,0,0,0}'),
  ('church_members', 'delete', 'other', $$delete from public.church_members where id = '{m_viewer}'$$, '{0,0,0,0,0}'),

  ('church_member_congregations', 'select', 'own', $$select 1 from public.church_member_congregations where church_id = '{church}'$$, '{1,1,1,0,0}'),
  ('church_member_congregations', 'select', 'other', $$select 1 from public.church_member_congregations where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('church_member_congregations', 'insert', 'own', $$insert into public.church_member_congregations (church_id, member_id, congregation_id) values ('{church}', '{m_viewer}', '{norte}')$$, '{1,1,42501,42501,42501}'),
  ('church_member_congregations', 'insert', 'other', $$insert into public.church_member_congregations (church_id, member_id, congregation_id) values ('{church}', '{m_viewer}', '{norte}')$$, '{42501,42501,42501,42501,42501}'),
  ('church_member_congregations', 'update', 'own', $$update public.church_member_congregations set congregation_id = '{sede}' where member_id = '{m_secretary}'$$, '{42501,42501,42501,42501,42501}'),
  ('church_member_congregations', 'delete', 'own', $$delete from public.church_member_congregations where member_id = '{m_secretary}'$$, '{1,1,0,0,0}'),
  ('church_member_congregations', 'delete', 'other', $$delete from public.church_member_congregations where member_id = '{m_secretary}'$$, '{0,0,0,0,0}'),

  ('people', 'select', 'own', $$select 1 from public.people where church_id = '{church}'$$, '{4,4,2,0,0}'),
  ('people', 'select', 'other', $$select 1 from public.people where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('people', 'insert', 'own', $$insert into public.people (church_id, primary_congregation_id, full_name) values ('{church}', '{norte}', 'Pessoa Nova')$$, '{1,1,1,42501,42501}'),
  ('people', 'insert', 'other', $$insert into public.people (church_id, primary_congregation_id, full_name) values ('{church}', '{norte}', 'Pessoa Nova')$$, '{42501,42501,42501,42501,42501}'),
  ('people', 'update', 'own', $$update public.people set notes = 'Atualizada' where id = '{p2}'$$, '{1,1,1,0,0}'),
  ('people', 'update', 'other', $$update public.people set notes = 'Atualizada' where id = '{p2}'$$, '{0,0,0,0,0}'),
  ('people', 'delete', 'own', $$delete from public.people where id = '{p4}'$$, '{42501,42501,42501,42501,42501}'),
  ('people', 'anonymize', 'own', $$select public.anonymize_person('{p4}')$$, '{1,1,1,42501,42501}'),
  ('people', 'anonymize', 'other', $$select public.anonymize_person('{p4}')$$, '{P0002,P0002,P0002,42501,42501}'),

  ('person_religious_info', 'select', 'own', $$select 1 from public.person_religious_info where church_id = '{church}'$$, '{2,2,1,0,0}'),
  ('person_religious_info', 'select', 'other', $$select 1 from public.person_religious_info where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('person_religious_info', 'insert', 'own', $$insert into public.person_religious_info (person_id, church_id, baptized) values ('{p4}', '{church}', false)$$, '{1,1,1,42501,42501}'),
  ('person_religious_info', 'insert', 'other', $$insert into public.person_religious_info (person_id, church_id, baptized) values ('{p4}', '{church}', false)$$, '{42501,42501,42501,42501,42501}'),
  ('person_religious_info', 'update', 'own', $$update public.person_religious_info set origin_church = 'Outra' where person_id = '{p2}'$$, '{1,1,1,0,0}'),
  ('person_religious_info', 'update', 'other', $$update public.person_religious_info set origin_church = 'Outra' where person_id = '{p2}'$$, '{0,0,0,0,0}'),
  ('person_religious_info', 'delete', 'own', $$delete from public.person_religious_info where person_id = '{p2}'$$, '{1,1,1,0,0}'),
  ('person_religious_info', 'delete', 'other', $$delete from public.person_religious_info where person_id = '{p2}'$$, '{0,0,0,0,0}'),

  ('classes', 'select', 'own', $$select 1 from public.classes where church_id = '{church}'$$, '{2,2,1,2,2}'),
  ('classes', 'select', 'other', $$select 1 from public.classes where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('classes', 'insert', 'own', $$insert into public.classes (church_id, congregation_id, name) values ('{church}', '{norte}', 'Turma Nova')$$, '{1,1,1,42501,42501}'),
  ('classes', 'insert', 'other', $$insert into public.classes (church_id, congregation_id, name) values ('{church}', '{norte}', 'Turma Nova')$$, '{42501,42501,42501,42501,42501}'),
  ('classes', 'update', 'own', $$update public.classes set room = 'Sala 9' where id = '{c2}'$$, '{1,1,1,0,0}'),
  ('classes', 'update', 'other', $$update public.classes set room = 'Sala 9' where id = '{c2}'$$, '{0,0,0,0,0}'),
  ('classes', 'delete', 'own', $$delete from public.classes where id = '{c2}'$$, '{42501,42501,42501,42501,42501}'),

  ('class_teachers', 'select', 'own', $$select 1 from public.class_teachers where church_id = '{church}'$$, '{2,2,1,2,2}'),
  ('class_teachers', 'select', 'other', $$select 1 from public.class_teachers where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('class_teachers', 'insert', 'own', $$insert into public.class_teachers (church_id, class_id, person_id) values ('{church}', '{c2}', '{p4}')$$, '{1,1,1,42501,42501}'),
  ('class_teachers', 'insert', 'other', $$insert into public.class_teachers (church_id, class_id, person_id) values ('{church}', '{c2}', '{p4}')$$, '{42501,42501,42501,42501,42501}'),
  ('class_teachers', 'update', 'own', $$update public.class_teachers set role = 'assistant' where id = '{t2}'$$, '{1,1,1,0,0}'),
  ('class_teachers', 'update', 'other', $$update public.class_teachers set role = 'assistant' where id = '{t2}'$$, '{0,0,0,0,0}'),
  ('class_teachers', 'delete', 'own', $$delete from public.class_teachers where id = '{t2}'$$, '{42501,42501,42501,42501,42501}'),

  ('enrollments', 'select', 'own', $$select 1 from public.enrollments where church_id = '{church}'$$, '{2,2,1,1,0}'),
  ('enrollments', 'select', 'other', $$select 1 from public.enrollments where church_id = '{church}'$$, '{0,0,0,0,0}'),
  ('enrollments', 'insert', 'own', $$insert into public.enrollments (church_id, person_id, class_id) values ('{church}', '{p4}', '{c2}')$$, '{1,1,1,42501,42501}'),
  ('enrollments', 'insert', 'other', $$insert into public.enrollments (church_id, person_id, class_id) values ('{church}', '{p4}', '{c2}')$$, '{42501,42501,42501,42501,42501}'),
  ('enrollments', 'update', 'own', $$update public.enrollments set started_on = started_on where id = '{e2}'$$, '{1,1,1,0,0}'),
  ('enrollments', 'update', 'other', $$update public.enrollments set started_on = started_on where id = '{e2}'$$, '{0,0,0,0,0}'),
  ('enrollments', 'delete', 'own', $$delete from public.enrollments where id = '{e2}'$$, '{42501,42501,42501,42501,42501}'),

  ('class_roster', 'select', 'own', $$select 1 from public.class_roster where church_id = '{church}'$$, '{0,0,0,1,0}'),
  ('class_roster', 'select', 'other', $$select 1 from public.class_roster where church_id = '{church}'$$, '{0,0,0,0,0}'),

  ('current_capabilities', 'call', 'own', $$select unnest(public.current_capabilities())$$, '{16,14,10,3,1}'),

  ('user_profiles', 'select', 'own', $$select 1 from public.user_profiles where user_id = '{self}'$$, '{1,1,1,1,1}'),
  ('user_profiles', 'select', 'other', $$select 1 from public.user_profiles where user_id = '{u_owner}'$$, '{0,0,0,0,0}'),
  ('user_profiles', 'insert', 'own', $$insert into public.user_profiles (user_id) values ('{u_loose}')$$, '{42501,42501,42501,42501,42501}'),
  ('user_profiles', 'update', 'own', $$update public.user_profiles set full_name = 'Nome Novo' where user_id = '{self}'$$, '{1,1,1,1,1}'),
  ('user_profiles', 'update', 'other', $$update public.user_profiles set full_name = 'Invadido' where user_id = '{u_owner}'$$, '{0,0,0,0,0}'),
  ('user_profiles', 'delete', 'own', $$delete from public.user_profiles where user_id = '{self}'$$, '{42501,42501,42501,42501,42501}');

select plan((select count(*)::int from cases) * (select count(*)::int from actors) + 93);

select is(
  pg_temp.attempt(
    'authenticated', m.user_id, m.church_id,
    pg_temp.render(m.statement, case m.target when 'own' then m.church else m.other end, m.user_id)
  ),
  m.expected[m.ord],
  format('%s %s: %s %s (%s)', m.church, m.role, m.tbl, m.op, m.target)
)
from (
  select a.church, a.other, a.role, a.ord, a.user_id, a.church_id, c.tbl, c.op, c.target, c.statement, c.expected
  from cases c
  cross join actors a
  order by c.id, a.church, a.ord
) as m;

-- Spoofed claim (each user pointing at the other church) and no active church

select is(
  pg_temp.attempt('authenticated', a.user_id, pg_temp.fx(a.other, 'church'), pg_temp.render(pg_temp.visible_rows(), a.other, a.user_id)),
  '0',
  format('%s %s: a claim for church %s exposes nothing', a.church, a.role, a.other)
)
from (select * from actors order by church, ord) as a;

select is(
  pg_temp.attempt('authenticated', a.user_id, pg_temp.fx(a.other, 'church'), 'select unnest(public.current_capabilities())'),
  '0',
  format('%s %s: a claim for church %s grants no capability', a.church, a.role, a.other)
)
from (select * from actors order by church, ord) as a;

select is(
  pg_temp.attempt(
    'authenticated', a.user_id, pg_temp.fx(a.other, 'church'),
    pg_temp.render($$insert into public.people (church_id, primary_congregation_id, full_name) values ('{church}', '{norte}', 'Forjada')$$, a.other, a.user_id)
  ),
  '42501',
  format('%s %s: a claim for church %s cannot write there', a.church, a.role, a.other)
)
from (select * from actors order by church, ord) as a;

select is(
  pg_temp.attempt('authenticated', a.user_id, null, pg_temp.render(pg_temp.visible_rows(), a.church, a.user_id)),
  '0',
  format('%s %s: without an active church nothing is visible', a.church, a.role)
)
from (select * from actors order by church, ord) as a;

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_owner'), pg_temp.fx('A', 'church'),
    pg_temp.render($$update public.user_profiles set active_church_id = '{church}' where user_id = '{self}'$$, 'B', pg_temp.fx('A', 'u_owner'))
  ),
  '42501',
  'a user cannot make active a church they do not belong to'
);

-- Switching the active church: the dual member is a viewer in A and an admin in B

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('A', 'church'), 'select unnest(public.current_capabilities())'),
  '1',
  'dual member with A active has the viewer capabilities'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('A', 'church'),
    pg_temp.render($$select 1 from public.people where church_id = '{church}'$$, 'B', null)
  ),
  '0',
  'dual member with A active sees no person of B'
);

select set_config(
  'request.jwt.claims',
  jsonb_build_object('sub', pg_temp.fx('A', 'u_dual'), 'role', 'authenticated', 'active_church_id', pg_temp.fx('A', 'church'))::text,
  true
);
set local role authenticated;

select lives_ok(
  $$update public.user_profiles set active_church_id = pg_temp.fx('B', 'church') where user_id = pg_temp.fx('A', 'u_dual')$$,
  'dual member switches the profile to B'
);

reset role;
select set_config('request.jwt.claims', '', true);

select is(
  app.custom_access_token_hook(jsonb_build_object('user_id', pg_temp.fx('A', 'u_dual'), 'claims', '{}'::jsonb))
    -> 'claims' ->> 'active_church_id',
  pg_temp.fx('B', 'church')::text,
  'after the switch the refreshed token carries B'
);

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('B', 'church'), 'select unnest(public.current_capabilities())'),
  '14',
  'with the B token the dual member has the admin capabilities'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('B', 'church'),
    pg_temp.render($$select 1 from public.people where church_id = '{church}'$$, 'B', null)
  ),
  '4',
  'with the B token the dual member reads the people of B'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('B', 'church'),
    pg_temp.render($$select 1 from public.classes where church_id = '{church}'$$, 'A', null)
  ),
  '0',
  'with the B token nothing of A is visible'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('B', 'church'),
    pg_temp.render($$insert into public.congregations (church_id, name) values ('{church}', 'Nova')$$, 'A', null)
  ),
  '42501',
  'admin rights in B do not reach A'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('A', 'church'),
    pg_temp.render($$select 1 from public.people where church_id = '{church}'$$, 'B', null)
  ),
  '0',
  'a token still carrying A keeps the viewer scope of A until it is refreshed'
);

update public.church_members set status = 'suspended' where id = pg_temp.fx('B', 'm_dual');

select is(
  app.custom_access_token_hook(jsonb_build_object('user_id', pg_temp.fx('A', 'u_dual'), 'claims', '{}'::jsonb))
    -> 'claims' ->> 'active_church_id',
  pg_temp.fx('A', 'church')::text,
  'suspended in B, the next token falls back to A'
);

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('B', 'church'), pg_temp.render(pg_temp.visible_rows(), 'B', pg_temp.fx('A', 'u_dual'))),
  '0',
  'suspended in B, the old B token exposes nothing'
);

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_dual'), pg_temp.fx('B', 'church'), 'select unnest(public.current_capabilities())'),
  '0',
  'suspended in B, the old B token grants no capability'
);

-- Revoked membership (row deleted) with a token issued before

insert into public.church_members (id, church_id, user_id, role)
values (pg_temp.fx('A', 'm_revoked'), pg_temp.fx('A', 'church'), pg_temp.fx('A', 'u_revoked'), 'admin');

update public.user_profiles set active_church_id = pg_temp.fx('A', 'church') where user_id = pg_temp.fx('A', 'u_revoked');

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_revoked'), pg_temp.fx('A', 'church'),
    pg_temp.render($$select 1 from public.people where church_id = '{church}'$$, 'A', null)
  ),
  '4',
  'before the revocation the admin reads the people of A'
);

delete from public.church_members where id = pg_temp.fx('A', 'm_revoked');

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_revoked'), pg_temp.fx('A', 'church'), pg_temp.render(pg_temp.visible_rows(), 'A', pg_temp.fx('A', 'u_revoked'))),
  '0',
  'revoked: the old token exposes no tenant row'
);

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_revoked'), pg_temp.fx('A', 'church'), 'select 1 from public.churches'),
  '0',
  'revoked: the church leaves the church list'
);

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_revoked'), pg_temp.fx('A', 'church'), 'select unnest(public.current_capabilities())'),
  '0',
  'revoked: no capability left'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_revoked'), pg_temp.fx('A', 'church'),
    pg_temp.render($$insert into public.people (church_id, primary_congregation_id, full_name) values ('{church}', '{norte}', 'Depois')$$, 'A', null)
  ),
  '42501',
  'revoked: cannot insert'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_revoked'), pg_temp.fx('A', 'church'),
    pg_temp.render($$update public.people set notes = 'Depois' where id = '{p2}'$$, 'A', null)
  ),
  '0',
  'revoked: cannot update'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_revoked'), pg_temp.fx('A', 'church'),
    pg_temp.render($$select public.anonymize_person('{p2}')$$, 'A', null)
  ),
  '42501',
  'revoked: cannot anonymize'
);

select is(
  app.custom_access_token_hook(jsonb_build_object('user_id', pg_temp.fx('A', 'u_revoked'), 'claims', '{}'::jsonb))
    -> 'claims' -> 'active_church_id',
  'null'::jsonb,
  'revoked: the next token carries no church'
);

-- Suspended teacher with a token issued before

update public.church_members set status = 'suspended' where id = pg_temp.fx('A', 'm_teacher');

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('A', 'u_teacher'), pg_temp.fx('A', 'church'),
    pg_temp.render($$select 1 from public.class_roster where church_id = '{church}'$$, 'A', null)
  ),
  '0',
  'suspended teacher: the roster is empty'
);

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_teacher'), pg_temp.fx('A', 'church'), pg_temp.render(pg_temp.visible_rows(), 'A', pg_temp.fx('A', 'u_teacher'))),
  '0',
  'suspended teacher: no tenant row'
);

select is(
  pg_temp.attempt('authenticated', pg_temp.fx('A', 'u_teacher'), pg_temp.fx('A', 'church'), 'select unnest(public.current_capabilities())'),
  '0',
  'suspended teacher: no capability left'
);

select is(
  app.custom_access_token_hook(jsonb_build_object('user_id', pg_temp.fx('A', 'u_teacher'), 'claims', '{}'::jsonb))
    -> 'claims' -> 'active_church_id',
  'null'::jsonb,
  'suspended teacher: the next token carries no church'
);

select is(
  pg_temp.attempt(
    'authenticated', pg_temp.fx('B', 'u_teacher'), pg_temp.fx('B', 'church'),
    pg_temp.render($$select 1 from public.class_roster where church_id = '{church}'$$, 'B', null)
  ),
  '1',
  'the teacher of B is not affected by the suspension in A'
);

-- Composite FKs refuse references to another church even without RLS (as postgres)

select throws_ok(
  $$insert into public.church_member_congregations (church_id, member_id, congregation_id)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('B', 'm_viewer'), pg_temp.fx('A', 'norte'))$$,
  '23503', null, 'church_member_congregations: member of another church'
);

select throws_ok(
  $$insert into public.church_member_congregations (church_id, member_id, congregation_id)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('A', 'm_viewer'), pg_temp.fx('B', 'norte'))$$,
  '23503', null, 'church_member_congregations: congregation of another church'
);

select throws_ok(
  $$insert into public.people (church_id, primary_congregation_id, full_name)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('B', 'norte'), 'Cruzada')$$,
  '23503', null, 'people: congregation of another church'
);

select throws_ok(
  $$insert into public.people (church_id, full_name, guardian_person_id)
    values (pg_temp.fx('A', 'church'), 'Cruzada', pg_temp.fx('B', 'p1'))$$,
  '23503', null, 'people: guardian of another church'
);

select throws_ok(
  $$insert into public.people (church_id, full_name, invited_by_person_id)
    values (pg_temp.fx('A', 'church'), 'Cruzada', pg_temp.fx('B', 'p1'))$$,
  '23503', null, 'people: inviter of another church'
);

select throws_ok(
  $$update public.people set primary_congregation_id = pg_temp.fx('B', 'norte') where id = pg_temp.fx('A', 'p4')$$,
  '23503', null, 'people: moving a person to a congregation of another church'
);

select throws_ok(
  $$update public.people set church_id = pg_temp.fx('B', 'church') where id = pg_temp.fx('A', 'p4')$$,
  '23503', null, 'people: moving a person to another church'
);

select throws_ok(
  $$insert into public.person_religious_info (person_id, church_id)
    values (pg_temp.fx('B', 'p4'), pg_temp.fx('A', 'church'))$$,
  '23503', null, 'person_religious_info: person of another church'
);

select throws_ok(
  $$insert into public.classes (church_id, congregation_id, name)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('B', 'norte'), 'Cruzada')$$,
  '23503', null, 'classes: congregation of another church'
);

select throws_ok(
  $$insert into public.class_teachers (church_id, class_id, person_id)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('B', 'c2'), pg_temp.fx('A', 'p4'))$$,
  '23503', null, 'class_teachers: class of another church'
);

select throws_ok(
  $$insert into public.class_teachers (church_id, class_id, person_id)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('A', 'c2'), pg_temp.fx('B', 'p4'))$$,
  '23503', null, 'class_teachers: person of another church'
);

select throws_ok(
  $$update public.class_teachers set member_id = pg_temp.fx('B', 'm_teacher') where id = pg_temp.fx('A', 't2')$$,
  '23503', null, 'class_teachers: login of another church'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('B', 'p4'), pg_temp.fx('A', 'c2'))$$,
  '23503', null, 'enrollments: person of another church'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values (pg_temp.fx('A', 'church'), pg_temp.fx('A', 'p4'), pg_temp.fx('B', 'c2'))$$,
  '23503', null, 'enrollments: class of another church'
);

-- Anonymous: nothing in public is reachable

select is(
  pg_temp.attempt('anon', null, null, s.statement),
  '42501',
  format('anon: %s', s.statement)
)
from (
  values
    ('select 1 from public.churches'),
    ('select 1 from public.congregations'),
    ('select 1 from public.church_members'),
    ('select 1 from public.church_member_congregations'),
    ('select 1 from public.user_profiles'),
    ('select 1 from public.people'),
    ('select 1 from public.person_religious_info'),
    ('select 1 from public.classes'),
    ('select 1 from public.class_teachers'),
    ('select 1 from public.enrollments'),
    ('select 1 from public.class_roster'),
    ('select public.current_capabilities()'),
    (format('select public.anonymize_person(%L)', pg_temp.fx('A', 'p4')))
) as s (statement);

select * from finish();
rollback;
