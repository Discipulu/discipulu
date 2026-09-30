import type { Metadata } from "next";
import Link from "next/link";

import { signIn } from "@/features/auth/actions";
import { AuthForm } from "@/features/auth/auth-form";

export const metadata: Metadata = { title: "Entrar · Discipulu" };

export default async function LoginPage({ searchParams }: PageProps<"/login">) {
  const { error } = await searchParams;

  return (
    <>
      <h1 className="text-2xl font-semibold tracking-tight">Entrar</h1>
      {error === "link" && (
        <p role="alert" className="text-sm text-destructive">
          O link de confirmação é inválido ou expirou. Entre ou crie a conta de novo.
        </p>
      )}
      <AuthForm action={signIn} submitLabel="Entrar" passwordAutoComplete="current-password" />
      <p className="text-sm text-muted-foreground">
        Ainda não tem conta?{" "}
        <Link href="/signup" className="text-foreground underline underline-offset-4">
          Criar conta
        </Link>
      </p>
    </>
  );
}
