begin;
select plan(42);

-- Fixtures (fictional). Church A: HQ + Congregação Norte, religious fields on.
-- Church B: HQ only, religious fields off.

insert into auth.users (id, email) values
  ('a0000000-0000-4000-8000-0000000000a1', 'dono.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a3', 'secretaria.norte.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a4', 'leitor.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a5', 'suspenso.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a6', 'professor.a@exemplo.test'),
  ('b0000000-0000-4000-8000-0000000000b1', 'dono.b@exemplo.test');

insert into public.churches (id, name, slug, religious_fields_enabled) values
  ('a0000000-0000-4000-8000-000000000000', 'Igreja Exemplo A', 'igreja-exemplo-a', true),
  ('b0000000-0000-4000-8000-000000000000', 'Igreja Exemplo B', 'igreja-exemplo-b', false);

insert into public.congregations (id, church_id, name, is_headquarters) values
  ('a0000000-0000-4000-8000-0000000000c1', 'a0000000-0000-4000-8000-000000000000', 'Sede', true),
  ('a0000000-0000-4000-8000-0000000000c2', 'a0000000-0000-4000-8000-000000000000', 'Congregação Norte', false),
  ('b0000000-0000-4000-8000-0000000000c1', 'b0000000-0000-4000-8000-000000000000', 'Sede', true);

insert into public.church_members (id, church_id, user_id, role, all_congregations, status) values
  ('e0000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a1', 'owner', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a3', 'secretary', false, 'active'),
  ('e0000000-0000-4000-8000-0000000000a4', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a4', 'viewer', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a5', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a5', 'admin', true, 'suspended'),
  ('e0000000-0000-4000-8000-0000000000a6', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a6', 'teacher', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000b1', 'owner', true, 'active');

insert into public.church_member_congregations (church_id, member_id, congregation_id) values
  ('a0000000-0000-4000-8000-000000000000', 'e0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-0000000000c2');

insert into public.people (id, church_id, primary_congregation_id, full_name, birth_date, created_at, updated_at) values
  ('f0000000-0000-4000-8000-0000000000a2', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c2', 'João Exemplo Norte', '1985-03-02', '2026-01-01', '2026-01-01'),
  ('f0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-000000000000', null, 'Pessoa Exemplo Sem Congregação', null, '2026-01-01', '2026-01-01'),
  ('f0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000c1', 'Pessoa Exemplo B', null, '2026-01-01', '2026-01-01');

insert into public.people (
  id, church_id, primary_congregation_id, full_name, birth_date, gender, phone, email,
  address_line, city, state, invited_by_person_id, notes
) values (
  'f0000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-000000000000',
  'a0000000-0000-4000-8000-0000000000c1', '  Maria  JOSÉ da Conceição ', '1990-05-17', 'female',
  '(11) 90000-0001', 'maria@exemplo.test', 'Rua Exemplo, 1', 'Cidade Exemplo', 'SP',
  'f0000000-0000-4000-8000-0000000000a2', 'Observação fictícia'
);

insert into public.person_religious_info (person_id, church_id, is_church_member, baptized, baptism_date) values
  ('f0000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-000000000000', true, true, '2005-12-25'),
  ('f0000000-0000-4000-8000-0000000000a2', 'a0000000-0000-4000-8000-000000000000', true, false, null),
  ('f0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', false, false, null);

-- Schema

select is(
  (select search_name from public.people where id = 'f0000000-0000-4000-8000-0000000000a1'),
  'maria jose da conceicao',
  'search_name is unaccented, lowercased and whitespace-collapsed'
);

select has_index('public', 'people', 'people_duplicate_idx', array['church_id', 'search_name', 'birth_date'], 'duplicate warning index exists');

select ok(
  not exists (select 1 from app.role_capabilities where role = 'teacher' and capability = 'people.read'),
  'teacher has no people.read (reads students through the class roster)'
);

-- Owner of A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);
set local role authenticated;

select results_eq(
  'select id from public.people order by id',
  $$values ('f0000000-0000-4000-8000-0000000000a1'::uuid), ('f0000000-0000-4000-8000-0000000000a2'), ('f0000000-0000-4000-8000-0000000000a3')$$,
  'owner A sees every person of A (with or without congregation) and none of B'
);

select is(
  (select count(*)::int from public.person_religious_info),
  2,
  'owner A sees the religious info of A only'
);

select throws_ok(
  $$insert into public.people (church_id, full_name) values ('b0000000-0000-4000-8000-000000000000', 'Intrusa')$$,
  '42501',
  null,
  'owner A cannot create a person in B'
);

select throws_ok(
  $$insert into public.people (church_id, primary_congregation_id, full_name)
    values ('a0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000c1', 'Cruzada')$$,
  '23503',
  null,
  'composite FK blocks a person of A in a congregation of B'
);

select throws_ok(
  $$insert into public.people (church_id, full_name, guardian_person_id)
    values ('a0000000-0000-4000-8000-000000000000', 'Criança Exemplo', 'f0000000-0000-4000-8000-0000000000b1')$$,
  '23503',
  null,
  'composite FK blocks a guardian from another church'
);

select throws_ok(
  $$insert into public.people (church_id, full_name) values ('a0000000-0000-4000-8000-000000000000', '   ')$$,
  '23514',
  null,
  'a person needs a name'
);

select throws_ok(
  $$insert into public.people (church_id, full_name, anonymized_at)
    values ('a0000000-0000-4000-8000-000000000000', 'Fantasma', now())$$,
  '42501',
  null,
  'anonymized_at cannot be set through the API'
);

select throws_ok(
  $$delete from public.people where id = 'f0000000-0000-4000-8000-0000000000a3'$$,
  '42501',
  null,
  'people cannot be deleted through the API'
);

update public.people set phone = '(11) 90000-0003' where id = 'f0000000-0000-4000-8000-0000000000a3';

select throws_ok(
  $$insert into public.person_religious_info (person_id, church_id, baptized)
    values ('f0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', true)$$,
  '42501',
  null,
  'owner A cannot write religious info in B'
);

-- Spoofed claim: owner A pointing at B

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "active_church_id": "b0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.people) + (select count(*)::int from public.person_religious_info),
  0,
  'a claim for a church without membership exposes no person'
);

-- Secretary of A scoped to Congregação Norte

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a3", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select results_eq(
  'select id from public.people',
  $$values ('f0000000-0000-4000-8000-0000000000a2'::uuid)$$,
  'scoped secretary sees only people of the congregations in scope'
);

select results_eq(
  'select person_id from public.person_religious_info',
  $$values ('f0000000-0000-4000-8000-0000000000a2'::uuid)$$,
  'scoped secretary sees religious info only of people in scope'
);

select lives_ok(
  $$insert into public.people (church_id, primary_congregation_id, full_name)
    values ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c2', 'Nova Pessoa Norte')
    returning id$$,
  'scoped secretary creates a person in scope and reads it back (insert ... returning)'
);

select throws_ok(
  $$insert into public.people (church_id, primary_congregation_id, full_name)
    values ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Pessoa Sede')$$,
  '42501',
  null,
  'scoped secretary cannot create a person outside the scope'
);

select throws_ok(
  $$insert into public.people (church_id, full_name) values ('a0000000-0000-4000-8000-000000000000', 'Sem Congregação')$$,
  '42501',
  null,
  'scoped secretary cannot create a person without congregation'
);

select throws_ok(
  $$update public.people set primary_congregation_id = 'a0000000-0000-4000-8000-0000000000c1'
    where id = 'f0000000-0000-4000-8000-0000000000a2'$$,
  '42501',
  null,
  'scoped secretary cannot move a person out of the scope'
);

update public.people set notes = 'Alterada' where id = 'f0000000-0000-4000-8000-0000000000a3';

select lives_ok(
  $$update public.person_religious_info set baptized = true, baptism_date = '2020-01-12'
    where person_id = 'f0000000-0000-4000-8000-0000000000a2'$$,
  'scoped secretary updates religious info of a person in scope'
);

select throws_ok(
  $$insert into public.person_religious_info (person_id, church_id, baptized)
    values ('f0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-000000000000', true)$$,
  '42501',
  null,
  'scoped secretary cannot write religious info of a person outside the scope'
);

select throws_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a1')$$,
  'P0002',
  null,
  'scoped secretary cannot anonymize a person outside the scope'
);

-- Teacher of A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a6", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.people) + (select count(*)::int from public.person_religious_info),
  0,
  'teacher reads neither people nor religious info directly'
);

select throws_ok(
  $$insert into public.people (church_id, full_name) values ('a0000000-0000-4000-8000-000000000000', 'Aluno')$$,
  '42501',
  null,
  'teacher cannot create people'
);

select throws_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a2')$$,
  '42501',
  null,
  'teacher cannot anonymize people'
);

-- Viewer and suspended admin of A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a4", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is((select count(*)::int from public.people), 0, 'viewer reads no people');

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a5", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is((select count(*)::int from public.people), 0, 'a suspended member reads no people despite a valid token');

-- Owner of B: religious fields disabled

select set_config('request.jwt.claims', '{"sub": "b0000000-0000-4000-8000-0000000000b1", "role": "authenticated", "active_church_id": "b0000000-0000-4000-8000-000000000000"}', true);

select results_eq(
  'select id from public.people',
  $$values ('f0000000-0000-4000-8000-0000000000b1'::uuid)$$,
  'owner B sees only people of B'
);

select is(
  (select count(*)::int from public.person_religious_info),
  0,
  'religious info is hidden when the church disables religious fields'
);

select is_empty(
  $$update public.person_religious_info set is_church_member = true where person_id = 'f0000000-0000-4000-8000-0000000000b1' returning person_id$$,
  'religious info cannot be written when the church disables religious fields'
);

select throws_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a1')$$,
  'P0002',
  null,
  'owner B cannot anonymize a person of A'
);

-- Anonymization by owner of A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select lives_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a1')$$,
  'owner A anonymizes a person'
);

select lives_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a1')$$,
  'anonymizing twice is a no-op'
);

update public.people set full_name = 'Reidentificada' where id = 'f0000000-0000-4000-8000-0000000000a1';

select is(
  (select count(*)::int from public.people where id = 'f0000000-0000-4000-8000-0000000000a1'),
  1,
  'an anonymized person stays visible (history and statistics)'
);

-- Anonymous

reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok('select * from public.people', '42501', null, 'anon cannot read people');
select throws_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a2')$$,
  '42501',
  null,
  'anon cannot call anonymize_person'
);

reset role;

-- Effects checked as postgres

select results_eq(
  $$select full_name, search_name, birth_date, gender, phone, email, address_line, city, state,
           invited_by_person_id, notes, anonymized_at is not null
    from public.people where id = 'f0000000-0000-4000-8000-0000000000a1'$$,
  $$values (null::text, null::text, '1990-01-01'::date, 'female'::text, null::text, null::text,
            null::text, null::text, null::text, null::uuid, null::text, true)$$,
  'anonymization erases identity and contacts, keeps gender and the birth year'
);

select is(
  (select count(*)::int from public.person_religious_info where person_id = 'f0000000-0000-4000-8000-0000000000a1'),
  0,
  'anonymization removes religious info'
);

select is(
  (
    select count(*)::int from app.audit_log
    where record_id = 'f0000000-0000-4000-8000-0000000000a1'
      and concat(old_data::text, new_data::text) ~* 'maria|90000-0001|exemplo\.test|2005-12-25|rua exemplo'
  ),
  0,
  'no audit entry keeps erased data of an anonymized person'
);

select results_eq(
  $$select actor_id from app.audit_log
    where table_name = 'people' and record_id = 'f0000000-0000-4000-8000-0000000000a1'
      and new_data ->> 'anonymized_at' is not null$$,
  $$values ('a0000000-0000-4000-8000-0000000000a1'::uuid)$$,
  'the anonymization is audited with the acting user'
);

select results_eq(
  $$select phone, notes, updated_at > created_at from public.people where id = 'f0000000-0000-4000-8000-0000000000a3'$$,
  $$values ('(11) 90000-0003'::text, null::text, true)$$,
  'owner update applied, out-of-scope update ignored, updated_at bumped'
);

select results_eq(
  $$select action, record_id, actor_id from app.audit_log
    where table_name = 'person_religious_info' and action = 'update'$$,
  $$values ('update', 'f0000000-0000-4000-8000-0000000000a2'::uuid, 'a0000000-0000-4000-8000-0000000000a3'::uuid)$$,
  'person_religious_info writes are audited by person_id'
);

select * from finish();
rollback;
