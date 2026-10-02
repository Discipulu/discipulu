import { beforeEach, describe, expect, it, vi } from "vitest";

const rpc = vi.fn();

vi.mock("server-only", () => ({}));
vi.mock("@/lib/supabase/server", () => ({ createClient: async () => ({ rpc }) }));

const { can, getCapabilities } = await import("@/lib/auth/capabilities");

describe("can", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("asks the database for the capabilities in the active church", async () => {
    rpc.mockResolvedValue({ data: ["attendance.record", "people.read_roster"], error: null });

    expect(await getCapabilities()).toEqual(new Set(["attendance.record", "people.read_roster"]));
    expect(rpc).toHaveBeenCalledWith("current_capabilities");
  });

  it("allows a capability the member has", async () => {
    rpc.mockResolvedValue({
      data: ["attendance.record", "people.read_roster", "reports.read"],
      error: null,
    });

    expect(await can("people.read_roster")).toBe(true);
  });

  it("denies a capability the member lacks", async () => {
    rpc.mockResolvedValue({ data: ["reports.read"], error: null });

    expect(await can("people.read_roster")).toBe(false);
    expect(await can("people.read")).toBe(false);
  });

  it("denies everything without an active church", async () => {
    rpc.mockResolvedValue({ data: [], error: null });

    expect(await can("reports.read")).toBe(false);
  });

  it("throws instead of denying when the database fails", async () => {
    rpc.mockResolvedValue({ data: null, error: { code: "PGRST202", message: "not found" } });

    await expect(can("reports.read")).rejects.toThrow("capabilities: PGRST202 not found");
  });
});
