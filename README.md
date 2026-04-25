# Makelaarsmaatje

Snellere lead-opvolging voor makelaars, zonder heen-en-weer mailen.

Een Next.js + Supabase applicatie die Funda-leads automatisch verwerkt, kwalificeert, en bezichtigingen laat boeken via een self-service link.

---

## Wat deze repo bevat

Dit is de **fundering** van de app: database-schema, auth-setup, Supabase-integratie, middleware, types en utilities. De UI-pagina's worden in een volgende iteratie toegevoegd.

### Structuur

```
makelaarsmaatje/
├── app/                    # Next.js App Router pagina's (komt in volgende stap)
│   ├── globals.css         # Globale styling + animaties
│   ├── layout.tsx          # Root layout
│   └── page.tsx            # Homepage (redirect naar /dashboard)
├── components/
│   ├── Logo.tsx            # Makelaarsmaatje logo
│   └── Toast.tsx           # Notificaties
├── lib/
│   ├── supabase/
│   │   ├── client.ts       # Browser client
│   │   └── server.ts       # Server client + service role
│   └── utils.ts            # Helpers (scoring, formatters, AI-reply)
├── supabase/migrations/
│   ├── 001_initial_schema.sql   # Volledig database-schema met RLS
│   └── 002_seed_data.sql        # Demo-data
├── types/index.ts          # TypeScript types
├── middleware.ts           # Auth-protection + session refresh
├── .env.example            # Environment variables template
└── package.json
```

---

## Setup in 7 stappen

### 1. Clone en installeer

```bash
git clone <jouw-github-url> makelaarsmaatje
cd makelaarsmaatje
npm install
```

### 2. Maak een Supabase project aan

Ga naar [supabase.com](https://supabase.com) en maak een nieuw project. Kies een sterk database-wachtwoord en bewaar het. Wacht tot het project klaar is (ongeveer 2 minuten).

### 3. Draai het database-schema

In het Supabase dashboard: ga naar **SQL Editor** → **New query**.

Open `supabase/migrations/001_initial_schema.sql`, kopieer de volledige inhoud, plak in de SQL editor, klik **Run**. Je ziet "Success" als alles goed ging.

Dit maakt alle tabellen aan: organizations, profiles, properties, leads, notes, slots, messages, automated_events. Plus Row Level Security zodat elke makelaar alleen zijn eigen kantoor-data ziet.

### 4. Environment variables

```bash
cp .env.example .env.local
```

In Supabase: ga naar **Project Settings** → **API**. Kopieer:
- `Project URL` → `NEXT_PUBLIC_SUPABASE_URL`
- `anon public` key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `service_role` key → `SUPABASE_SERVICE_ROLE_KEY` (⚠️ geheim, nooit committen!)

Verzin een lange random string voor `WEBHOOK_SECRET` (voor het beveiligen van de Funda webhook).

Zet `NEXT_PUBLIC_APP_URL=http://localhost:3000` voor lokaal.

### 5. Start lokaal

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). Eerste keer krijg je een login-scherm (komt in volgende stap).

### 6. Registreer jezelf en vul de demo-data

1. Registreer een account via Supabase Dashboard → **Authentication** → **Users** → **Add user** (of via de login-pagina zodra die klaar is).
2. Open `supabase/migrations/002_seed_data.sql`, **pas het e-mailadres aan** naar jouw eigen adres op regel 14.
3. Draai dit bestand in de SQL Editor. Dit koppelt jouw user aan het demo-kantoor "Vermeulen Vastgoed" en voegt demo-leads toe.

### 7. Push naar GitHub en deploy op Vercel

```bash
git add .
git commit -m "Initial commit: fundering Makelaarsmaatje"
git remote add origin https://github.com/<jouw-username>/makelaarsmaatje.git
git push -u origin main
```

Dan op [vercel.com](https://vercel.com): **Add New Project** → importeer je GitHub repo → vul dezelfde environment variables in → Deploy.

Pas `NEXT_PUBLIC_APP_URL` aan naar je Vercel URL zodra die bekend is.

---

## Database-schema uitleg

### Organizations
Elk makelaarskantoor is een organisatie. Meerdere makelaars horen bij één org.

### Profiles
Gekoppeld 1-op-1 aan `auth.users`. Bevat naam, initialen, rol (admin/makelaar), kleur.
**Belangrijk**: een trigger maakt automatisch een profile aan bij signup.

### Properties
Woningen in portefeuille, met verkoper-gegevens voor wekelijkse rapportages.

### Leads
De kern. Bevat contact-info, bericht, kwalificatie (budget, financiering, tijdlijn), score, status. Linkt optioneel aan een property en een toegewezen makelaar.

### Lead notes
Notities die makelaars bij leads kunnen zetten. Meerdere per lead, met auteur.

### Booking slots & availability
Beschikbare bezichtigingsmomenten en reguliere werktijden per makelaar.

### Messages
Historie van alle berichten (binnenkomend/uitgaand) per lead, per kanaal (email, WhatsApp, Funda).

### Automated events
Geplande herinneringen (24u/2u voor bezichtiging) en follow-ups (2u/3d erna).

---

## Row Level Security (belangrijk!)

Elke tabel heeft RLS-policies die ervoor zorgen dat:
- Makelaar A kan alleen leads van zijn eigen kantoor zien
- Notes zijn alleen zichtbaar als je bij het kantoor van de lead hoort
- Je kunt alleen je eigen beschikbaarheid aanpassen

Dit gebeurt automatisch — je hoeft niks te doen in je query-code. Als je een lead opvraagt via `supabase.from('leads').select()`, krijg je alleen de leads waar je rechten op hebt.

Voor de publieke booking-pagina (waar een koper zonder login een afspraak moet kunnen maken) gebruik je de **service role key** in een API route, die RLS omzeilt. Let op: deze key mag NOOIT in client-side code terechtkomen.

---

## Volgende stappen

De UI-pagina's volgen in de volgende iteratie:
- `/login` — Register & login flow
- `/dashboard` — Leads-overzicht met zoek/filter
- `/lead/[id]` — Lead-detail met chat-weergave, notities, slots, automatische flow
- `/agenda` — Teamagenda
- `/boek/[leadId]` — Publieke booking-pagina (wat de klant ziet)
- `/verkoper` — Wekelijkse rapportages
- `/statistieken` — KPI dashboard
- `/instellingen` — Beschikbaarheid, team, koppelingen

En de integraties:
- `/api/webhooks/funda-lead` — Webhook voor inkomende Funda-mails (via Zapier/Make.com)
- `/api/messages/send` — WhatsApp/e-mail verzenden via Twilio
- Cron-job voor herinneringen en follow-ups

---

## Funda-koppeling: hoe werkt het?

Funda heeft geen open API. Oplossing: maak een e-mailadres `leads@jouwdomein.nl`. Makelaars stellen in Funda in dat leads naar dit adres gaan. Een service zoals Zapier, Make.com of Postmark parseert de mail en stuurt de data naar `/api/webhooks/funda-lead`. Het endpoint maakt een nieuwe `lead` record aan, triggert de AI-scoring, en stuurt eventueel automatisch een WhatsApp met boekingslink.

---

## Stack

- **Framework**: Next.js 14 (App Router)
- **Database**: Supabase (Postgres + Auth + RLS)
- **Styling**: Tailwind CSS
- **Icons**: Lucide React
- **Hosting**: Vercel
- **Taal**: TypeScript

---

## Licentie

Proprietary. Bouw gerust verder, maar vraag eerst toestemming voor commercieel gebruik.
