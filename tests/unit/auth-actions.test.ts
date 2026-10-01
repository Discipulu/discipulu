import { beforeEach, describe, expect, it, vi } from "vitest";

const auth = {
  signInWithPassword: vi.fn(),
  signUp: vi.fn(),
  signOut: vi.fn(),
};

vi.mock("@/lib/supabase/server", () => ({
  createClient: async () => ({ auth }),
}));

vi.mock("next/headers", () => ({
  headers: async () => new Headers({ origin: "https://app.exemplo.test" }),
}));

vi.mock("next/navigation", () => ({
  redirect: (url: string) => {
    throw new Error(`redirect:${url}`);
  },
}));

const { signIn, signUp } = await import("@/features/auth/actions");

function form(fields: Record<string, string>) {
  const data = new FormData();
  for (const [key, value] of Object.entries(fields)) data.set(key, value);
  return data;
}

describe("signIn", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("asks for email and password", async () => {
    expect(await signIn({}, form({ email: " " }))).toEqual({
      email: "",
      error: "Informe e-mail e senha.",
    });
    expect(auth.signInWithPassword).not.toHaveBeenCalled();
  });

  it("translates known auth errors", async () => {
    auth.signInWithPassword.mockResolvedValue({
      error: { code: "invalid_credentials", message: "Invalid login credentials" },
    });

    const state = await signIn({}, form({ email: "ana@exemplo.test", password: "errada123" }));

    expect(state).toEqual({ email: "ana@exemplo.test", error: "E-mail ou senha incorretos." });
    expect(auth.signInWithPassword).toHaveBeenCalledWith({
      email: "ana@exemplo.test",
      password: "errada123",
    });
  });

  it("falls back to a generic message and logs unknown errors", async () => {
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    auth.signInWithPassword.mockResolvedValue({
      error: { code: "unexpected_failure", message: "Error sending email" },
    });

    const state = await signIn({}, form({ email: "ana@exemplo.test", password: "senha1234" }));

    expect(state).toEqual({
      email: "ana@exemplo.test",
      error: "Não foi possível concluir. Tente de novo.",
    });
    expect(log).toHaveBeenCalled();
    log.mockRestore();
  });

  it("redirects to /app on success", async () => {
    auth.signInWithPassword.mockResolvedValue({ error: null });

    await expect(
      signIn({}, form({ email: "ana@exemplo.test", password: "senha1234" })),
    ).rejects.toThrow("redirect:/app");
  });
});

describe("signUp", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("rejects short passwords before calling Supabase", async () => {
    const state = await signUp({}, form({ email: "ana@exemplo.test", password: "1234567" }));

    expect(state).toEqual({
      email: "ana@exemplo.test",
      error: "A senha precisa ter pelo menos 8 caracteres.",
    });
    expect(auth.signUp).not.toHaveBeenCalled();
  });

  it("sends the confirmation link back to the request origin", async () => {
    auth.signUp.mockResolvedValue({ data: { session: null }, error: null });

    const state = await signUp({}, form({ email: "ana@exemplo.test", password: "senha1234" }));

    expect(state).toEqual({ confirmationSentTo: "ana@exemplo.test" });
    expect(auth.signUp).toHaveBeenCalledWith({
      email: "ana@exemplo.test",
      password: "senha1234",
      options: { emailRedirectTo: "https://app.exemplo.test/auth/callback" },
    });
  });
});
