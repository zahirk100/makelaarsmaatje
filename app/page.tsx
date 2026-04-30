import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { Logo } from "@/components/Logo";
import type { Lead } from "@/types";

function formatDate(value: string) {
  return new Intl.DateTimeFormat("nl-NL", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

function euro(cents: number | null | undefined) {
  if (!cents) return "Prijs onbekend";
  return new Intl.NumberFormat("nl-NL", {
    style: "currency",
    currency: "EUR",
    maximumFractionDigits: 0,
  }).format(cents / 100);
}

export default async function DashboardPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("full_name, email, organization_id, organizations(name)")
    .eq("id", user.id)
    .single();

  const { data: leads } = await supabase
    .from("leads")
    .select("*, property:properties(address, city, price_cents)")
    .order("created_at", { ascending: false })
    .limit(8);

  const typedLeads = (leads ?? []) as Lead[];
  const newLeads = typedLeads.filter((lead) => lead.status === "new").length;
  const bookedLeads = typedLeads.filter((lead) => lead.status === "booked").length;
  const hotLeads = typedLeads.filter((lead) => lead.priority === "hot").length;

  async function signOut() {
    "use server";
    const { createClient } = await import("@/lib/supabase/server");
    const supabase = createClient();
    await supabase.auth.signOut();
    redirect("/login");
  }

  return (
    <main className="min-h-screen px-4 py-6 md:px-8">
      <div className="mx-auto max-w-6xl">
        <header className="mb-8 flex flex-col gap-4 rounded-3xl border border-[#eadfca] bg-white/80 p-5 shadow-sm md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-4">
            <Logo size={48} />
            <div>
              <p className="text-sm text-[#637363]">Welkom terug</p>
              <h1 className="font-display text-3xl font-bold text-[#1f3d2b]">
                {profile?.full_name ?? user.email}
              </h1>
            </div>
          </div>

          <form action={signOut}>
            <button className="rounded-2xl border border-[#1f3d2b] px-4 py-2 text-sm font-semibold text-[#1f3d2b] hover:bg-[#1f3d2b] hover:text-white">
              Uitloggen
            </button>
          </form>
        </header>

        <section className="grid gap-4 md:grid-cols-3">
          <div className="rounded-3xl bg-[#1f3d2b] p-6 text-white shadow-lg">
            <p className="text-sm opacity-80">Nieuwe leads</p>
            <p className="mt-3 text-4xl font-bold">{newLeads}</p>
          </div>
          <div className="rounded-3xl bg-white/90 p-6 shadow-lg border border-[#eadfca]">
            <p className="text-sm text-[#637363]">Ingeplande bezichtigingen</p>
            <p className="mt-3 text-4xl font-bold text-[#1f3d2b]">{bookedLeads}</p>
          </div>
          <div className="rounded-3xl bg-white/90 p-6 shadow-lg border border-[#eadfca]">
            <p className="text-sm text-[#637363]">Hot leads</p>
            <p className="mt-3 text-4xl font-bold text-[#c8821a]">{hotLeads}</p>
          </div>
        </section>

        <section className="mt-8 rounded-3xl border border-[#eadfca] bg-white/90 p-5 shadow-lg">
          <div className="mb-5 flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
            <div>
              <h2 className="font-display text-2xl font-bold">Laatste leads</h2>
              <p className="text-sm text-[#637363]">De nieuwste aanvragen uit je Supabase database.</p>
            </div>
          </div>

          {typedLeads.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-[#d8cdb8] p-8 text-center">
              <h3 className="font-semibold">Nog geen leads gevonden</h3>
              <p className="mt-2 text-sm text-[#637363]">
                Zodra je seed-data of echte Funda-leads binnenkomen, verschijnen ze hier.
              </p>
            </div>
          ) : (
            <div className="overflow-hidden rounded-2xl border border-[#eadfca]">
              <table className="w-full text-left text-sm">
                <thead className="bg-[#f6efe2] text-[#637363]">
                  <tr>
                    <th className="px-4 py-3">Lead</th>
                    <th className="px-4 py-3">Woning</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Prioriteit</th>
                    <th className="px-4 py-3">Binnengekomen</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#eadfca] bg-white">
                  {typedLeads.map((lead) => (
                    <tr key={lead.id} className="hover:bg-[#fbf7ef]">
                      <td className="px-4 py-4">
                        <div className="font-semibold text-[#1f3d2b]">{lead.name}</div>
                        <div className="text-xs text-[#637363]">{lead.email ?? lead.phone ?? "Geen contactgegevens"}</div>
                      </td>
                      <td className="px-4 py-4">
                        <div>{lead.property?.address ?? "Geen woning gekoppeld"}</div>
                        <div className="text-xs text-[#637363]">{lead.property?.city ?? ""} {euro(lead.property?.price_cents)}</div>
                      </td>
                      <td className="px-4 py-4">
                        <span className="rounded-full bg-[#eef3ed] px-3 py-1 text-xs font-semibold text-[#1f3d2b]">
                          {lead.status}
                        </span>
                      </td>
                      <td className="px-4 py-4 capitalize">{lead.priority}</td>
                      <td className="px-4 py-4 text-[#637363]">{formatDate(lead.created_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
