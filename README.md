# Tempo

The Web MVP and native iOS app share the same Convex backend and Auth0 identity
model. Native macOS development uses the same SwiftUI feature layer and timer
sync behavior.

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
