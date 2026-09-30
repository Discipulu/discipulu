import type { Metadata } from "next";
import Link from "next/link";

import { signUp } from "@/features/auth/actions";
import { AuthForm } from "@/features/auth/auth-form";

export const metadata: Metadata = { title: "Criar conta · Discipulu" };

export default function SignupPage() {
  return (
    <>
      <h1 className="text-2xl font-semibold tracking-tight">Criar conta</h1>
      <AuthForm action={signUp} submitLabel="Criar conta" passwordAutoComplete="new-password" />
      <p className="text-sm text-muted-foreground">
        Já tem conta?{" "}
        <Link href="/login" className="text-foreground underline underline-offset-4">
          Entrar
        </Link>
      </p>
    </>
  );
}
