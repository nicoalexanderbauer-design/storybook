-- Scoped to Slutbook; no changes to accounts, passwords or other applications.
-- A still-unexpired JWT must not retain data access after its session is revoked.
create or replace function storybook_private.is_member()
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1
    from public.sb_members m
    join auth.sessions s on s.user_id=m.id
    where m.id=(select auth.uid()) and m.enabled
      and s.id=nullif((select auth.jwt()->>'session_id'),'')::uuid
      and (s.not_after is null or s.not_after > now())
  );
$$;
revoke all on function storybook_private.is_member() from public, anon;
grant execute on function storybook_private.is_member() to authenticated;

-- Restrictive rules keep other applications' future permissive policies from
-- granting writes to another member's photos in this shared storage table.
create policy sb_photos_owner_delete_guard on storage.objects
as restrictive for delete to authenticated
using (bucket_id<>'storybook-photos' or
  (storybook_private.is_member() and (storage.foldername(name))[1]=(select auth.uid())::text));
create policy sb_photos_owner_update_guard on storage.objects
as restrictive for update to authenticated
using (bucket_id<>'storybook-photos' or
  (storybook_private.is_member() and (storage.foldername(name))[1]=(select auth.uid())::text))
with check (bucket_id<>'storybook-photos' or
  (storybook_private.is_member() and (storage.foldername(name))[1]=(select auth.uid())::text));
create policy sb_photos_anonymous_guard on storage.objects
as restrictive for all to anon
using (bucket_id<>'storybook-photos')
with check (bucket_id<>'storybook-photos');
