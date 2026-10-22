# Tempo

A personal time tracker: a timer started on the web can be picked up on an
iPhone or Mac, and every finished session stays in one log with folders and
labels. The Web MVP and native iOS app share the same Convex backend and Auth0
identity model. Native macOS development uses the same SwiftUI feature layer
and timer sync behavior.

## Demo

![Tempo: a session started on the Now page, paused, resumed and stopped, then listed in the log with the rest of the week](docs/demo/demo.gif)

The recording is the real web app (production build) in its local demo mode, against a local Convex deployment
seeded with a fictional week through the app's own mutations (`scripts/demo/`, see [Local demo](#local-demo)).
Still: [docs/demo/poster.png](docs/demo/poster.png). Video: [demo.webm](docs/demo/demo.webm), [demo.mp4](docs/demo/demo.mp4).
The same recording plays on the public landing page.

Live at https://tempo.bhushan.fun. Signed-out visitors get the landing page; the app itself needs an Auth0 login.

## Stack

- Web: Next.js 16 (App Router), React 19, Tailwind CSS 4 with Base UI components, `@auth0/nextjs-auth0`
- Backend: Convex (schema, queries, mutations in `convex/`), Auth0 as the OIDC provider
- Apple: SwiftUI iOS and macOS targets in `apps/apple` sharing one Swift core
- Shared TypeScript domain, formatting, and constants in `packages/shared`

The `pnpm` monorepo contains:

- `apps/web` for the Next.js web app
- `apps/apple` for the shared Swift core plus native iOS and macOS targets
- `convex` for backend code
- `packages/shared` for shared TypeScript code

## Getting Started

```bash
pnpm install
pnpm dev
```

The web app runs on `http://localhost:3003`.

## Environment Conventions

- Web app auth and browser runtime env file: `apps/web/.env.local`
- Web app example env file: `apps/web/.env.example`
- Convex CLI writes deployment metadata to the repo root `.env.local`
- Convex secrets are managed in Convex, not in a committed env file
- Convex env notes live in `convex/README.md`

Setup flow:

```bash
cp apps/web/.env.example apps/web/.env.local
```

Then copy `CONVEX_URL` from the repo root `.env.local` into
`apps/web/.env.local` as `NEXT_PUBLIC_CONVEX_URL`.

For local Auth0 setup, register these URLs in your Auth0 application:

- Allowed Callback URL: `http://localhost:3003/auth/callback`
- Allowed Logout URL: `http://localhost:3003`

## Local demo

Demo mode replaces Auth0 with one fixed fictional account (`apps/web/lib/demo.ts`). It turns on only when
`NEXT_PUBLIC_TEMPO_DEMO=1` and the Convex URL is loopback, and it authorises the Convex client with the local
deployment's admin key acting as that identity, so every page, query, and mutation is the real one.
`apps/web/next.config.ts` fails any build that sets either demo variable on Vercel or with a non-loopback Convex URL. The scripts in
`scripts/demo/` need no Convex account: `npx convex dev` in anonymous mode runs a local backend.

```bash
pnpm install
CONVEX_AGENT_MODE=anonymous npx convex dev          # local deployment on http://127.0.0.1:3210; keep it running
# convex/auth.config.ts reads these names; the values are never contacted in demo mode
for kv in AUTH0_DOMAIN=demo-tempo.invalid AUTH0_CLIENT_ID=demo-client AUTH0_NATIVE_CLIENT_ID=demo-native-client; do
  CONVEX_AGENT_MODE=anonymous npx convex env set ${kv%%=*} ${kv#*=}
done
node scripts/demo/seed.mjs                           # labels, folders, and a week of fictional entries
node scripts/demo/write-env.mjs                      # apps/web/.env.local for demo mode
pnpm --filter @tempo/web build && pnpm --filter @tempo/web start   # or pnpm dev
PLAYWRIGHT_MODULE=/path/to/node_modules/playwright/index.js node scripts/demo/capture.mjs
```

`capture.mjs` starts, pauses, resumes and stops one session and opens the log, writing `docs/demo/poster.png` and
`demo.webm`, plus `demo.mp4` and `demo.gif` when `ffmpeg` is on `PATH`. It removes its own earlier takes first, so it
can be rerun. Playwright is not a project dependency.

## Status and limitations

- The web app is deployed at https://tempo.bhushan.fun with Convex and Auth0; the native targets are built from
  `apps/apple/Tempo.xcodeproj`, and the landing page links a Mac preview build from GitHub releases.
- One account, no workspaces or sharing: folders, labels, and entries belong to the signed-in user.
- Demo mode cannot activate on a deployed build: it requires a local Convex URL, and the admin key it uses belongs
  to a throwaway local deployment.

## Roadmap

1. Deploy the Next.js web app and Convex backend.
2. Run the production smoke test.
3. Build and QA the native iOS and macOS targets from `apps/apple/Tempo.xcodeproj`.

## Production Deployment

The Vercel project uses `apps/web` as its Root Directory. Its committed
`vercel-build` script deploys the Convex functions before building Next.js, so
the frontend and backend always come from the same revision.

Add a production Convex deploy key to the Vercel Production environment:

```text
CONVEX_DEPLOY_KEY=<production deploy key>
```

The key only needs the `deployment:deploy` permission. Preview deployments
require a separate Convex preview deploy key under the same variable name in
Vercel's Preview environment.
