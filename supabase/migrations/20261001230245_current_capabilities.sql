-- The server asks capabilities, never roles. rls is not exposed by the Data API, so this RPC
-- returns the caller's own capabilities in the active church (empty without an active membership).
create function public.current_capabilities()
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(rc.capability order by rc.capability), '{}')
  from public.church_members m
  join app.role_capabilities rc on rc.role = m.role
  where m.church_id = rls.active_church_id()
    and m.user_id = auth.uid()
    and m.status = 'active'
$$;

revoke execute on function public.current_capabilities() from public, anon, authenticated;
grant execute on function public.current_capabilities() to authenticated;

update app.app_meta set value = '20261001230245' where key = 'schema_version';
