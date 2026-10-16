
create schema if not exists storybook_private;
revoke all on schema storybook_private from public, anon;
grant usage on schema storybook_private to authenticated;
create table public.sb_members (
 id uuid primary key references auth.users(id) on delete cascade,
 username text not null unique check (username ~ '^[a-z0-9_]{3,32}$'),
 display_name text not null,
 enabled boolean not null default true
);
alter table public.sb_members enable row level security;
create function storybook_private.is_member() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.sb_members where id=(select auth.uid()) and enabled);
$$;
revoke all on function storybook_private.is_member() from public, anon;
grant execute on function storybook_private.is_member() to authenticated;
create policy sb_members_read on public.sb_members for select to authenticated using (storybook_private.is_member());
grant select on public.sb_members to authenticated;
revoke all on public.sb_members from anon;

create table public.sb_people (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.sb_members(id),
 name text not null check (length(trim(name)) between 1 and 120),
 category text not null default 'Date' check(category in ('Date','Freund','Familie','Job','Bekanntschaft')),
 status text not null default 'Kennenlernen' check(status in ('Kennenlernen','Date geplant','Dating','Situationship','Beziehung','Freundschaft','Abgeschlossen')),
 photo_path text,
 details jsonb not null default '{}'::jsonb check(jsonb_typeof(details)='object' and octet_length(details::text)<60000),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(id,owner_id),
 check(photo_path is null or (split_part(photo_path,'/',1)=owner_id::text and split_part(photo_path,'/',2)=id::text))
);
create table public.sb_entries (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.sb_members(id),
 person_id uuid not null,
 happened_on date not null default current_date,
 title text not null check(length(trim(title)) between 1 and 160),
 body text not null default '' check(length(body)<=30000),
 mood text check(mood is null or mood in ('Verliebt','Neugierig','Entspannt','Gemischt','Enttäuscht')),
 rating integer check(rating between 1 and 5),
 details jsonb not null default '{}'::jsonb check(jsonb_typeof(details)='object' and octet_length(details::text)<30000),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 foreign key(person_id,owner_id) references public.sb_people(id,owner_id) on delete cascade
);
create table public.sb_connections (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.sb_members(id),
 source_id uuid not null,
 target_id uuid not null references public.sb_people(id) on delete cascade,
 kind text not null check(length(trim(kind)) between 1 and 80),
 note text not null default '' check(length(note)<=3000),
 created_at timestamptz not null default now(),
 foreign key(source_id,owner_id) references public.sb_people(id,owner_id) on delete cascade,
 check(source_id<>target_id),
 unique(owner_id,source_id,target_id,kind)
);
create index sb_people_owner on public.sb_people(owner_id);
create index sb_entries_person_date on public.sb_entries(person_id,happened_on desc);
create index sb_entries_owner on public.sb_entries(owner_id);
create index sb_connections_source on public.sb_connections(source_id);
create index sb_connections_target on public.sb_connections(target_id);
create index sb_connections_owner on public.sb_connections(owner_id);
create function storybook_private.touch_updated_at() returns trigger language plpgsql set search_path='' as $$
begin new.updated_at=now(); return new; end;
$$;
revoke all on function storybook_private.touch_updated_at() from public, anon, authenticated;
create trigger sb_people_updated before update on public.sb_people for each row execute function storybook_private.touch_updated_at();
create trigger sb_entries_updated before update on public.sb_entries for each row execute function storybook_private.touch_updated_at();

alter table public.sb_people enable row level security;
alter table public.sb_entries enable row level security;
alter table public.sb_connections enable row level security;
create policy sb_people_read on public.sb_people for select to authenticated using(storybook_private.is_member());
create policy sb_people_insert on public.sb_people for insert to authenticated with check(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_people_update on public.sb_people for update to authenticated using(storybook_private.is_member() and owner_id=(select auth.uid())) with check(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_people_delete on public.sb_people for delete to authenticated using(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_entries_read on public.sb_entries for select to authenticated using(storybook_private.is_member());
create policy sb_entries_insert on public.sb_entries for insert to authenticated with check(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_entries_update on public.sb_entries for update to authenticated using(storybook_private.is_member() and owner_id=(select auth.uid())) with check(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_entries_delete on public.sb_entries for delete to authenticated using(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_connections_read on public.sb_connections for select to authenticated using(storybook_private.is_member());
create policy sb_connections_insert on public.sb_connections for insert to authenticated with check(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_connections_update on public.sb_connections for update to authenticated using(storybook_private.is_member() and owner_id=(select auth.uid())) with check(storybook_private.is_member() and owner_id=(select auth.uid()));
create policy sb_connections_delete on public.sb_connections for delete to authenticated using(storybook_private.is_member() and owner_id=(select auth.uid()));
revoke all on public.sb_people, public.sb_entries, public.sb_connections from anon;
grant select,insert,update,delete on public.sb_people,public.sb_entries,public.sb_connections to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('storybook-photos','storybook-photos',false,5242880,array['image/jpeg','image/png','image/webp']);
create policy sb_photos_read on storage.objects for select to authenticated using(bucket_id='storybook-photos' and storybook_private.is_member());
create policy sb_photos_insert on storage.objects for insert to authenticated with check(bucket_id='storybook-photos' and storybook_private.is_member() and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy sb_photos_delete on storage.objects for delete to authenticated using(bucket_id='storybook-photos' and storybook_private.is_member() and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy sb_photos_guard on storage.objects as restrictive for all to authenticated using(bucket_id<>'storybook-photos' or (storybook_private.is_member() and (storage.foldername(name))[1] in (select id::text from public.sb_members))) with check(bucket_id<>'storybook-photos' or (storybook_private.is_member() and (storage.foldername(name))[1]=(select auth.uid())::text));
