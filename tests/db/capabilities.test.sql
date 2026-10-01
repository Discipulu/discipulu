begin;
select plan(8);

-- Fixtures (fictional). Church A and church B, one member per case.

insert into auth.users (id, email) values
  ('a0000000-0000-4000-8000-00000000ca01', 'dono.cap@exemplo.test'),
  ('a0000000-0000-4000-8000-00000000ca02', 'professor.cap@exemplo.test'),
  ('a0000000-0000-4000-8000-00000000ca03', 'leitor.cap@exemplo.test'),
  ('a0000000-0000-4000-8000-00000000ca04', 'suspenso.cap@exemplo.test');

insert into public.churches (id, name, slug) values
  ('a0000000-0000-4000-8000-0000000ca000', 'Igreja Exemplo A', 'igreja-exemplo-cap-a'),
  ('b0000000-0000-4000-8000-0000000ca000', 'Igreja Exemplo B', 'igreja-exemplo-cap-b');

insert into public.church_members (church_id, user_id, role, status) values
  ('a0000000-0000-4000-8000-0000000ca000', 'a0000000-0000-4000-8000-00000000ca01', 'owner', 'active'),
  ('a0000000-0000-4000-8000-0000000ca000', 'a0000000-0000-4000-8000-00000000ca02', 'teacher', 'active'),
  ('a0000000-0000-4000-8000-0000000ca000', 'a0000000-0000-4000-8000-00000000ca03', 'viewer', 'active'),
  ('a0000000-0000-4000-8000-0000000ca000', 'a0000000-0000-4000-8000-00000000ca04', 'admin', 'suspended');

set local role authenticated;

-- Must match the Capability type in src/lib/auth/capabilities.ts.
select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-00000000ca01", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-0000000ca000"}', true);
select is(
  public.current_capabilities(),
  array[
    'attendance.record', 'audit.read', 'church.billing', 'church.manage', 'classes.manage',
    'congregations.manage', 'enrollments.manage', 'members.manage', 'members.manage_owners',
    'people.export', 'people.read', 'people.read_roster', 'people.read_sensitive', 'people.write',
    'reports.read', 'sunday.close'
  ],
  'owner gets every capability, sorted'
);

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-00000000ca02", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-0000000ca000"}', true);
select is(
  public.current_capabilities(),
  array['attendance.record', 'people.read_roster', 'reports.read'],
  'teacher gets attendance, roster and reports'
);

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-00000000ca03", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-0000000ca000"}', true);
select is(public.current_capabilities(), array['reports.read'], 'viewer only gets reports.read');

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-00000000ca04", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-0000000ca000"}', true);
select is(public.current_capabilities(), '{}'::text[], 'suspended member gets nothing even with a valid claim');

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-00000000ca01", "role": "authenticated", "active_church_id": "b0000000-0000-4000-8000-0000000ca000"}', true);
select is(public.current_capabilities(), '{}'::text[], 'spoofed claim for another church gets nothing');

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-00000000ca01", "role": "authenticated"}', true);
select is(public.current_capabilities(), '{}'::text[], 'no active church gets nothing');

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-00000000ca01", "role": "authenticated", "active_church_id": ""}', true);
select is(public.current_capabilities(), '{}'::text[], 'empty active church claim gets nothing');

reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;
select throws_ok('select public.current_capabilities()', '42501', null, 'anon cannot call current_capabilities');
reset role;

select * from finish();
rollback;
