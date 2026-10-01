"use client";

import Link from "next/link";
import { useActionState } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import type { AuthFormState } from "./actions";

type AuthFormProps = {
  action: (prev: AuthFormState, formData: FormData) => Promise<AuthFormState>;
  submitLabel: string;
  passwordAutoComplete: "current-password" | "new-password";
};

export function AuthForm({ action, submitLabel, passwordAutoComplete }: AuthFormProps) {
  const [state, formAction, pending] = useActionState(action, {});

  if (state.confirmationSentTo) {
    return (
      <div role="status" className="grid gap-3 rounded-lg border p-6">
        <h2 className="text-lg font-semibold">Confira seu e-mail</h2>
        <p className="text-sm text-muted-foreground">
          Enviamos um link de confirmação para{" "}
          <span className="font-medium text-foreground">{state.confirmationSentTo}</span>. Abra o
          link para ativar a conta. Se não encontrar, olhe também a caixa de spam.
        </p>
        <Link href="/login" className="text-sm underline underline-offset-4">
          Já confirmei, quero entrar
        </Link>
      </div>
    );
  }

  return (
    <form action={formAction} className="grid gap-4">
      <div className="grid gap-2">
        <Label htmlFor="email">E-mail</Label>
        <Input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          defaultValue={state.email}
          key={state.email}
          required
        />
      </div>
      <div className="grid gap-2">
        <Label htmlFor="password">Senha</Label>
        <Input
          id="password"
          name="password"
          type="password"
          autoComplete={passwordAutoComplete}
          required
        />
      </div>
      {state.error && (
        <p role="alert" className="text-sm text-destructive">
          {state.error}
        </p>
      )}
      <Button type="submit" disabled={pending}>
        {pending ? "Aguarde…" : submitLabel}
      </Button>
    </form>
  );
}
