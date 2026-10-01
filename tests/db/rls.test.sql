begin;
select plan(4);

select is(
  (
    select count(*)::int
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname in ('public', 'app')
      and c.relkind in ('r', 'p')
      and not c.relrowsecurity
  ),
  0,
  'every table in public and app has RLS enabled'
);

select ok(
  not has_schema_privilege('anon', 'app', 'usage')
    and not has_schema_privilege('authenticated', 'app', 'usage'),
  'anon and authenticated cannot use schema app'
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
