-- Removes everything cloud/schema.sql created. Your client files in the "skilltree" bucket must be deleted
-- from the Storage page first (Supabase does not allow dropping a bucket that still has files).
drop policy if exists "skilltree client: add files to own folder" on storage.objects;
drop policy if exists "skilltree admin: read client files" on storage.objects;
drop policy if exists "skilltree admin: delete client files" on storage.objects;
drop function if exists public.skilltree_client_check, public.skilltree_client_sent, public.skilltree_client_get, public.skilltree_set_week, public.skilltree_set_state;
drop table if exists public.skilltree_uploads, public.skilltree_projects, public.skilltree_admins;
drop schema if exists skilltree_private cascade;
