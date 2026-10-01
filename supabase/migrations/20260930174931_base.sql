create schema if not exists app;

revoke all on schema app from public, anon, authenticated;

create table app.app_meta (
  key text primary key,
  value text not null
);

-- No policies on purpose: only service_role and migrations read this table.
alter table app.app_meta enable row level security;

insert into app.app_meta (key, value) values ('schema_version', '20260930174931');
