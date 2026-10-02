"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

export type SwitchActiveChurchResult = { ok: true } | { ok: false; error: string };

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const GENERIC_ERROR = "Não foi possível trocar de igreja. Tente de novo.";

function activeChurchIdFrom(claims: Record<string, unknown> | undefined) {
  const value = claims?.active_church_id;
  return typeof value === "string" && value ? value : null;
}

function failure(error: string): SwitchActiveChurchResult {
  return { ok: false, error };
}

export async function getActiveChurchId(): Promise<string | null> {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  return activeChurchIdFrom(data?.claims);
}

export async function switchActiveChurch(churchId: string): Promise<SwitchActiveChurchResult> {
  if (typeof churchId !== "string" || !UUID_PATTERN.test(churchId)) {
    return failure("Igreja inválida.");
  }

  const supabase = await createClient();
  const { data: current } = await supabase.auth.getClaims();
  const userId = current?.claims.sub;
  if (!userId) {
    return failure("Sua sessão expirou. Entre de novo.");
  }

  const { data: membership, error: membershipError } = await supabase
    .from("church_members")
    .select("id")
    .eq("church_id", churchId)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();
  if (membershipError) {
    console.error(
      "active-church: membership lookup failed",
      membershipError.code,
      membershipError.message,
    );
    return failure(GENERIC_ERROR);
  }
  if (!membership) {
    return failure("Você não tem acesso a esta igreja.");
  }

  const { data: updated, error: updateError } = await supabase
    .from("user_profiles")
    .update({ active_church_id: churchId })
    .eq("user_id", userId)
    .select("user_id");
  if (updateError || !updated?.length) {
    console.error("active-church: profile update failed", updateError?.code, updateError?.message);
    return failure(GENERIC_ERROR);
  }

  const { data: refreshed, error: refreshError } = await supabase.auth.refreshSession();
  if (refreshError || !refreshed.session) {
    console.error(
      "active-church: session refresh failed",
      refreshError?.code,
      refreshError?.message,
    );
    return failure(GENERIC_ERROR);
  }

  // The hook falls back to another church when the membership is no longer valid, so the
  // refreshed token is checked instead of trusting the profile update.
  const { data: verified } = await supabase.auth.getClaims(refreshed.session.access_token);
  if (activeChurchIdFrom(verified?.claims) !== churchId) {
    console.error("active-church: refreshed token kept another church");
    return failure(GENERIC_ERROR);
  }

  revalidatePath("/", "layout");
  return { ok: true };
}
