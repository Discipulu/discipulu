import { beforeEach, describe, expect, it, vi } from "vitest";

const CHURCH_A = "22222222-2222-4222-8222-00000000000a";
const CHURCH_B = "22222222-2222-4222-8222-00000000000b";
const USER_ID = "11111111-1111-4111-8111-000000000002";

type Result = { data: unknown; error: { code?: string; message: string } | null };

const state: {
  currentClaims: Record<string, unknown> | null;
  refreshedClaims: Record<string, unknown> | null;
  membership: Result;
  profileUpdate: Result;
  refresh: {
    data: { session: { access_token: string } | null };
    error: { message: string } | null;
  };
} = {
  currentClaims: null,
  refreshedClaims: null,
  membership: { data: null, error: null },
  profileUpdate: { data: null, error: null },
  refresh: { data: { session: null }, error: null },
};

const calls: { table: string; method: string; args: unknown[] }[] = [];

function query(table: string, result: () => Result) {
  const chain: Record<string, unknown> = {
    maybeSingle: async () => result(),
    then: (resolve: (value: Result) => unknown, reject: (reason: unknown) => unknown) =>
      Promise.resolve(result()).then(resolve, reject),
  };
  for (const method of ["select", "update", "eq"]) {
    chain[method] = (...args: unknown[]) => {
      calls.push({ table, method, args });
      return chain;
    };
  }
  return chain;
}

const supabase = {
  auth: {
    getClaims: vi.fn(async (jwt?: string) => {
      const claims = jwt ? state.refreshedClaims : state.currentClaims;
      return { data: claims ? { claims } : null, error: null };
    }),
    refreshSession: vi.fn(async () => state.refresh),
  },
  from: vi.fn((table: string) =>
    query(table, () => (table === "church_members" ? state.membership : state.profileUpdate)),
  ),
};

const revalidatePath = vi.fn();

vi.mock("@/lib/supabase/server", () => ({ createClient: async () => supabase }));
vi.mock("next/cache", () => ({ revalidatePath }));

const { getActiveChurchId, switchActiveChurch } = await import("@/lib/auth/active-church");

function signedIn(activeChurchId: string | null) {
  state.currentClaims = { sub: USER_ID, role: "authenticated", active_church_id: activeChurchId };
}

describe("getActiveChurchId", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("reads active_church_id from the verified claims", async () => {
    signedIn(CHURCH_A);
    expect(await getActiveChurchId()).toBe(CHURCH_A);
  });

  it("returns null when the user has no church", async () => {
    signedIn(null);
    expect(await getActiveChurchId()).toBeNull();
  });

  it("returns null without a session", async () => {
    state.currentClaims = null;
    expect(await getActiveChurchId()).toBeNull();
  });
});

describe("switchActiveChurch", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    calls.length = 0;
    signedIn(CHURCH_A);
    state.membership = { data: { id: "44444444-4444-4444-8444-000000000006" }, error: null };
    state.profileUpdate = { data: [{ user_id: USER_ID }], error: null };
    state.refresh = { data: { session: { access_token: "refreshed-token" } }, error: null };
    state.refreshedClaims = { sub: USER_ID, active_church_id: CHURCH_B };
  });

  it("rejects an id that is not a uuid before calling Supabase", async () => {
    expect(await switchActiveChurch("igreja-b")).toEqual({ ok: false, error: "Igreja inválida." });
    expect(supabase.auth.getClaims).not.toHaveBeenCalled();
    expect(supabase.from).not.toHaveBeenCalled();
  });

  it("asks to sign in again without a session", async () => {
    state.currentClaims = null;

    expect(await switchActiveChurch(CHURCH_B)).toEqual({
      ok: false,
      error: "Sua sessão expirou. Entre de novo.",
    });
    expect(supabase.from).not.toHaveBeenCalled();
  });

  it("refuses a church without an active membership and leaves the profile alone", async () => {
    state.membership = { data: null, error: null };

    expect(await switchActiveChurch(CHURCH_B)).toEqual({
      ok: false,
      error: "Você não tem acesso a esta igreja.",
    });
    expect(calls).toContainEqual({
      table: "church_members",
      method: "eq",
      args: ["status", "active"],
    });
    expect(calls).toContainEqual({
      table: "church_members",
      method: "eq",
      args: ["user_id", USER_ID],
    });
    expect(calls.some((call) => call.method === "update")).toBe(false);
    expect(supabase.auth.refreshSession).not.toHaveBeenCalled();
  });

  it("fails when the membership lookup errors", async () => {
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    state.membership = { data: null, error: { code: "PGRST000", message: "connection lost" } };

    const result = await switchActiveChurch(CHURCH_B);

    expect(result).toEqual({
      ok: false,
      error: "Não foi possível trocar de igreja. Tente de novo.",
    });
    expect(log).toHaveBeenCalled();
    log.mockRestore();
  });

  it("fails when the profile update changes no row", async () => {
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    state.profileUpdate = { data: [], error: null };

    expect(await switchActiveChurch(CHURCH_B)).toMatchObject({ ok: false });
    expect(supabase.auth.refreshSession).not.toHaveBeenCalled();
    log.mockRestore();
  });

  it("fails when the session cannot be refreshed", async () => {
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    state.refresh = { data: { session: null }, error: { message: "refresh_token_not_found" } };

    expect(await switchActiveChurch(CHURCH_B)).toMatchObject({ ok: false });
    expect(revalidatePath).not.toHaveBeenCalled();
    log.mockRestore();
  });

  it("fails when the refreshed token still carries another church", async () => {
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    state.refreshedClaims = { sub: USER_ID, active_church_id: CHURCH_A };

    expect(await switchActiveChurch(CHURCH_B)).toEqual({
      ok: false,
      error: "Não foi possível trocar de igreja. Tente de novo.",
    });
    expect(revalidatePath).not.toHaveBeenCalled();
    log.mockRestore();
  });

  it("updates the profile, refreshes the session and checks the new claim", async () => {
    expect(await switchActiveChurch(CHURCH_B)).toEqual({ ok: true });

    expect(calls).toContainEqual({
      table: "user_profiles",
      method: "update",
      args: [{ active_church_id: CHURCH_B }],
    });
    expect(calls).toContainEqual({
      table: "user_profiles",
      method: "eq",
      args: ["user_id", USER_ID],
    });
    expect(supabase.auth.refreshSession).toHaveBeenCalledOnce();
    expect(supabase.auth.getClaims).toHaveBeenLastCalledWith("refreshed-token");
    expect(revalidatePath).toHaveBeenCalledWith("/", "layout");
  });
});
