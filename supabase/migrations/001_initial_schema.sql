-- ============================================================================
-- MAKELAARSMAATJE DATABASE SCHEMA
-- Run dit volledige script in Supabase SQL Editor (Dashboard > SQL Editor > New)
-- ============================================================================

-- ============================================================================
-- 1. ORGANIZATIONS (makelaarskantoren)
-- ============================================================================
create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  created_at timestamptz default now()
);

-- ============================================================================
-- 2. PROFILES (makelaars, gekoppeld aan auth.users)
-- ============================================================================
create type user_role as enum ('admin', 'makelaar');

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid references organizations(id) on delete cascade,
  full_name text not null,
  initials text not null,
  email text not null,
  phone text,
  role user_role default 'makelaar',
  color text default '#1F3D2B',
  avatar_url text,
  created_at timestamptz default now()
);

-- ============================================================================
-- 3. PROPERTIES (woningen in portefeuille)
-- ============================================================================
create table properties (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,
  address text not null,
  city text,
  price_cents bigint,
  size_m2 int,
  funda_url text,
  seller_name text,
  seller_email text,
  seller_phone text,
  status text default 'active',
  created_at timestamptz default now()
);

-- ============================================================================
-- 4. LEADS (binnenkomende leads van Funda)
-- ============================================================================
create type lead_status as enum ('new', 'contacted', 'booked', 'visited', 'disqualified', 'closed');
create type lead_priority as enum ('hot', 'warm', 'cold');

create table leads (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,
  property_id uuid references properties(id) on delete set null,
  assigned_to uuid references profiles(id) on delete set null,
  
  -- Lead info
  name text not null,
  email text,
  phone text,
  message text,
  source text default 'Funda',
  channel text default 'Funda-lead',
  
  -- Qualification
  qualified boolean default false,
  score int default 0,
  budget_range text,
  financing_status text,
  timeline text,
  priority lead_priority default 'warm',
  
  -- Status
  status lead_status default 'new',
  booking_time timestamptz,
  
  -- Raw data (het originele bericht van Funda)
  raw_payload jsonb,
  
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index leads_org_idx on leads(organization_id);
create index leads_assigned_idx on leads(assigned_to);
create index leads_status_idx on leads(status);
create index leads_created_idx on leads(created_at desc);

-- ============================================================================
-- 5. NOTES (notities bij leads)
-- ============================================================================
create table lead_notes (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid references leads(id) on delete cascade,
  author_id uuid references profiles(id) on delete set null,
  text text not null,
  created_at timestamptz default now()
);

create index notes_lead_idx on lead_notes(lead_id);

-- ============================================================================
-- 6. BOOKING SLOTS (beschikbare bezichtigingsmomenten)
-- ============================================================================
create table booking_slots (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references properties(id) on delete cascade,
  agent_id uuid references profiles(id) on delete cascade,
  start_time timestamptz not null,
  duration_minutes int default 30,
  booked_by_lead_id uuid references leads(id) on delete set null,
  is_booked boolean default false,
  created_at timestamptz default now()
);

create index slots_property_idx on booking_slots(property_id);
create index slots_start_idx on booking_slots(start_time);

-- ============================================================================
-- 7. AVAILABILITY (reguliere beschikbaarheid van een makelaar per dag)
-- ============================================================================
create table agent_availability (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references profiles(id) on delete cascade,
  day_of_week int not null, -- 0=zondag, 1=maandag, etc.
  start_time time,
  end_time time,
  is_active boolean default true,
  unique(agent_id, day_of_week)
);

-- ============================================================================
-- 8. MESSAGES (uitgewisselde berichten met leads)
-- ============================================================================
create type message_direction as enum ('incoming', 'outgoing');
create type message_channel as enum ('email', 'whatsapp', 'funda', 'sms');

create table messages (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid references leads(id) on delete cascade,
  direction message_direction not null,
  channel message_channel not null,
  content text,
  sent_by uuid references profiles(id) on delete set null,
  created_at timestamptz default now()
);

create index messages_lead_idx on messages(lead_id);

-- ============================================================================
-- 9. AUTOMATED EVENTS (geplande herinneringen en follow-ups)
-- ============================================================================
create type event_type as enum ('reminder_24h', 'reminder_2h', 'followup_2h', 'followup_3d');
create type event_status as enum ('scheduled', 'sent', 'failed', 'cancelled');

create table automated_events (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid references leads(id) on delete cascade,
  event_type event_type not null,
  scheduled_for timestamptz not null,
  status event_status default 'scheduled',
  sent_at timestamptz,
  created_at timestamptz default now()
);

create index events_scheduled_idx on automated_events(scheduled_for) where status = 'scheduled';

-- ============================================================================
-- 10. TRIGGER: auto-update updated_at op leads
-- ============================================================================
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_leads_updated_at before update on leads
  for each row execute function update_updated_at_column();

-- ============================================================================
-- 11. TRIGGER: maak automatisch een profile aan wanneer een gebruiker signup't
-- ============================================================================
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, initials)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'initials', upper(substring(new.email, 1, 2)))
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY - BELANGRIJK voor rechten
-- ============================================================================

alter table organizations enable row level security;
alter table profiles enable row level security;
alter table properties enable row level security;
alter table leads enable row level security;
alter table lead_notes enable row level security;
alter table booking_slots enable row level security;
alter table agent_availability enable row level security;
alter table messages enable row level security;
alter table automated_events enable row level security;

-- Helper: haal organization_id op van huidige gebruiker
create or replace function user_organization_id()
returns uuid as $$
  select organization_id from profiles where id = auth.uid();
$$ language sql stable security definer;

-- PROFILES: iedereen in org kan elkaar zien, alleen jezelf bewerken
create policy "Users can view profiles in their org"
  on profiles for select using (organization_id = user_organization_id());

create policy "Users can update own profile"
  on profiles for update using (id = auth.uid());

-- ORGANIZATIONS: alleen eigen org zichtbaar
create policy "Users can view own organization"
  on organizations for select using (id = user_organization_id());

-- PROPERTIES: alleen eigen org
create policy "Users can view properties in their org"
  on properties for select using (organization_id = user_organization_id());

create policy "Users can insert properties in their org"
  on properties for insert with check (organization_id = user_organization_id());

create policy "Users can update properties in their org"
  on properties for update using (organization_id = user_organization_id());

create policy "Users can delete properties in their org"
  on properties for delete using (organization_id = user_organization_id());

-- LEADS: alleen eigen org
create policy "Users can view leads in their org"
  on leads for select using (organization_id = user_organization_id());

create policy "Users can insert leads in their org"
  on leads for insert with check (organization_id = user_organization_id());

create policy "Users can update leads in their org"
  on leads for update using (organization_id = user_organization_id());

create policy "Users can delete leads in their org"
  on leads for delete using (organization_id = user_organization_id());

-- LEAD NOTES
create policy "Users can view notes on their org leads"
  on lead_notes for select using (
    lead_id in (select id from leads where organization_id = user_organization_id())
  );

create policy "Users can add notes to their org leads"
  on lead_notes for insert with check (
    lead_id in (select id from leads where organization_id = user_organization_id())
  );

create policy "Users can delete their own notes"
  on lead_notes for delete using (author_id = auth.uid());

-- BOOKING SLOTS
create policy "Users can view slots for their org properties"
  on booking_slots for select using (
    property_id in (select id from properties where organization_id = user_organization_id())
  );

create policy "Users can manage slots for their org properties"
  on booking_slots for all using (
    property_id in (select id from properties where organization_id = user_organization_id())
  );

-- AVAILABILITY
create policy "Users can view availability in their org"
  on agent_availability for select using (
    agent_id in (select id from profiles where organization_id = user_organization_id())
  );

create policy "Users can manage own availability"
  on agent_availability for all using (agent_id = auth.uid());

-- MESSAGES
create policy "Users can view messages for their org leads"
  on messages for select using (
    lead_id in (select id from leads where organization_id = user_organization_id())
  );

create policy "Users can send messages for their org leads"
  on messages for insert with check (
    lead_id in (select id from leads where organization_id = user_organization_id())
  );

-- AUTOMATED EVENTS
create policy "Users can view events for their org leads"
  on automated_events for select using (
    lead_id in (select id from leads where organization_id = user_organization_id())
  );

-- ============================================================================
-- PUBLIC ACCESS for booking page (geen auth nodig om te kunnen boeken)
-- Dit gebeurt via de API route met service role key, niet rechtstreeks.
-- ============================================================================
