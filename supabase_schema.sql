-- ============================================================
-- nEvents App — Supabase Database Schema
-- Run this entire file in your Supabase SQL Editor
-- ============================================================

-- ─── PROFILES ────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  name          text not null default '',
  roll_number   text not null default '',
  department    text not null default 'Computer Science and Engineering (CSE)',
  college       text not null default 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
  year          text not null default '1st Year',
  phone         text not null default '',
  dob           text not null default '',
  gender        text not null default 'Male',
  role          text not null default 'student',
  sub_role      text not null default '',
  avatar_index  int  not null default 0,
  custom_avatar_url text not null default '',
  participant_code  text not null default '',
  assigned_department text not null default '',
  assigned_event_ids  text[] not null default '{}',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Admins can view all profiles" on public.profiles;
create policy "Admins can view all profiles" on public.profiles for select using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- ─── AUTO-CREATE PROFILE ON SIGNUP TRIGGER ───────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (
    id, name, roll_number, department, college, year, phone, dob, gender, role, avatar_index
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'roll_number', ''),
    coalesce(new.raw_user_meta_data->>'department', 'Computer Science and Engineering (CSE)'),
    coalesce(new.raw_user_meta_data->>'college', 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)'),
    coalesce(new.raw_user_meta_data->>'year', '1st Year'),
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'dob', ''),
    coalesce(new.raw_user_meta_data->>'gender', 'Male'),
    coalesce(new.raw_user_meta_data->>'role', 'student'),
    coalesce((new.raw_user_meta_data->>'avatar_index')::int, 0)
  )
  on conflict (id) do update set
    name = excluded.name,
    roll_number = case when excluded.roll_number <> '' then excluded.roll_number else public.profiles.roll_number end,
    department = case when excluded.department <> '' then excluded.department else public.profiles.department end,
    college = case when excluded.college <> '' then excluded.college else public.profiles.college end,
    year = case when excluded.year <> '' then excluded.year else public.profiles.year end,
    phone = case when excluded.phone <> '' then excluded.phone else public.profiles.phone end,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── EVENTS ──────────────────────────────────────────────────
create table if not exists public.events (
  id                text primary key default gen_random_uuid()::text,
  title             text not null,
  description       text not null default '',
  banner_url        text not null default '',
  date_time         timestamptz not null,
  venue             text not null default '',
  category          text not null default 'Technical',
  coordinator_name  text not null default '',
  coordinator_phone text not null default '',
  max_seats         int  not null default 100,
  reviews           jsonb not null default '[]',
  created_by        uuid references auth.users(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

drop trigger if exists events_updated_at on public.events;
create trigger events_updated_at before update on public.events for each row execute procedure public.handle_updated_at();

alter table public.events enable row level security;

drop policy if exists "Anyone can view events" on public.events;
create policy "Anyone can view events" on public.events for select using (true);

drop policy if exists "Admins can insert events" on public.events;
create policy "Admins can insert events" on public.events for insert with check (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

drop policy if exists "Admins can update events" on public.events;
create policy "Admins can update events" on public.events for update using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

drop policy if exists "Admins can delete events" on public.events;
create policy "Admins can delete events" on public.events for delete using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- ─── REGISTRATIONS ───────────────────────────────────────────
create table if not exists public.registrations (
  id                  text primary key default gen_random_uuid()::text,
  event_id            text not null references public.events(id) on delete cascade,
  user_id             uuid references auth.users(id),
  full_name           text not null,
  roll_number         text not null,
  department          text not null default '',
  college             text not null default '',
  year_of_study       text not null default '',
  phone_number        text not null default '',
  registration_date   timestamptz not null default now(),
  status              text not null default 'Registered',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

drop trigger if exists registrations_updated_at on public.registrations;
create trigger registrations_updated_at before update on public.registrations for each row execute procedure public.handle_updated_at();

create index if not exists registrations_event_id_idx on public.registrations(event_id);
create index if not exists registrations_user_id_idx  on public.registrations(user_id);
create index if not exists registrations_roll_idx     on public.registrations(roll_number);

alter table public.registrations enable row level security;

drop policy if exists "Users can view own registrations" on public.registrations;
create policy "Users can view own registrations" on public.registrations for select using (user_id = auth.uid());

drop policy if exists "Admins and staff can view all registrations" on public.registrations;
create policy "Admins and staff can view all registrations" on public.registrations for select using (
  exists (select 1 from public.profiles where id = auth.uid() and (role = 'admin' or sub_role != ''))
);

drop policy if exists "Authenticated users can register" on public.registrations;
create policy "Authenticated users can register" on public.registrations for insert with check (auth.uid() is not null);

drop policy if exists "Admins and staff can update status" on public.registrations;
create policy "Admins and staff can update status" on public.registrations for update using (
  exists (select 1 from public.profiles where id = auth.uid() and (role = 'admin' or sub_role != ''))
);

-- ─── BANNERS ─────────────────────────────────────────────────
create table if not exists public.banners (
  id              text primary key default gen_random_uuid()::text,
  title           text not null,
  image_url       text not null,
  linked_event_id text references public.events(id) on delete set null,
  display_order   int  not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

drop trigger if exists banners_updated_at on public.banners;
create trigger banners_updated_at before update on public.banners for each row execute procedure public.handle_updated_at();

alter table public.banners enable row level security;

drop policy if exists "Anyone can view banners" on public.banners;
create policy "Anyone can view banners" on public.banners for select using (true);

drop policy if exists "Admins can manage banners" on public.banners;
create policy "Admins can manage banners" on public.banners for all using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- ─── STAFF ASSIGNMENTS ───────────────────────────────────────
create table if not exists public.staff_assignments (
  id                  text primary key default gen_random_uuid()::text,
  user_id             uuid not null references auth.users(id) on delete cascade,
  user_name           text not null default '',
  user_email          text not null default '',
  user_roll_number    text not null default '',
  user_department     text not null default '',
  sub_role            text not null,
  assigned_department text not null default '',
  assigned_event_ids  text[] not null default '{}',
  granted_by_admin_id uuid references auth.users(id),
  granted_at          timestamptz not null default now(),
  unique (user_id)
);

alter table public.staff_assignments enable row level security;

drop policy if exists "Staff can view own assignment" on public.staff_assignments;
create policy "Staff can view own assignment" on public.staff_assignments for select using (user_id = auth.uid());

drop policy if exists "Admins can manage all staff assignments" on public.staff_assignments;
create policy "Admins can manage all staff assignments" on public.staff_assignments for all using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- ─── NOTIFICATIONS ───────────────────────────────────────────
create table if not exists public.notifications (
  id              text primary key default gen_random_uuid()::text,
  user_id         uuid references auth.users(id) on delete cascade,
  title           text not null,
  message         text not null,
  is_read         boolean not null default false,
  linked_event_id text references public.events(id) on delete set null,
  created_at      timestamptz not null default now()
);

create index if not exists notifications_user_id_idx on public.notifications(user_id);

alter table public.notifications enable row level security;

drop policy if exists "Users can view own and broadcast notifications" on public.notifications;
create policy "Users can view own and broadcast notifications" on public.notifications for select using (user_id = auth.uid() or user_id is null);

drop policy if exists "Users can mark own notifications read" on public.notifications;
create policy "Users can mark own notifications read" on public.notifications for update using (user_id = auth.uid() or user_id is null);

drop policy if exists "Authenticated users can insert notifications" on public.notifications;
create policy "Authenticated users can insert notifications" on public.notifications for insert with check (auth.uid() is not null);

drop policy if exists "Admins can delete notifications" on public.notifications;
create policy "Admins can delete notifications" on public.notifications for delete using (
  exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
);

-- ─── CHAT MESSAGES ───────────────────────────────────────────
create table if not exists public.chat_messages (
  id            text primary key default gen_random_uuid()::text,
  event_id      text not null references public.events(id) on delete cascade,
  student_roll  text not null,
  student_name  text not null,
  sender_role   text not null,
  text          text not null,
  created_at    timestamptz not null default now()
);

create index if not exists chat_messages_event_roll_idx on public.chat_messages(event_id, student_roll);

alter table public.chat_messages enable row level security;

drop policy if exists "Authenticated users can view chat messages" on public.chat_messages;
create policy "Authenticated users can view chat messages" on public.chat_messages for select using (auth.uid() is not null);

drop policy if exists "Authenticated users can send messages" on public.chat_messages;
create policy "Authenticated users can send messages" on public.chat_messages for insert with check (auth.uid() is not null);

-- ─── ENABLE REALTIME ─────────────────────────────────────────
-- Safe Realtime table registration:
do $$
begin
  begin
    alter publication supabase_realtime add table public.events;
  exception when others then null;
  end;

  begin
    alter publication supabase_realtime add table public.registrations;
  exception when others then null;
  end;

  begin
    alter publication supabase_realtime add table public.notifications;
  exception when others then null;
  end;

  begin
    alter publication supabase_realtime add table public.chat_messages;
  exception when others then null;
  end;
end $$;
