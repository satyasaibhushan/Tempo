// Local demo mode (README, "Local demo"): one fixed fictional account instead of Auth0, authorised against a
// local Convex deployment by that deployment's admin key acting as this identity. It is on only when
// NEXT_PUBLIC_TEMPO_DEMO=1 and the Convex URL is loopback, which a visitor's browser can only resolve to their own
// machine. NEXT_PUBLIC_ values are inlined at build time, so next.config.ts also refuses to build with either demo
// variable on Vercel or against a non-loopback Convex URL: no deployable bundle carries the switch or the key.
export const DEMO_IDENTITY = {
  tokenIdentifier: "https://demo-tempo.invalid/|auth0|demo-maya",
  issuer: "https://demo-tempo.invalid/",
  subject: "auth0|demo-maya",
  name: "Maya Iyer",
  email: "maya.iyer@example.com",
};

const DEMO_VARIABLES = ["NEXT_PUBLIC_TEMPO_DEMO", "NEXT_PUBLIC_TEMPO_DEMO_ADMIN_KEY"] as const;

export function isLoopbackConvexUrl(convexUrl: string | undefined): boolean {
  return /^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?\/?$/.test(convexUrl ?? "");
}

export function isDemoMode(demoFlag: string | undefined, convexUrl: string | undefined): boolean {
  return demoFlag === "1" && isLoopbackConvexUrl(convexUrl);
}

// The reason a build must not proceed with this environment, or null when it may.
export function demoBuildProblem(env: Record<string, string | undefined>): string | null {
  const present = DEMO_VARIABLES.filter((name) => env[name] !== undefined && env[name] !== "");
  if (present.length === 0) return null;
  if (env.VERCEL) return `${present.join(" and ")} are local-demo only and must not be set on Vercel`;
  if (!isLoopbackConvexUrl(env.NEXT_PUBLIC_CONVEX_URL)) {
    return `${present.join(" and ")} are local-demo only and need a loopback NEXT_PUBLIC_CONVEX_URL`;
  }
  return null;
}

// Literal process.env.NEXT_PUBLIC_* reads so Next inlines them into client bundles.
export const demoEnabled = isDemoMode(process.env.NEXT_PUBLIC_TEMPO_DEMO, process.env.NEXT_PUBLIC_CONVEX_URL);

type DemoSessionUser = {
  sub: string;
  name: string;
  email: string;
  nickname?: string;
  picture?: string;
};

export const demoSession: { user: DemoSessionUser } | null = demoEnabled
  ? { user: { sub: DEMO_IDENTITY.subject, name: DEMO_IDENTITY.name, email: DEMO_IDENTITY.email } }
  : null;
