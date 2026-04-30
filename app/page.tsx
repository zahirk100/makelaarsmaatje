"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Logo } from "@/components/Logo";

export default function LoginPage() {
  const router = useRouter();
  const supabase = createClient();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError(null);

    const { error } = await supabase.auth.signInWithPassword({ email, password });

    setLoading(false);

    if (error) {
      setError("Inloggen mislukt. Controleer je e-mailadres en wachtwoord.");
      return;
    }

    router.refresh();
    router.push("/dashboard");
  }

  return (
    <main className="min-h-screen flex items-center justify-center px-4 py-10">
      <section className="w-full max-w-md rounded-3xl bg-white/90 p-8 shadow-xl border border-[#eadfca]">
        <div className="flex items-center gap-3 mb-8">
          <Logo size={44} />
          <div>
            <h1 className="font-display text-3xl font-bold text-[#1f3d2b]">Makelaarsmaatje</h1>
            <p className="text-sm text-[#637363]">Log in op je dashboard</p>
          </div>
        </div>

        <form onSubmit={handleLogin} className="space-y-5">
          <div>
            <label className="block text-sm font-semibold mb-2" htmlFor="email">
              E-mailadres
            </label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="w-full rounded-2xl border border-[#d8cdb8] bg-white px-4 py-3 outline-none focus:ring-2 focus:ring-[#c8821a]"
              placeholder="jij@kantoor.nl"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold mb-2" htmlFor="password">
              Wachtwoord
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="w-full rounded-2xl border border-[#d8cdb8] bg-white px-4 py-3 outline-none focus:ring-2 focus:ring-[#c8821a]"
              placeholder="••••••••"
            />
          </div>

          {error ? (
            <div className="rounded-2xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
              {error}
            </div>
          ) : null}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-2xl bg-[#1f3d2b] px-4 py-3 font-semibold text-white shadow-lg transition hover:opacity-95 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? "Bezig met inloggen..." : "Inloggen"}
          </button>
        </form>
      </section>
    </main>
  );
}
