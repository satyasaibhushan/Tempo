// Local demo mode (README, "Local demo"): one fixed fictional account instead of Auth0, authorised against a
// local Convex deployment by that deployment's admin key acting as this identity. It is on only when
// NEXT_PUBLIC_TEMPO_DEMO=1 and the Convex URL is local, so a deployed build can never enter it.
export const DEMO_IDENTITY = {
  tokenIdentifier: "https://demo-tempo.invalid/|auth0|demo-maya",
  issuer: "https://demo-tempo.invalid/",
  subject: "auth0|demo-maya",
  name: "Maya Iyer",
  email: "maya.iyer@example.com",
};

const convexUrl = process.env.NEXT_PUBLIC_CONVEX_URL ?? "";
export const demoEnabled =
  process.env.NEXT_PUBLIC_TEMPO_DEMO === "1" && /^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?\/?$/.test(convexUrl);

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
