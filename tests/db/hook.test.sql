begin;
select plan(13);

-- Fictional fixtures. The suite runs as postgres, which cannot assume supabase_auth_admin,
-- so the RLS path of the hook is guarded by the policy and grant checks below.

insert into auth.users (id, email) values
  ('a0000000-0000-4000-8000-0000000000a1', 'ativa@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a2', 'suspensa@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a3', 'sem.preferencia@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a4', 'sem.vinculo@exemplo.test'),
  ('a0000000-0000-4000-8000-0000000000a5', 'sem.perfil@exemplo.test');

insert into public.churches (id, name, slug) values
  ('a0000000-0000-4000-8000-000000000000', 'Igreja Exemplo A', 'igreja-exemplo-a'),
  ('b0000000-0000-4000-8000-000000000000', 'Igreja Exemplo B', 'igreja-exemplo-b');

insert into public.church_members (church_id, user_id, role, status, created_at) values
  ('b0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a1', 'viewer', 'active', '2026-01-01'),
  ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a1', 'admin', 'active', '2026-02-01'),
  ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a2', 'admin', 'suspended', '2026-01-01'),
  ('b0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a2', 'viewer', 'active', '2026-02-01'),
  ('b0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a3', 'viewer', 'active', '2026-01-01'),
  ('a0000000-0000-4000-8000-000000000000', 'a0000000-0000-4000-8000-0000000000a3', 'viewer', 'active', '2026-02-01');

update public.user_profiles set active_church_id = 'a0000000-0000-4000-8000-000000000000'
where user_id in ('a0000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-0000000000a2');

delete from public.user_profiles where user_id = 'a0000000-0000-4000-8000-0000000000a5';

create function pg_temp.hook_claim(uid text) returns jsonb language sql as $$
  select app.custom_access_token_hook(jsonb_build_object(
    'user_id', uid,
    'authentication_method', 'password',
    'claims', jsonb_build_object('sub', uid, 'role', 'authenticated', 'aud', 'authenticated')
  )) -> 'claims'
$$;

select is(
  pg_temp.hook_claim('a0000000-0000-4000-8000-0000000000a1') ->> 'active_church_id',
  'a0000000-0000-4000-8000-000000000000',
  'valid preferred church becomes the claim'
);

select is(
  pg_temp.hook_claim('a0000000-0000-4000-8000-0000000000a2') ->> 'active_church_id',
  'b0000000-0000-4000-8000-000000000000',
  'preferred church with a suspended membership falls back to another active one'
);

select is(
  pg_temp.hook_claim('a0000000-0000-4000-8000-0000000000a3') ->> 'active_church_id',
  'b0000000-0000-4000-8000-000000000000',
  'without a preference the oldest active membership wins'
);

select ok(
  pg_temp.hook_claim('a0000000-0000-4000-8000-0000000000a4') ? 'active_church_id'
    and pg_temp.hook_claim('a0000000-0000-4000-8000-0000000000a4') -> 'active_church_id' = 'null'::jsonb,
  'without any membership the claim is present and null'
);

select ok(
  pg_temp.hook_claim('a0000000-0000-4000-8000-0000000000a5') -> 'active_church_id' = 'null'::jsonb,
  'a user without a profile gets a null claim'
);

select is(
  pg_temp.hook_claim('a0000000-0000-4000-8000-0000000000a1') - 'active_church_id',
  '{"sub": "a0000000-0000-4000-8000-0000000000a1", "role": "authenticated", "aud": "authenticated"}'::jsonb,
  'existing claims are preserved'
);

select is(
  app.custom_access_token_hook('{"user_id": "not-a-uuid", "claims": {"role": "authenticated"}}'),
  '{"user_id": "not-a-uuid", "claims": {"role": "authenticated"}}'::jsonb,
  'on any error the hook returns the event unchanged'
);

-- Privileges required by Supabase Auth

select ok(
  has_function_privilege('supabase_auth_admin', 'app.custom_access_token_hook(jsonb)', 'execute')
    and has_schema_privilege('supabase_auth_admin', 'app', 'usage'),
  'supabase_auth_admin can run the hook'
);

select ok(
  not has_function_privilege('authenticated', 'app.custom_access_token_hook(jsonb)', 'execute')
    and not has_function_privilege('anon', 'app.custom_access_token_hook(jsonb)', 'execute'),
  'anon and authenticated cannot run the hook'
);

select ok(
  not (select prosecdef from pg_proc where oid = 'app.custom_access_token_hook(jsonb)'::regprocedure),
  'the hook is not security definer'
);

select ok(
  has_table_privilege('supabase_auth_admin', 'public.user_profiles', 'select')
    and has_table_privilege('supabase_auth_admin', 'public.church_members', 'select'),
  'supabase_auth_admin can select the tables the hook reads'
);

select ok(
  not (select rolbypassrls from pg_roles where rolname = 'supabase_auth_admin'),
  'supabase_auth_admin does not bypass RLS (policies below are required)'
);

select is(
  (
    select array_agg(tablename::text order by tablename)
    from pg_policies
    where schemaname = 'public'
      and cmd = 'SELECT'
      and roles = '{supabase_auth_admin}'
      and qual = 'true'
  ),
  array['church_members', 'user_profiles'],
  'user_profiles and church_members have a select policy for supabase_auth_admin'
);

select * from finish();
rollback;
