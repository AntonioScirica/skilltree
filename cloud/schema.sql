-- Skilltree, cloud mode: the map for you (after login) and a private page for each client.
-- Run once in the SQL Editor of a Supabase project. Every object is prefixed with skilltree_,
-- so it can live next to the tables of an app you already have.
--
-- Who sees what:
--   admin (a user listed in skilltree_admins)          → everything
--   client (whoever holds the link with the project token) → only their own list, and can only add files and answers
--   anyone else                                         → nothing

create table public.skilltree_admins (
  uid uuid primary key references auth.users on delete cascade
);

create table public.skilltree_projects (
  id           uuid primary key default gen_random_uuid(),
  slug         text unique not null check (slug ~ '^[a-z0-9-]{1,40}$'),
  name         text not null,
  start_date   date,                                   -- Monday of week 1
  roadmap      jsonb not null,                         -- internal: lang, levels, tasks, send, rituals
  requests     jsonb not null,                         -- visible to the client: { fasi, items }
  releases     jsonb not null default '[]',            -- visible to the client: [{ v, data, titolo, novita[], controlli[] }]
  state        jsonb not null default '{}',            -- your progress: { done, rel, got, week }
  checks       jsonb not null default '{}',            -- the client's ticks: { "<version>": { "<index>": 1 } }
  client_token text unique not null default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  created_at   timestamptz not null default now()
);

-- Files and written answers sent by the client. path is null for a written answer.
create table public.skilltree_uploads (
  id         bigint generated always as identity primary key,
  project_id uuid not null references public.skilltree_projects on delete cascade,
  request_id text not null,
  name       text not null,
  path       text,
  note       text,
  created_at timestamptz not null default now()
);
create index on public.skilltree_uploads (project_id);

alter table public.skilltree_admins   enable row level security;
alter table public.skilltree_projects enable row level security;
alter table public.skilltree_uploads  enable row level security;

-- Helper functions live outside the schema exposed by the API.
create schema skilltree_private;
grant usage on schema skilltree_private to anon, authenticated;

create function skilltree_private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.skilltree_admins where uid = auth.uid());
$$;

create function skilltree_private.token_ok(p_token text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.skilltree_projects where client_token = p_token);
$$;

create policy "skilltree admin: all on projects" on public.skilltree_projects for all to authenticated
  using (skilltree_private.is_admin()) with check (skilltree_private.is_admin());
create policy "skilltree admin: read uploads" on public.skilltree_uploads for select to authenticated
  using (skilltree_private.is_admin());
create policy "skilltree admin: delete uploads" on public.skilltree_uploads for delete to authenticated
  using (skilltree_private.is_admin());
create policy "skilltree admin: sees own row" on public.skilltree_admins for select to authenticated
  using (uid = auth.uid());

-- Progress: one key at a time, in a single UPDATE, so clicks and scripts never overwrite each other.
-- A lit task stores when it was lit (seconds since the epoch).
create function public.skilltree_set_state(p_project uuid, p_key text, p_id text, p_on boolean) returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if p_key not in ('done', 'rel', 'got') or p_id !~ '^[\w#-]{1,40}$' then
    raise exception 'invalid request';
  end if;
  update public.skilltree_projects
     set state = jsonb_set(state, array[p_key],
                   case when p_on then coalesce(state -> p_key, '{}') || jsonb_build_object(p_id, extract(epoch from now())::bigint)
                        else coalesce(state -> p_key, '{}') - p_id end)
   where id = p_project;
end $$;

create function public.skilltree_set_week(p_project uuid, p_week int) returns void
language sql security invoker set search_path = '' as $$
  update public.skilltree_projects set state = jsonb_set(state, '{week}', to_jsonb(greatest(0, least(p_week, 200)))) where id = p_project;
$$;

revoke execute on function public.skilltree_set_state, public.skilltree_set_week from public, anon;
grant  execute on function public.skilltree_set_state, public.skilltree_set_week to authenticated, service_role;

-- What the client sees: project name, their list, what they sent, what you marked as received.
-- No roadmap, no internal state, no other project.
create function public.skilltree_client_get(p_token text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'name', p.name,
    'lang', p.roadmap ->> 'lang',
    'start', p.start_date,
    'requests', p.requests,
    'releases', p.releases,
    'checks', p.checks,
    'received', (select coalesce(jsonb_agg(r ->> 'id'), '[]')
                   from jsonb_array_elements(p.requests -> 'items') r
                  where coalesce(p.state -> 'got', '{}') ? (r ->> 'id')),
    'sent', (select coalesce(jsonb_agg(jsonb_build_object('request_id', u.request_id, 'name', u.name, 'at', u.created_at) order by u.id), '[]')
               from public.skilltree_uploads u where u.project_id = p.id))
  from public.skilltree_projects p
  where p.client_token = p_token and length(p_token) >= 32;
$$;

-- The client records a file just uploaded (p_path) or a written answer (p_note).
create function public.skilltree_client_sent(p_token text, p_request text, p_name text, p_path text default null, p_note text default null) returns void
language plpgsql security definer set search_path = '' as $$
declare v_project uuid;
begin
  select id into v_project from public.skilltree_projects
   where client_token = p_token and length(p_token) >= 32
     and requests -> 'items' @> jsonb_build_array(jsonb_build_object('id', p_request));
  if v_project is null then raise exception 'invalid link'; end if;
  if (p_path is null) = (p_note is null)                                   -- exactly one of the two
     or length(p_name) not between 1 and 200
     or length(coalesce(p_note, '')) > 5000
     or (p_path is not null and p_path not like p_token || '/' || p_request || '/%')
     or (select count(*) from public.skilltree_uploads where project_id = v_project) >= 3000 then
    raise exception 'invalid request';
  end if;
  insert into public.skilltree_uploads (project_id, request_id, name, path, note)
  values (v_project, p_request, p_name, p_path, p_note);
end $$;

-- The client ticks (or unticks) a check of a release. Only for releases and checks that exist.
create function public.skilltree_client_check(p_token text, p_version text, p_index int, p_on boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare v_n int;
begin
  select jsonb_array_length(r -> 'controlli') into v_n
    from public.skilltree_projects p, jsonb_array_elements(p.releases) r
   where p.client_token = p_token and length(p_token) >= 32 and r ->> 'v' = p_version;
  if v_n is null or p_index is null or p_index < 0 or p_index >= v_n then raise exception 'invalid request'; end if;
  update public.skilltree_projects
     set checks = jsonb_set(checks, array[p_version],
                    case when p_on then coalesce(checks -> p_version, '{}') || jsonb_build_object(p_index::text, 1)
                         else coalesce(checks -> p_version, '{}') - p_index::text end)
   where client_token = p_token;
end $$;

revoke execute on function public.skilltree_client_get, public.skilltree_client_sent, public.skilltree_client_check from public;
grant  execute on function public.skilltree_client_get, public.skilltree_client_sent, public.skilltree_client_check to anon, authenticated;

-- File storage: private, 50 MB per file. Folder = the project token.
insert into storage.buckets (id, name, public, file_size_limit)
values ('skilltree', 'skilltree', false, 52428800)
on conflict (id) do nothing;

create policy "skilltree client: add files to own folder" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'skilltree' and skilltree_private.token_ok((storage.foldername(name))[1]));
create policy "skilltree admin: read client files" on storage.objects for select to authenticated
  using (bucket_id = 'skilltree' and skilltree_private.is_admin());
create policy "skilltree admin: delete client files" on storage.objects for delete to authenticated
  using (bucket_id = 'skilltree' and skilltree_private.is_admin());

-- AFTER creating your user (Authentication → Users → Add user), make it an admin:
--   insert into public.skilltree_admins (uid) select id from auth.users where email = 'YOUR-EMAIL';
-- If nobody else should sign up, turn off "Allow new users to sign up" (Authentication → Sign In / Providers).
-- A signed-up user who is not in skilltree_admins sees nothing anyway.

-- Tell the API to notice the new tables and functions right away (otherwise it can take a minute).
notify pgrst, 'reload schema';
