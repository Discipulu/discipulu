begin;
select plan(57);

-- Fixtures (fictional). Church A: Sede + Congregação Norte. Church B: Sede only.

insert into auth.users (id, email) values
  ('a0000000-0000-4000-8000-0000000000a1', 'dono.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a3', 'secretaria.norte.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a4', 'leitor.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a6', 'professora.sede.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a7', 'professor.norte.a@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a8', 'professor.suspenso.a@exemplo.test'),
  ('b0000000-0000-4000-8000-0000000000b1', 'dono.b@exemplo.test');

insert into public.churches (id, name, slug) values
  ('a0000000-0000-4000-8000-000000000000', 'Igreja Exemplo A', 'igreja-exemplo-a'),
  ('b0000000-0000-4000-8000-000000000000', 'Igreja Exemplo B', 'igreja-exemplo-b');

insert into public.congregations (id, church_id, name, is_headquarters) values
  ('a0000000-0000-4000-8000-0000000000c1', 'a0000000-0000-4000-8000-000000000000', 'Sede', true),
  ('a0000000-0000-4000-8000-0000000000c2', 'a0000000-0000-4000-8000-000000000000', 'Congregação Norte', false),
  ('b0000000-0000-4000-8000-0000000000c1', 'b0000000-0000-4000-8000-000000000000', 'Sede', true);

insert into public.church_members (id, church_id, user_id, role, all_congregations, status) values
  ('e0000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a1', 'owner', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a3', 'secretary', false, 'active'),
  ('e0000000-0000-4000-8000-0000000000a4', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a4', 'viewer', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a6', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a6', 'teacher', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a7', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a7', 'teacher', true, 'active'),
  ('e0000000-0000-4000-8000-0000000000a8', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a8', 'teacher', true, 'suspended'),
  ('e0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000b1', 'owner', true, 'active');

insert into public.church_member_congregations (church_id, member_id, congregation_id) values
  ('a0000000-0000-4000-8000-000000000000', 'e0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-0000000000c2');

insert into public.people (id, church_id, primary_congregation_id, full_name, birth_date, phone) values
  ('f0000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Responsável Exemplo', '1985-01-20', '(11) 90000-0003'),
  ('f0000000-0000-4000-8000-0000000000a4', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c2', 'Aluno Exemplo Norte', null, null),
  ('f0000000-0000-4000-8000-0000000000a5', 'a0000000-0000-4000-8000-000000000000', null, 'Pessoa Exemplo Sem Congregação', null, null),
  ('f0000000-0000-4000-8000-0000000000a6', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Visitante Exemplo Sede', null, null),
  ('f0000000-0000-4000-8000-0000000000a7', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Ex-aluno Exemplo Sede', null, null),
  ('f0000000-0000-4000-8000-0000000000a8', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Pessoa Exemplo Sede', null, null),
  ('f0000000-0000-4000-8000-0000000000a9', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Pessoa Exemplo Duas Turmas', null, null),
  ('f0000000-0000-4000-8000-0000000000aa', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c2', 'Nova Aluna Exemplo Norte', null, null),
  ('d0000000-0000-4000-8000-0000000000d1', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Professora Exemplo Sede', null, null),
  ('d0000000-0000-4000-8000-0000000000d2', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c2', 'Professor Exemplo Norte', null, null),
  ('d0000000-0000-4000-8000-0000000000d3', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Auxiliar Exemplo', null, null),
  ('d0000000-0000-4000-8000-0000000000d4', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Professor Exemplo Suspenso', null, null),
  ('f0000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000c1', 'Pessoa Exemplo B', null, null);

insert into public.people (
  id, church_id, primary_congregation_id, full_name, birth_date, phone, email, address_line, guardian_person_id
) values
  ('f0000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1',
   'Adulto Exemplo Sede', '1990-05-17', '(11) 90000-0001', 'adulto@exemplo.test', 'Rua Exemplo, 1', null),
  ('f0000000-0000-4000-8000-0000000000a2', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1',
   'Criança Exemplo Sede', '2018-03-10', '(11) 90000-0002', 'crianca@exemplo.test', 'Rua Exemplo, 2',
   'f0000000-0000-4000-8000-0000000000a3');

insert into public.classes (id, church_id, congregation_id, name, archived_at) values
  ('10000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Juniores', null),
  ('10000000-0000-4000-8000-0000000000a2', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c2', 'Adultos Norte', null),
  ('10000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Jovens', null),
  ('10000000-0000-4000-8000-0000000000a4', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Turma Exemplo Antiga', null),
  ('10000000-0000-4000-8000-0000000000a5', 'a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Turma Exemplo Arquivada', '2026-01-01'),
  ('10000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000c1', 'Classe Exemplo B', null);

insert into public.class_teachers (id, church_id, class_id, person_id, member_id, role) values
  ('30000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000000', '10000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000d1', 'e0000000-0000-4000-8000-0000000000a6', 'lead'),
  ('30000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000000', '10000000-0000-4000-8000-0000000000a2', 'd0000000-0000-4000-8000-0000000000d2', 'e0000000-0000-4000-8000-0000000000a7', 'lead'),
  ('30000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000000', '10000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000d3', 'e0000000-0000-4000-8000-0000000000a4', 'assistant'),
  ('30000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000000', '10000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000d4', 'e0000000-0000-4000-8000-0000000000a8', 'assistant');

insert into public.class_teachers (id, church_id, class_id, person_id, member_id, started_on, ended_on) values
  ('30000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000000', '10000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000d2', 'e0000000-0000-4000-8000-0000000000a7', '2025-01-01', '2025-12-31');

-- congregation_id is sent wrong on purpose: the trigger copies it from the class.
insert into public.enrollments (id, church_id, person_id, class_id, congregation_id, started_on, created_at, updated_at) values
  ('20000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a1', '10000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-0000000000c2', '2026-02-01', '2026-01-01', '2026-01-01');

insert into public.enrollments (id, church_id, person_id, class_id, started_on) values
  ('20000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a2', '10000000-0000-4000-8000-0000000000a1', '2026-02-01'),
  ('20000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a4', '10000000-0000-4000-8000-0000000000a2', '2026-02-01'),
  ('20000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a5', '10000000-0000-4000-8000-0000000000a2', '2026-02-01'),
  ('20000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a6', '10000000-0000-4000-8000-0000000000a2', '2026-02-01'),
  ('20000000-0000-4000-8000-000000000007', 'a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a9', '10000000-0000-4000-8000-0000000000a1', '2026-02-01'),
  ('20000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000b1', '10000000-0000-4000-8000-0000000000b1', '2026-02-01');

insert into public.enrollments (id, church_id, person_id, class_id, started_on, ended_on, end_reason) values
  ('20000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a7', '10000000-0000-4000-8000-0000000000a2', '2025-02-01', '2025-12-01', 'left');

-- Schema and integrity (as postgres)

select columns_are(
  'public', 'class_roster',
  array['enrollment_id', 'church_id', 'class_id', 'person_id', 'started_on', 'full_name', 'age',
        'birth_month', 'birth_day', 'phone', 'phone_is_guardian'],
  'class_roster exposes no address, e-mail or religious data'
);

select results_eq(
  $$select role from app.role_capabilities where capability = 'people.read_roster' order by role$$,
  $$values ('admin'::text), ('owner'), ('secretary'), ('teacher')$$,
  'people.read_roster is granted to every role but viewer'
);

select is(
  (select congregation_id from public.enrollments where id = '20000000-0000-4000-8000-000000000001'),
  'a0000000-0000-4000-8000-0000000000c1'::uuid,
  'enrollment congregation is copied from the class, whatever was sent'
);

select is(
  (select started_on from public.class_teachers where id = '30000000-0000-4000-8000-000000000001'),
  (now() at time zone 'America/Sao_Paulo')::date,
  'started_on defaults to today in the church timezone'
);

select lives_ok(
  $$insert into public.enrollments (id, church_id, person_id, class_id, started_on)
    values ('20000000-0000-4000-8000-000000000008', 'a0000000-0000-4000-8000-000000000000',
            'f0000000-0000-4000-8000-0000000000a9', '10000000-0000-4000-8000-0000000000a2', '2026-02-01')$$,
  'a person may hold one active enrollment in each congregation'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a9', '10000000-0000-4000-8000-0000000000a3')$$,
  '23505',
  null,
  'a second active enrollment in the same congregation is refused'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id, started_on, ended_on, end_reason)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8',
            '10000000-0000-4000-8000-0000000000a3', '2026-03-01', '2026-02-01', 'left')$$,
  '23514',
  null,
  'an enrollment cannot end before it starts'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id, end_reason)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8',
            '10000000-0000-4000-8000-0000000000a3', 'left')$$,
  '23514',
  null,
  'an end reason requires an end date'
);

select throws_ok(
  $$update public.enrollments set person_id = 'f0000000-0000-4000-8000-0000000000a8'
    where id = '20000000-0000-4000-8000-000000000001'$$,
  '23514',
  'an enrollment keeps its person and class: end it and open another',
  'an enrollment cannot change person'
);

select throws_ok(
  $$update public.enrollments set class_id = '10000000-0000-4000-8000-0000000000a3'
    where id = '20000000-0000-4000-8000-000000000001'$$,
  '23514',
  'an enrollment keeps its person and class: end it and open another',
  'an enrollment cannot change class'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8', '10000000-0000-4000-8000-0000000000b1')$$,
  '23503',
  null,
  'composite FK blocks an enrollment of A in a class of B'
);

select throws_ok(
  $$insert into public.classes (church_id, congregation_id, name)
    values ('a0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000c1', 'Cruzada')$$,
  '23503',
  null,
  'composite FK blocks a class of A in a congregation of B'
);

select throws_ok(
  $$insert into public.class_teachers (church_id, class_id, person_id, member_id)
    values ('a0000000-0000-4000-8000-000000000000', '10000000-0000-4000-8000-0000000000a3',
            'd0000000-0000-4000-8000-0000000000d1', 'e0000000-0000-4000-8000-0000000000b1')$$,
  '23503',
  null,
  'composite FK blocks a teacher login from another church'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8', '10000000-0000-4000-8000-0000000000a5')$$,
  '23514',
  'class 10000000-0000-4000-8000-0000000000a5 is archived',
  'nobody is enrolled in an archived class'
);

select throws_ok(
  $$update public.classes set archived_at = now() where id = '10000000-0000-4000-8000-0000000000a1'$$,
  '23514',
  'class 10000000-0000-4000-8000-0000000000a1 still has active enrollments',
  'a class with active enrollments cannot be archived'
);

select throws_ok(
  $$update public.classes set congregation_id = 'a0000000-0000-4000-8000-0000000000c1'
    where id = '10000000-0000-4000-8000-0000000000a2'$$,
  '23503',
  null,
  'a class with enrollments cannot move to another congregation'
);

-- Teacher of Juniores (Sede)

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a6", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);
set local role authenticated;

select results_eq(
  'select person_id from public.class_roster order by person_id',
  $$values ('f0000000-0000-4000-8000-0000000000a1'::uuid), ('f0000000-0000-4000-8000-0000000000a2'), ('f0000000-0000-4000-8000-0000000000a9')$$,
  'teacher sees the active students of their class only'
);

select results_eq(
  $$select full_name, age, birth_month, birth_day, phone, phone_is_guardian
    from public.class_roster where person_id = 'f0000000-0000-4000-8000-0000000000a2'$$,
  $$select 'Criança Exemplo Sede'::text,
           extract(year from age((now() at time zone 'America/Sao_Paulo')::date, '2018-03-10'::date))::integer,
           3, 10, '(11) 90000-0003'::text, true$$,
  'a minor shows age, birthday and the guardian phone'
);

select results_eq(
  $$select phone, phone_is_guardian from public.class_roster where person_id = 'f0000000-0000-4000-8000-0000000000a1'$$,
  $$values ('(11) 90000-0001'::text, false)$$,
  'an adult shows their own phone'
);

select results_eq(
  'select id from public.enrollments order by id',
  $$values ('20000000-0000-4000-8000-000000000001'::uuid), ('20000000-0000-4000-8000-000000000002'), ('20000000-0000-4000-8000-000000000007')$$,
  'teacher reads the enrollments of their class only'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8', '10000000-0000-4000-8000-0000000000a1')$$,
  '42501',
  null,
  'teacher cannot enroll students'
);

select throws_ok(
  $$insert into public.classes (church_id, congregation_id, name)
    values ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Turma do Professor')$$,
  '42501',
  null,
  'teacher cannot create classes'
);

-- Teacher of Adultos Norte, with an ended assignment in Juniores

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a7", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select results_eq(
  'select person_id from public.class_roster order by person_id',
  $$values ('f0000000-0000-4000-8000-0000000000a4'::uuid), ('f0000000-0000-4000-8000-0000000000a5'), ('f0000000-0000-4000-8000-0000000000a6'), ('f0000000-0000-4000-8000-0000000000a9')$$,
  'another teacher sees only their own class; an ended assignment gives nothing'
);

-- Viewer linked as assistant, suspended teacher

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a4", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.class_roster) + (select count(*)::int from public.enrollments),
  0,
  'a viewer linked as teacher reads no roster nor enrollments (no people.read_roster)'
);

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a8", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is((select count(*)::int from public.class_roster), 0, 'a suspended teacher reads no roster despite a valid token');

-- Secretary of A scoped to Congregação Norte

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a3", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select results_eq(
  'select id from public.classes',
  $$values ('10000000-0000-4000-8000-0000000000a2'::uuid)$$,
  'scoped secretary sees only the classes of the scope'
);

select results_eq(
  'select id from public.people order by id',
  $$values ('d0000000-0000-4000-8000-0000000000d2'::uuid), ('f0000000-0000-4000-8000-0000000000a4'),
           ('f0000000-0000-4000-8000-0000000000a5'), ('f0000000-0000-4000-8000-0000000000a6'),
           ('f0000000-0000-4000-8000-0000000000a7'), ('f0000000-0000-4000-8000-0000000000a9'),
           ('f0000000-0000-4000-8000-0000000000aa')$$,
  'scoped secretary sees people of the scope plus anyone with a current or past enrollment there (with or without congregation)'
);

select results_eq(
  'select id from public.enrollments order by id',
  $$values ('20000000-0000-4000-8000-000000000003'::uuid), ('20000000-0000-4000-8000-000000000004'),
           ('20000000-0000-4000-8000-000000000005'), ('20000000-0000-4000-8000-000000000006'),
           ('20000000-0000-4000-8000-000000000008')$$,
  'scoped secretary sees only enrollments of the scope'
);

select results_eq(
  'select id from public.class_teachers',
  $$values ('30000000-0000-4000-8000-000000000002'::uuid)$$,
  'scoped secretary sees only teachers of classes in the scope'
);

select is((select count(*)::int from public.class_roster), 0, 'the roster is only for classes the user teaches');

select throws_ok(
  $$update public.people set notes = 'Alterada' where id = 'f0000000-0000-4000-8000-0000000000a6'$$,
  '42501',
  null,
  'scoped secretary reads but cannot edit a person of another congregation enrolled in the scope'
);

select throws_ok(
  $$insert into public.person_religious_info (person_id, church_id, baptized)
    values ('f0000000-0000-4000-8000-0000000000a6', 'a0000000-0000-4000-8000-000000000000', true)$$,
  '42501',
  null,
  'scoped secretary cannot write religious info of a person of another congregation'
);

select throws_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a6')$$,
  '42501',
  null,
  'scoped secretary cannot anonymize a person of another congregation'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8', '10000000-0000-4000-8000-0000000000a2')$$,
  '42501',
  null,
  'scoped secretary cannot enroll a person they cannot read'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000aa', '10000000-0000-4000-8000-0000000000a1')$$,
  '42501',
  null,
  'scoped secretary cannot enroll into a class outside the scope'
);

select lives_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000aa', '10000000-0000-4000-8000-0000000000a2')
    returning id$$,
  'scoped secretary enrolls a person into a class of the scope (insert ... returning)'
);

select throws_ok(
  $$insert into public.classes (church_id, congregation_id, name)
    values ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c1', 'Turma Sede')$$,
  '42501',
  null,
  'scoped secretary cannot create a class outside the scope'
);

select lives_ok(
  $$insert into public.classes (church_id, congregation_id, name)
    values ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000c2', 'Jovens Norte')
    returning id$$,
  'scoped secretary creates a class in the scope (insert ... returning)'
);

-- Owner of A

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "active_church_id": "a0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.classes where church_id <> 'a0000000-0000-4000-8000-000000000000')
    + (select count(*)::int from public.enrollments where church_id <> 'a0000000-0000-4000-8000-000000000000'),
  0,
  'owner A sees no class nor enrollment of B'
);

select throws_ok(
  $$insert into public.classes (church_id, congregation_id, name)
    values ('b0000000-0000-4000-8000-000000000000', 'b0000000-0000-4000-8000-0000000000c1', 'Intrusa')$$,
  '42501',
  null,
  'owner A cannot create a class in B'
);

select throws_ok(
  $$delete from public.classes where id = '10000000-0000-4000-8000-0000000000a4'$$,
  '42501',
  null,
  'classes are archived, never deleted'
);

select throws_ok(
  $$delete from public.enrollments where id = '20000000-0000-4000-8000-000000000002'$$,
  '42501',
  null,
  'enrollments are ended, never deleted'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id, congregation_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8',
            '10000000-0000-4000-8000-0000000000a3', 'a0000000-0000-4000-8000-0000000000c1')$$,
  '42501',
  null,
  'enrollment congregation cannot be sent through the API'
);

select lives_ok(
  $$update public.classes set archived_at = now() where id = '10000000-0000-4000-8000-0000000000a4'$$,
  'owner archives a class without active enrollments'
);

-- Class change: end the enrollment, open another.

select lives_ok(
  $$update public.enrollments set ended_on = '2026-09-27', end_reason = 'moved_class'
    where id = '20000000-0000-4000-8000-000000000001'$$,
  'class change, step 1: end the current enrollment'
);

select lives_ok(
  $$insert into public.enrollments (church_id, person_id, class_id, started_on)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a1',
            '10000000-0000-4000-8000-0000000000a3', '2026-09-27')
    returning id$$,
  'class change, step 2: open the enrollment in the new class'
);

select lives_ok(
  $$select public.anonymize_person('f0000000-0000-4000-8000-0000000000a9')$$,
  'owner anonymizes an enrolled person'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('a0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a9', '10000000-0000-4000-8000-0000000000a3')$$,
  '23514',
  'person f0000000-0000-4000-8000-0000000000a9 is anonymized',
  'an anonymized person cannot be enrolled'
);

-- Spoofed claim: owner A pointing at B

select set_config('request.jwt.claims', '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "active_church_id": "b0000000-0000-4000-8000-000000000000"}', true);

select is(
  (select count(*)::int from public.classes) + (select count(*)::int from public.class_teachers)
    + (select count(*)::int from public.enrollments) + (select count(*)::int from public.class_roster),
  0,
  'a claim for a church without membership exposes no class, teacher, enrollment or roster'
);

-- Owner of B

select set_config('request.jwt.claims', '{"sub": "b0000000-0000-4000-8000-0000000000b1", "role": "authenticated", "active_church_id": "b0000000-0000-4000-8000-000000000000"}', true);

select results_eq(
  'select id from public.classes union all select id from public.enrollments',
  $$values ('10000000-0000-4000-8000-0000000000b1'::uuid), ('20000000-0000-4000-8000-0000000000b1')$$,
  'owner B sees only classes and enrollments of B'
);

select throws_ok(
  $$insert into public.enrollments (church_id, person_id, class_id)
    values ('b0000000-0000-4000-8000-000000000000', 'f0000000-0000-4000-8000-0000000000a8', '10000000-0000-4000-8000-0000000000b1')$$,
  '42501',
  null,
  'owner B cannot enroll a person of A'
);

-- Anonymous

reset role;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok('select * from public.class_roster', '42501', null, 'anon cannot read the class roster');
select throws_ok('select * from public.enrollments', '42501', null, 'anon cannot read enrollments');

reset role;

-- Effects checked as postgres

select results_eq(
  $$select class_id, ended_on, end_reason from public.enrollments
    where person_id = 'f0000000-0000-4000-8000-0000000000a1' order by started_on$$,
  $$values ('10000000-0000-4000-8000-0000000000a1'::uuid, '2026-09-27'::date, 'moved_class'::text),
           ('10000000-0000-4000-8000-0000000000a3', null, null)$$,
  'class change keeps the old enrollment as history and one active enrollment'
);

select results_eq(
  $$select count(*)::int, count(*) filter (where ended_on is not null and end_reason = 'other')::int
    from public.enrollments where person_id = 'f0000000-0000-4000-8000-0000000000a9'$$,
  $$values (2, 2)$$,
  'anonymization ends every active enrollment of the person'
);

select results_eq(
  $$select a.actor_id, e.updated_at > e.created_at
    from app.audit_log a
    join public.enrollments e on e.id = a.record_id
    where a.table_name = 'enrollments' and a.action = 'update'
      and a.record_id = '20000000-0000-4000-8000-000000000001'$$,
  $$values ('a0000000-0000-4000-8000-0000000000a1'::uuid, true)$$,
  'enrollment changes are audited with the acting user and bump updated_at'
);

select ok(
  exists (select 1 from app.audit_log where table_name = 'class_teachers' and action = 'insert'),
  'teacher assignments are audited'
);

select * from finish();
rollback;
