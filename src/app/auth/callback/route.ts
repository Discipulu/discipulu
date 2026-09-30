import { NextResponse, type NextRequest } from "next/server";

import { createClient } from "@/lib/supabase/server";

// Relative Location on purpose: under `next start`, request.nextUrl carries the server's bind
// address (e.g. localhost:3000 inside Docker), not the host the browser used.
function redirectTo(path: string) {
  return new NextResponse(null, { status: 307, headers: { Location: path } });
}

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return redirectTo("/app");
    }
  }

  return redirectTo("/login?error=link");
}
