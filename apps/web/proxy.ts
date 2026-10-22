import { NextResponse } from "next/server";

import { auth0 } from "./lib/auth0";
import { demoEnabled } from "./lib/demo";

export async function proxy(request: Request) {
  if (demoEnabled) return NextResponse.next();
  return await auth0.middleware(request);
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|sitemap.xml|robots.txt).*)"],
};
