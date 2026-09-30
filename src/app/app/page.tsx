import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { Button } from "@/components/ui/button";
import { signOut } from "@/features/auth/actions";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Painel · Discipulu" };

export default async function AppHomePage() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  if (!data?.claims) {
    redirect("/login");
  }

  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-2xl font-semibold tracking-tight">Painel</h1>
      <p className="text-muted-foreground">
        Conectado como <span className="text-foreground">{data.claims.email}</span>
      </p>
      <form action={signOut}>
        <Button type="submit" variant="outline">
          Sair
        </Button>
      </form>
    </main>
  );
}
