-- Development data only: fictional churches, people and @exemplo.test users.
-- Every user signs in with the password discipulu-dev (see README).
-- Slugs and e-mails differ from the pgTAP fixtures, which run on top of this seed.

-- Users (the on_auth_user_created trigger creates their profiles)

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
select
  '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated', u.email,
  extensions.crypt('discipulu-dev', extensions.gen_salt('bf')), now(),
  '{"provider": "email", "providers": ["email"]}', jsonb_build_object('full_name', u.full_name),
  now(), now(), '', '', '', ''
from (
  values
    ('11111111-1111-4111-8111-000000000001'::uuid, 'dono@exemplo.test', 'Helena Duarte'),
    ('11111111-1111-4111-8111-000000000002'::uuid, 'admin@exemplo.test', 'Fábio Antunes'),
    ('11111111-1111-4111-8111-000000000003'::uuid, 'secretaria@exemplo.test', 'Carla Mendes'),
    ('11111111-1111-4111-8111-000000000004'::uuid, 'professor@exemplo.test', 'Ricardo Moura'),
    ('11111111-1111-4111-8111-000000000005'::uuid, 'leitor@exemplo.test', 'Lívia Prado')
) as u (id, email, full_name);

insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select
  u.id::text, u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
  'email', now(), now(), now()
from auth.users u
where u.email in (
  'dono@exemplo.test', 'admin@exemplo.test', 'secretaria@exemplo.test',
  'professor@exemplo.test', 'leitor@exemplo.test'
);

-- Churches and congregations. B runs on another timezone and has religious fields off.

insert into public.churches (id, name, slug, city, state, timezone, religious_fields_enabled, created_by) values
  ('22222222-2222-4222-8222-00000000000a', 'Igreja Exemplo A', 'exemplo-a', 'Cidade Exemplo', 'SP',
   'America/Sao_Paulo', true, '11111111-1111-4111-8111-000000000001'),
  ('22222222-2222-4222-8222-00000000000b', 'Igreja Exemplo B', 'exemplo-b', 'Vila Exemplo', 'AM',
   'America/Manaus', false, '11111111-1111-4111-8111-000000000002');

insert into public.congregations (id, church_id, name, is_headquarters, city, state) values
  ('33333333-3333-4333-8333-0000000000a1', '22222222-2222-4222-8222-00000000000a', 'Sede', true, 'Cidade Exemplo', 'SP'),
  ('33333333-3333-4333-8333-0000000000a2', '22222222-2222-4222-8222-00000000000a', 'Congregação Vila Nova', false, 'Cidade Exemplo', 'SP'),
  ('33333333-3333-4333-8333-0000000000b1', '22222222-2222-4222-8222-00000000000b', 'Sede', true, 'Vila Exemplo', 'AM');

-- Members: one user per role in A; admin@ is also the owner of B.

insert into public.church_members (id, church_id, user_id, role, all_congregations) values
  ('44444444-4444-4444-8444-000000000001', '22222222-2222-4222-8222-00000000000a', '11111111-1111-4111-8111-000000000001', 'owner', true),
  ('44444444-4444-4444-8444-000000000002', '22222222-2222-4222-8222-00000000000a', '11111111-1111-4111-8111-000000000002', 'admin', true),
  ('44444444-4444-4444-8444-000000000003', '22222222-2222-4222-8222-00000000000a', '11111111-1111-4111-8111-000000000003', 'secretary', false),
  ('44444444-4444-4444-8444-000000000004', '22222222-2222-4222-8222-00000000000a', '11111111-1111-4111-8111-000000000004', 'teacher', true),
  ('44444444-4444-4444-8444-000000000005', '22222222-2222-4222-8222-00000000000a', '11111111-1111-4111-8111-000000000005', 'viewer', true),
  ('44444444-4444-4444-8444-000000000006', '22222222-2222-4222-8222-00000000000b', '11111111-1111-4111-8111-000000000002', 'owner', true);

insert into public.church_member_congregations (church_id, member_id, congregation_id) values
  ('22222222-2222-4222-8222-00000000000a', '44444444-4444-4444-8444-000000000003', '33333333-3333-4333-8333-0000000000a2');

update public.user_profiles
set active_church_id = '22222222-2222-4222-8222-00000000000a'
where user_id in (
  '11111111-1111-4111-8111-000000000001', '11111111-1111-4111-8111-000000000002',
  '11111111-1111-4111-8111-000000000003', '11111111-1111-4111-8111-000000000004',
  '11111111-1111-4111-8111-000000000005'
);

-- Classes (8)

insert into public.classes (id, church_id, congregation_id, name, min_age, max_age, room, sort_order) values
  ('55555555-5555-4555-8555-0000000000a1', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Crianças', 4, 8, 'Sala 1', 1),
  ('55555555-5555-4555-8555-0000000000a2', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Juniores', 9, 12, 'Sala 2', 2),
  ('55555555-5555-4555-8555-0000000000a3', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Adolescentes', 13, 17, 'Sala 3', 3),
  ('55555555-5555-4555-8555-0000000000a4', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Adultos', 18, null, 'Templo', 4),
  ('55555555-5555-4555-8555-0000000000a5', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a2', 'Crianças', 4, 12, 'Salão', 1),
  ('55555555-5555-4555-8555-0000000000a6', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a2', 'Jovens e Adultos', 13, null, 'Templo', 2),
  ('55555555-5555-4555-8555-0000000000b1', '22222222-2222-4222-8222-00000000000b', '33333333-3333-4333-8333-0000000000b1', 'Crianças', 4, 12, 'Sala 1', 1),
  ('55555555-5555-4555-8555-0000000000b2', '22222222-2222-4222-8222-00000000000b', '33333333-3333-4333-8333-0000000000b1', 'Adultos', 18, null, 'Templo', 2);

-- Named people: teachers, a guardian and her son, and a Sede member also enrolled at Vila Nova.

insert into public.people (id, church_id, primary_congregation_id, full_name, birth_date, gender, phone, email, guardian_person_id) values
  ('66666666-6666-4666-8666-000000000001', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Ricardo Moura', '1982-04-12', 'male', '(11) 95555-0001', 'professor@exemplo.test', null),
  ('66666666-6666-4666-8666-000000000002', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Lívia Prado', '1990-09-03', 'female', '(11) 95555-0002', 'leitor@exemplo.test', null),
  ('66666666-6666-4666-8666-000000000003', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Sônia Brito', '1975-01-28', 'female', '(11) 95555-0003', null, null),
  ('66666666-6666-4666-8666-000000000004', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Marcos Faria', '1988-06-19', 'male', '(11) 95555-0004', null, null),
  ('66666666-6666-4666-8666-000000000005', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Cláudia Reis', '1968-11-07', 'female', '(11) 95555-0005', null, null),
  ('66666666-6666-4666-8666-000000000006', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a2', 'Jorge Tavares', '1979-03-15', 'male', '(11) 95555-0006', null, null),
  ('66666666-6666-4666-8666-000000000007', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Renata Siqueira', '1987-08-22', 'female', '(11) 95555-0007', 'renata.siqueira@exemplo.test', null),
  ('66666666-6666-4666-8666-000000000009', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Elisa Moraes', '1995-02-14', 'female', '(11) 95555-0009', null, null),
  ('66666666-6666-4666-8666-000000000010', '22222222-2222-4222-8222-00000000000b', '33333333-3333-4333-8333-0000000000b1', 'Aline Castro', '1984-05-30', 'female', '(92) 95555-0010', null, null),
  ('66666666-6666-4666-8666-000000000011', '22222222-2222-4222-8222-00000000000b', '33333333-3333-4333-8333-0000000000b1', 'Roberto Lins', '1972-12-01', 'male', '(92) 95555-0011', null, null);

insert into public.people (id, church_id, primary_congregation_id, full_name, birth_date, gender, guardian_person_id) values
  ('66666666-6666-4666-8666-000000000008', '22222222-2222-4222-8222-00000000000a', '33333333-3333-4333-8333-0000000000a1', 'Miguel Siqueira',
   (current_date - interval '10 years 2 months')::date, 'male', '66666666-6666-4666-8666-000000000007');

-- Generated people. Ages are relative to today so everyone keeps fitting their class;
-- minors get a guardian from the adults of the same congregation.

with
  names as (
    select
      array['Ana', 'Beatriz', 'Camila', 'Daniela', 'Eduarda', 'Fernanda', 'Gabriela', 'Heloísa',
            'Isabela', 'Juliana', 'Larissa', 'Mariana', 'Natália', 'Olívia', 'Priscila', 'Raquel',
            'Sofia', 'Tatiane', 'Valéria', 'Yasmin'] as female,
      array['André', 'Bruno', 'Caio', 'Diego', 'Emanuel', 'Felipe', 'Gustavo', 'Henrique',
            'Igor', 'Júlio', 'Leonardo', 'Mateus', 'Nicolas', 'Otávio', 'Pedro', 'Rafael',
            'Samuel', 'Thiago', 'Vinícius', 'Wesley'] as male,
      array['Almeida', 'Barbosa', 'Cardoso', 'Dias', 'Esteves', 'Ferraz', 'Lacerda', 'Macedo',
            'Nunes', 'Oliveira', 'Pereira', 'Queiroz', 'Ribeiro', 'Santana', 'Teixeira', 'Vieira'] as surnames
  ),
  groups (ord, code, church_id, congregation_id, total, min_age, max_age, area_code, guardian_code, guardian_total) as (
    values
      (1, 'a-sede-adultos', '22222222-2222-4222-8222-00000000000a'::uuid, '33333333-3333-4333-8333-0000000000a1'::uuid, 10, 25, 70, '11', null, null),
      (2, 'a-sede-adolescentes', '22222222-2222-4222-8222-00000000000a'::uuid, '33333333-3333-4333-8333-0000000000a1'::uuid, 6, 13, 17, '11', 'a-sede-adultos', 10),
      (3, 'a-sede-juniores', '22222222-2222-4222-8222-00000000000a'::uuid, '33333333-3333-4333-8333-0000000000a1'::uuid, 6, 9, 12, '11', 'a-sede-adultos', 10),
      (4, 'a-sede-criancas', '22222222-2222-4222-8222-00000000000a'::uuid, '33333333-3333-4333-8333-0000000000a1'::uuid, 6, 4, 8, '11', 'a-sede-adultos', 10),
      (5, 'a-vila-adultos', '22222222-2222-4222-8222-00000000000a'::uuid, '33333333-3333-4333-8333-0000000000a2'::uuid, 8, 18, 65, '11', null, null),
      (6, 'a-vila-jovens', '22222222-2222-4222-8222-00000000000a'::uuid, '33333333-3333-4333-8333-0000000000a2'::uuid, 2, 14, 17, '11', 'a-vila-adultos', 8),
      (7, 'a-vila-criancas', '22222222-2222-4222-8222-00000000000a'::uuid, '33333333-3333-4333-8333-0000000000a2'::uuid, 6, 4, 12, '11', 'a-vila-adultos', 8),
      (8, 'b-adultos', '22222222-2222-4222-8222-00000000000b'::uuid, '33333333-3333-4333-8333-0000000000b1'::uuid, 6, 20, 70, '92', null, null),
      (9, 'b-criancas', '22222222-2222-4222-8222-00000000000b'::uuid, '33333333-3333-4333-8333-0000000000b1'::uuid, 4, 4, 12, '92', 'b-adultos', 6)
  ),
  generated as (
    select
      g.*,
      n,
      case when n % 2 = 0 then 'female' else 'male' end as gender,
      g.min_age + (n * 7 + g.ord) % (g.max_age - g.min_age + 1) as age,
      (n * 5 + g.ord * 3) % 16 as s1,
      (n * 37 + g.ord * 11) % 300 as extra_days
    from groups g
    cross join lateral generate_series(1, g.total) as n
  )
insert into public.people (
  id, church_id, primary_congregation_id, full_name, birth_date, gender, phone, email, guardian_person_id
)
select
  md5('seed-person-' || x.code || '-' || x.n)::uuid,
  x.church_id,
  x.congregation_id,
  (case when x.gender = 'female' then names.female else names.male end)[1 + (x.n * 7 + x.ord * 3) % 20]
    || ' ' || names.surnames[1 + x.s1]
    || ' ' || names.surnames[1 + (x.s1 + 1 + x.n % 15) % 16],
  (current_date - make_interval(years => x.age, days => x.extra_days))::date,
  x.gender,
  case when x.age >= 13 then format('(%s) 9%s-%s', x.area_code, lpad((1000 + x.ord * 50 + x.n)::text, 4, '0'), lpad((x.n * 13)::text, 4, '0')) end,
  case when x.age >= 18 then format('%s.%s@exemplo.test', x.code, x.n) end,
  case when x.guardian_code is not null then
    md5('seed-person-' || x.guardian_code || '-' || (1 + x.n % x.guardian_total))::uuid
  end
from generated x
cross join names;

-- Religious info (church A only: B has the fields turned off)

insert into public.person_religious_info (person_id, church_id, is_church_member, baptized, baptism_date)
select
  p.id, p.church_id, true, b.baptized,
  case when b.baptized then (p.birth_date + interval '16 years')::date end
from public.people p
cross join lateral (select get_byte(decode(md5(p.id::text), 'hex'), 0) % 3 <> 0 as baptized) b
where p.church_id = '22222222-2222-4222-8222-00000000000a'
  and p.birth_date <= current_date - interval '18 years'
  and get_byte(decode(md5(p.id::text), 'hex'), 1) % 4 <> 0;

-- Teachers. The teacher and the viewer users are linked through member_id: the class roster
-- answers for the teacher and stays empty for the viewer (no people.read_roster).

insert into public.class_teachers (church_id, class_id, person_id, member_id, role, started_on, ended_on) values
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a1', '66666666-6666-4666-8666-000000000003', null, 'lead', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a2', '66666666-6666-4666-8666-000000000001', '44444444-4444-4444-8444-000000000004', 'lead', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a2', '66666666-6666-4666-8666-000000000004', null, 'lead',
   (date_trunc('year', current_date) - interval '2 years')::date, (date_trunc('year', current_date) - interval '1 day')::date),
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a3', '66666666-6666-4666-8666-000000000004', null, 'lead', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a4', '66666666-6666-4666-8666-000000000005', null, 'lead', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a4', '66666666-6666-4666-8666-000000000002', '44444444-4444-4444-8444-000000000005', 'assistant', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a5', '66666666-6666-4666-8666-000000000001', '44444444-4444-4444-8444-000000000004', 'lead', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000a', '55555555-5555-4555-8555-0000000000a6', '66666666-6666-4666-8666-000000000006', null, 'lead', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000b', '55555555-5555-4555-8555-0000000000b1', '66666666-6666-4666-8666-000000000010', null, 'lead', date_trunc('year', current_date)::date, null),
  ('22222222-2222-4222-8222-00000000000b', '55555555-5555-4555-8555-0000000000b2', '66666666-6666-4666-8666-000000000011', null, 'lead', date_trunc('year', current_date)::date, null);

-- Enrollments. congregation_id comes from the class (trigger). Generated people go to the
-- class of their congregation that fits their age; one adult in five stays out.

insert into public.enrollments (church_id, person_id, class_id, started_on)
select p.church_id, p.id, c.id, date_trunc('year', current_date)::date
from public.people p
join public.classes c
  on c.church_id = p.church_id
  and c.congregation_id = p.primary_congregation_id
  and extract(year from age(current_date, p.birth_date)) >= c.min_age
  and (c.max_age is null or extract(year from age(current_date, p.birth_date)) <= c.max_age)
where p.id::text !~ '^66666666-'
  and (
    extract(year from age(current_date, p.birth_date)) < 18
    or get_byte(decode(md5(p.id::text), 'hex'), 2) % 5 <> 0
  );

-- Miguel moved from Crianças to Juniores this year; Elisa (Sede) is also enrolled at Vila Nova,
-- so the Vila Nova secretary reads her without being able to edit her.

insert into public.enrollments (church_id, person_id, class_id, started_on, ended_on, end_reason) values
  ('22222222-2222-4222-8222-00000000000a', '66666666-6666-4666-8666-000000000008', '55555555-5555-4555-8555-0000000000a1',
   (date_trunc('year', current_date) - interval '3 years')::date, (date_trunc('year', current_date) - interval '1 day')::date, 'moved_class'),
  ('22222222-2222-4222-8222-00000000000a', '66666666-6666-4666-8666-000000000008', '55555555-5555-4555-8555-0000000000a2',
   date_trunc('year', current_date)::date, null, null),
  ('22222222-2222-4222-8222-00000000000a', '66666666-6666-4666-8666-000000000007', '55555555-5555-4555-8555-0000000000a4',
   date_trunc('year', current_date)::date, null, null),
  ('22222222-2222-4222-8222-00000000000a', '66666666-6666-4666-8666-000000000009', '55555555-5555-4555-8555-0000000000a4',
   date_trunc('year', current_date)::date, null, null),
  ('22222222-2222-4222-8222-00000000000a', '66666666-6666-4666-8666-000000000009', '55555555-5555-4555-8555-0000000000a6',
   date_trunc('year', current_date)::date, null, null);
