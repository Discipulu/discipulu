begin;
select plan(8);

select is(
  (
    select count(*)::int
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname in ('public', 'app', 'rls')
      and c.relkind in ('r', 'p')
      and not c.relrowsecurity
  ),
  0,
  'every table in public, app and rls has RLS enabled'
);

select ok(
  not has_schema_privilege('anon', 'app', 'usage')
    and not has_schema_privilege('authenticated', 'app', 'usage'),
  'anon and authenticated cannot use schema app'
);

select ok(
  has_schema_privilege('authenticated', 'rls', 'usage')
    and not has_schema_privilege('anon', 'rls', 'usage'),
  'only authenticated can use schema rls'
);

select is(
  (
    select count(*)::int
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'rls'
  ),
  0,
  'schema rls holds no tables, views or sequences'
);

select is(
  (
    select count(*)::int
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'rls'
      and not (p.prosecdef and 'search_path=""' = any (coalesce(p.proconfig, '{}')))
  ),
  0,
  'every rls function is security definer with an empty search_path'
);

select is(
  (
    select array_agg(n.nspname || '.' || p.proname order by p.proname)
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('app', 'rls')
      and (
        has_function_privilege('anon', p.oid, 'execute')
        or exists (
          select 1 from aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
          where a.grantee = 0 and a.privilege_type = 'EXECUTE'
        )
      )
  ),
  null,
  'no app or rls function is executable by anon or public'
);

set local role authenticated;

select throws_ok(
  'select * from app.app_meta',
  '42501',
  null,
  'authenticated cannot read app.app_meta'
);

reset role;

select isnt(
  (select value from app.app_meta where key = 'schema_version'),
  null,
  'app_meta records the schema version'
);

select * from finish();
rollback;
