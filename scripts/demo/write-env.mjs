// Writes apps/web/.env.local for the local demo (README, "Local demo"): the local Convex deployment's URL and
// admin key from .convex/local/default/config.json, the demo switch, and placeholder Auth0 values that the
// demo never uses. Refuses to overwrite an existing file.
//   node scripts/demo/write-env.mjs
import { existsSync, readFileSync, writeFileSync } from "node:fs";

const target = new URL("../../apps/web/.env.local", import.meta.url);
if (existsSync(target)) throw new Error("apps/web/.env.local already exists; remove it first if it should be replaced");
const config = JSON.parse(readFileSync(new URL("../../.convex/local/default/config.json", import.meta.url), "utf8"));
writeFileSync(target, `# Local demo configuration (README, "Local demo"). Fictional account; never deployed.
NEXT_PUBLIC_APP_URL=http://localhost:3003
APP_BASE_URL=http://localhost:3003
NEXT_PUBLIC_CONVEX_URL=http://127.0.0.1:${config.ports.cloud}
NEXT_PUBLIC_TEMPO_DEMO=1
NEXT_PUBLIC_TEMPO_DEMO_ADMIN_KEY=${config.adminKey}
AUTH0_SECRET=demo-only-placeholder-secret-0123456789abcdef0123456789
AUTH0_DOMAIN=demo-tempo.invalid
AUTH0_CLIENT_ID=demo-client
AUTH0_CLIENT_SECRET=demo-client-secret
`);
console.log("wrote apps/web/.env.local for the local demo");
