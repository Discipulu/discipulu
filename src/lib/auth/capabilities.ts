import "server-only";

import { cache } from "react";

import { createClient } from "@/lib/supabase/server";

export type Capability =
  | "attendance.record"
  | "audit.read"
  | "church.billing"
  | "church.manage"
  | "classes.manage"
  | "congregations.manage"
  | "enrollments.manage"
  | "members.manage"
  | "members.manage_owners"
  | "people.export"
  | "people.read"
  | "people.read_roster"
  | "people.read_sensitive"
  | "people.write"
  | "reports.read"
  | "sunday.close";

export const getCapabilities = cache(async (): Promise<ReadonlySet<string>> => {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("current_capabilities");
  if (error) {
    throw new Error(`capabilities: ${error.code ?? ""} ${error.message}`.trim());
  }
  return new Set(data);
});

export async function can(capability: Capability) {
  return (await getCapabilities()).has(capability);
}
