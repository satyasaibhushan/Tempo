import assert from "node:assert/strict";
import test from "node:test";

import { demoBuildProblem, isDemoMode } from "./demo.ts";

const LOCAL_CONVEX = "http://127.0.0.1:3210";
const CLOUD_CONVEX = "https://happy-otter-123.convex.cloud";

test("demo mode needs the exact switch and a loopback Convex URL", () => {
  assert.equal(isDemoMode("1", LOCAL_CONVEX), true);
  assert.equal(isDemoMode("1", "http://localhost:3210/"), true);
  assert.equal(isDemoMode(undefined, LOCAL_CONVEX), false);
  assert.equal(isDemoMode("true", LOCAL_CONVEX), false);
  for (const url of [
    undefined,
    CLOUD_CONVEX,
    "http://localhost.example.com",
    "http://127.0.0.1.nip.io:3210",
    "http://localhost:3210@example.com",
    "http://127.0.0.1:3210/../evil",
  ]) {
    assert.equal(isDemoMode("1", url), false, url);
  }
});

test("builds without demo variables are untouched", () => {
  assert.equal(demoBuildProblem({ VERCEL: "1", NEXT_PUBLIC_CONVEX_URL: CLOUD_CONVEX }), null);
  assert.equal(demoBuildProblem({ NEXT_PUBLIC_TEMPO_DEMO: "", NEXT_PUBLIC_CONVEX_URL: CLOUD_CONVEX }), null);
});

test("local demo builds are allowed", () => {
  assert.equal(
    demoBuildProblem({
      NEXT_PUBLIC_TEMPO_DEMO: "1",
      NEXT_PUBLIC_TEMPO_DEMO_ADMIN_KEY: "local-key",
      NEXT_PUBLIC_CONVEX_URL: LOCAL_CONVEX,
    }),
    null,
  );
});

test("a deployable build refuses either demo variable", () => {
  assert.match(
    demoBuildProblem({ VERCEL: "1", NEXT_PUBLIC_TEMPO_DEMO: "1", NEXT_PUBLIC_CONVEX_URL: LOCAL_CONVEX }) ?? "",
    /must not be set on Vercel/,
  );
  assert.match(
    demoBuildProblem({ NEXT_PUBLIC_TEMPO_DEMO_ADMIN_KEY: "key", NEXT_PUBLIC_CONVEX_URL: CLOUD_CONVEX }) ?? "",
    /NEXT_PUBLIC_TEMPO_DEMO_ADMIN_KEY .*loopback/,
  );
  assert.match(demoBuildProblem({ NEXT_PUBLIC_TEMPO_DEMO: "1" }) ?? "", /loopback/);
});
