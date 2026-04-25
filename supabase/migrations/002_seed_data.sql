-- ============================================================================
-- SEED DATA - Voer dit optioneel uit NA 001_initial_schema.sql
-- Dit maakt Vermeulen Vastgoed als demo-kantoor aan met dummy data.
-- Je moet EERST jezelf registreren via /login, dan pas deze seed draaien.
-- Pas het e-mailadres hieronder aan naar jouw eigen e-mail!
-- ============================================================================

-- 1. Maak de organisatie aan
insert into organizations (id, name, slug) values
  ('00000000-0000-0000-0000-000000000001', 'Vermeulen Vastgoed', 'vermeulen-vastgoed');

-- 2. Koppel JOUW user aan deze organisatie (pas email aan!)
update profiles
set
  organization_id = '00000000-0000-0000-0000-000000000001',
  full_name = 'Sander Vermeulen',
  initials = 'SV',
  role = 'admin',
  color = '#1F3D2B'
where email = 'zahir55399@gmail.com';

-- 3. Demo-woningen
insert into properties (id, organization_id, address, city, price_cents, size_m2, seller_name) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Prinsengracht 421', 'Amsterdam', 87500000, 112, 'Familie De Jong'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Keizersgracht 118', 'Amsterdam', 125000000, 145, 'R.W. Janssens'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Vondelstraat 88', 'Amsterdam', 69500000, 98, 'Mw. K. Bosman'),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Herengracht 502', 'Amsterdam', 185000000, 210, 'Heren De Wit');

-- 4. Demo-leads
insert into leads (organization_id, property_id, name, email, phone, message, status, priority, score, qualified, budget_range, financing_status, timeline) values
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Sophie van Dijk', 'sophie.vandijk@gmail.com', '+31 6 12345678',
   'Goedemiddag, ik zag uw woning aan de Prinsengracht op Funda en ben erg enthousiast. Graag zou ik een bezichtiging willen inplannen.',
   'new', 'hot', 92, true, '€800k tot €950k', 'Pre-approval aanwezig', 'Binnen 3 maanden'),
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Mark de Boer', 'm.deboer@outlook.com', '+31 6 87654321',
   'Interesse in de woning. Zou graag meer info willen over de VvE bijdrage.',
   'contacted', 'warm', 74, true, '€1.1M tot €1.3M', 'In aanvraag', '3 tot 6 maanden'),
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'Aisha Yilmaz', 'aisha.y@gmail.com', '+31 6 11223344',
   'Hallo, ik ben geïnteresseerd in deze woning.',
   'booked', 'warm', 85, true, '€650k tot €750k', 'Pre-approval aanwezig', 'Binnen 3 maanden'),
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000004', 'Thomas Bakker', 'tbakker@ziggo.nl', '+31 6 99887766',
   'Graag bezichtiging zaterdag. Serieuze koper.',
   'booked', 'hot', 96, true, '€1.7M tot €2M', 'Contant', 'Direct');
