"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

export type AuthFormState = {
  error?: string;
  message?: string;
};

const MIN_PASSWORD_LENGTH = 8;

const ERROR_MESSAGES: Record<string, string> = {
  invalid_credentials: "E-mail ou senha incorretos.",
  email_not_confirmed: "Confirme seu e-mail antes de entrar.",
  weak_password: `A senha precisa ter pelo menos ${MIN_PASSWORD_LENGTH} caracteres.`,
  over_email_send_rate_limit: "Muitas tentativas. Aguarde alguns minutos e tente de novo.",
  over_request_rate_limit: "Muitas tentativas. Aguarde alguns minutos e tente de novo.",
};

function readCredentials(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  return { email, password };
}

function toMessage(error: { code?: string; message: string }) {
  const message = error.code && ERROR_MESSAGES[error.code];
  if (message) return message;

  console.error("auth: unexpected error", error.code, error.message);
  return "Não foi possível concluir. Tente de novo.";
}

export async function signIn(_prev: AuthFormState, formData: FormData): Promise<AuthFormState> {
  const { email, password } = readCredentials(formData);
  if (!email || !password) {
    return { error: "Informe e-mail e senha." };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    return { error: toMessage(error) };
  }

  redirect("/app");
}

export async function signUp(_prev: AuthFormState, formData: FormData): Promise<AuthFormState> {
  const { email, password } = readCredentials(formData);
  if (!email || !password) {
    return { error: "Informe e-mail e senha." };
  }
  if (password.length < MIN_PASSWORD_LENGTH) {
    return { error: ERROR_MESSAGES.weak_password };
  }

  const origin = (await headers()).get("origin");
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { emailRedirectTo: origin ? `${origin}/auth/callback` : undefined },
  });
  if (error) {
    return { error: toMessage(error) };
  }

  if (data.session) {
    redirect("/app");
  }

  return { message: "Enviamos um link de confirmação para o seu e-mail." };
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
