begin;
select plan(39);

-- Fixtures (fictional). Church A: HQ + one congregation. Church B: HQ only.

insert into auth.users (id, email, raw_user_meta_data) values
  ('a0000000-0000-4000-8000-0000000000a1', 'dono.a@exemplo.test', '{"full_name": "  Dono Exemplo A "}'),
  ('a0000000-0000-4000-8000-0000000000a2', 'admin.a@exemplo.test', '{}'),
  ('a0000000-0000-4000-8000-0000000000a3', 'secretaria.a@exemplo.test', '{}'),
  ('a0000000-0000-4000-8000-0000000000a4', 'leitor.a@exemplo.test', '{}'),
  ('a0000000-0000-4000-8000-0000000000a5', 'suspenso.a@exemplo.test', '{}'),
  ('b0000000-0000-4000-8000-0000000000b1', 'dono.b@exemplo.test', '{}'),
  ('c0000000-0000-4000-8000-0000000000c1', 'duas.igrejas@exemplo.test', '{}'),
  ('d0000000-0000-4000-8000-0000000000d1', 'sem.igreja@exemplo.test', '{}');

insert into public.churches (id, name, slug, created_at, updated_at) values
  ('a0000000-0000-4000-8000-000000000000', 'Igreja Exemplo A', 'igreja-exemplo-a', '2026-01-01', '2026-01-01'),
  ('b0000000-0000-4000-8000-000000000000', 'Igreja Exemplo B', 'igreja-exemplo-b', '2026-01-01', '2026-01-01');

insert into public.congregations (id, church_id, name, is_headquarters) values
  ('a0000000-0000-4000-8000-0000000000c1', 'a0000000-0000-4000-8000-000000000000', 'Sede', true),
  ('a0000000-0000-4000-8000-0000000000c2', 'a0000000-0000-4000-8000-000000000000', 'Congregação Norte', false),
  ('b0000000-0000-4000-8000-0000000000c1', 'b0000000-0000-4000-8000-000000000000', 'Sede', true);

insert into public.church_members (id, church_id, user_id, role, all_congregations, status) values
  ('e0000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a1', 'owner', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a2', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a2', 'admin', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a3', 'secretary', false, 'active'),
  ('e0000000-0000-4000-8000-0000000000a4', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a4', 'viewer', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a5', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a5', 'admin', true, 'suspended'),
  ('e0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000b1', 'owner', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000c1', 'a0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-0000000000c1', 'teacher', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000c2', 'b0000000-0000-4000-8000-000000000000', 'c0000000-0000-4000-8000-0000000000c1', 'secretary', true, 'active');

insert into public.church_member_congregations (church_id, member_id, congregation_id) values
  ('a0000000-0000-4000-8000-000000000000', 'e0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-0000000000c2');

-- Profiles and capabilities

select is(
  (select count(*)::int from public.user_profiles where user_id::text ~ '^[a-d]0000000-'),
  8,
  'a profile is created for every new auth user'
);

select is(
  (select full_name from public.user_profiles where user_id = 'a0000000-0000-4000-8000-0000000000a1'),
  'Dono Exemplo A',
  'profile full_name comes trimmed from user metadata'
);

select results_eq(
  'select role, count(*)::int from app.role_capabilities group by role order by role',
  $$values ('admin', 14), ('owner', 16), ('secretary', 10), ('teacher', 3), ('viewer', 1)$$,
  'role_capabilities is seeded for every role'
);

select ok(
  not exists (
    select 1 from app.role_capabilities
    where role = 'admin' and capability in ('church.billing', 'members.manage_owners')
  ),
  'admin has neither church.billing nor members.manage_owners'
);

-- Owner of A, active church A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);
set local role authenticated;

select results_eq(
  'select name from public.churches',
  $$values ('Igreja Exemplo A')$$,
  'owner A sees only church A'
);

select is(
  (select count(*)::int from public.congregations),
  2,
  'owner A sees both congregations of A'
);

select is(
  (select count(*)::int from public.congregations where church_id = 'b0000000-0000-4000-8000-000000000000'),
  0,
  'owner A sees no congregation of B'
);

select is(
  (select count(*)::int from public.church_members where church_id = 'b0000000-0000-4000-8000-000000000000'),
  0,
  'owner A sees no member of B'
);

select is(
  (select count(*)::int from public.user_profiles),
  1,
  'a user sees only their own profile'
);

select throws_ok(
  $$insert into public.congregations (church_id, name) values ('b0000000-0000-4000-8000-000000000000', 'Intrusa')$$,
  '42501',
  null,
  'owner A cannot create a congregation in B'
);

select lives_ok(
  $$insert into public.congregations (church_id, name) values ('a0000000-0000-4000-8000-000000000000', 'Congregação Sul')$$,
  'owner A creates a congregation in A'
);

select throws_ok(
  $$insert into public.congregations (church_id, name, is_headquarters) values ('a0000000-0000-4000-8000-000000000000', 'Outra Sede', true)$$,
  '23505',
  null,
  'a church has a single headquarters'
);

select throws_ok(
  $$insert into public.church_member_congregations (church_id, member_id, congregation_id)
    values ('a0000000-0000-4000-8000-000000000000', 'e0000000-0000-4000-8000-0000000000a3', 'b0000000-0000-4000-8000-0000000000c1')$$,
  '23503',
  null,
  'composite FK blocks scoping a member of A to a congregation of B'
);

select throws_ok(
  $$insert into public.church_member_congregations (church_id, member_id, congregation_id)
    values ('b0000000-0000-4000-8000-000000000000', 'e0000000-0000-4000-8000-0000000000c2', 'b0000000-0000-4000-8000-0000000000c1')$$,
  '42501',
  null,
  'owner A cannot write member scopes of B'
);

select lives_ok(
  $$insert into public.church_members (church_id, user_id, role)
    values ('a0000000-0000-4000-8000-000000000000', 'd0000000-0000-4000-8000-0000000000d1', 'owner')$$,
  'owner A adds a co-owner'
);

select throws_ok(
  $$update public.user_profiles set active_church_id = 'b0000000-0000-4000-8000-000000000000'
    where user_id = 'a0000000-0000-4000-8000-0000000000a1'$$,
  '42501',
  null,
  'a user cannot activate a church they do not belong to'
);

select lives_ok(
  $$update public.user_profiles set active_church_id = 'a0000000-0000-4000-8000-000000000000'
    where user_id = 'a0000000-0000-4000-8000-0000000000a1'$$,
  'a user activates a church they belong to'
);

select throws_ok('select * from app.audit_log', '42501', null, 'authenticated cannot read app.audit_log');
select throws_ok('select * from app.role_capabilities', '42501', null, 'authenticated cannot read app.role_capabilities');
select throws_ok(
  $$delete from public.churches where id = 'a0000000-0000-4000-8000-000000000000'$$,
  '42501',
  null,
  'churches cannot be deleted through the API'
);

-- Spoofed claim: owner A pointing at B

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "active_church_id": "b0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.congregations),
  0,
  'a claim for a church without membership exposes nothing'
);

select is(
  (select count(*)::int from public.church_members),
  1,
  'with a foreign claim a user still sees only their own memberships'
);

-- No active church

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated"}', true);

select is(
  (select count(*)::int from public.congregations),
  0,
  'without an active church no congregation is visible'
);

-- Admin of A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a2", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.church_members),
  7,
  'admin A sees every member of A and none of B'
);

select throws_ok(
  $$update public.church_members set role = 'owner' where id = 'e0000000-0000-4000-8000-0000000000a4'$$,
  '42501',
  null,
  'admin cannot promote someone to owner'
);

update public.church_members set role = 'owner' where id = 'e0000000-0000-4000-8000-0000000000a2';
update public.church_members set role = 'viewer' where id = 'e0000000-0000-4000-8000-0000000000a1';

select results_eq(
  $$select role from public.church_members
    where id in ('e0000000-0000-4000-8000-0000000000a1', 'e0000000-0000-4000-8000-0000000000a2') order by id$$,
  $$values ('owner'), ('admin')$$,
  'admin can change neither their own row nor an owner row'
);

update public.churches set name = 'Igreja Exemplo A (renomeada)' where id = 'a0000000-0000-4000-8000-000000000000';

-- Secretary of A, scoped to Congregação Norte

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a3", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select results_eq(
  'select name from public.congregations',
  $$values ('Congregação Norte')$$,
  'scoped secretary sees only the congregations in scope'
);

select results_eq(
  'select user_id from public.church_members',
  $$values ('a0000000-0000-4000-8000-0000000000a3'::uuid)$$,
  'secretary sees only their own membership'
);

select is(
  (select count(*)::int from public.church_member_congregations),
  1,
  'secretary sees their own scope rows'
);

select throws_ok(
  $$insert into public.church_members (church_id, user_id, role)
    values ('a0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000b1', 'viewer')$$,
  '42501',
  null,
  'secretary cannot add members'
);

select throws_ok(
  $$insert into public.congregations (church_id, name) values ('a0000000-0000-4000-8000-000000000000', 'Nova')$$,
  '42501',
  null,
  'secretary cannot create congregations'
);

-- Viewer of A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a4", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

update public.churches set name = 'Hackeada' where id = 'a0000000-0000-4000-8000-000000000000';

select is(
  (select count(*)::int from public.church_member_congregations),
  0,
  'viewer sees no scope rows of others'
);

-- Suspended admin of A, token still valid

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a5", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.churches) + (select count(*)::int from public.congregations),
  0,
  'a suspended member loses access immediately despite a valid token'
);

-- Member of both churches (teacher in A, secretary in B)

select set_config('request.jwt.claims', '{"sub": "c0000000-0000-4000-8000-0000000000c1", "role": "authenticated", "active_church_id": "b0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.churches),
  2,
  'a member of two churches lists both (church switcher)'
);

select results_eq(
  'select church_id from public.congregations',
  $$values ('b0000000-0000-4000-8000-000000000000'::uuid)$$,
  'with B active, only congregations of B are visible'
);

-- Anonymous

reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok('select * from public.churches', '42501', null, 'anon cannot read churches');

reset role;

-- Effects checked as postgres

select results_eq(
  $$select name, updated_at > created_at from public.churches where id = 'a0000000-0000-4000-8000-000000000000'$$,
  $$values ('Igreja Exemplo A (renomeada)', true)$$,
  'admin rename applied, viewer rename ignored, updated_at bumped'
);

select results_eq(
  $$select action, actor_id, record_id is not null from app.audit_log
    where table_name = 'church_members' and new_data ->> 'user_id' = 'd0000000-0000-4000-8000-0000000000d1'$$,
  $$values ('insert', 'a0000000-0000-4000-8000-0000000000a1'::uuid, true)$$,
  'church_members insert is audited with the acting user'
);

select results_eq(
  $$select action, record_id from app.audit_log where table_name = 'church_member_congregations'$$,
  $$values ('insert', 'e0000000-0000-4000-8000-0000000000a3'::uuid)$$,
  'church_member_congregations writes are audited by member_id'
);

select * from finish();
rollback;
