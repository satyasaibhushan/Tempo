// Records the product demo into docs/demo/ against a running local build in demo mode (README, "Local demo"),
// seeded by scripts/demo/seed.mjs: poster.png (Now page), demo.webm (recorded session), demo.mp4 and demo.gif.
//   node scripts/demo/capture.mjs [http://localhost:3003]
// Playwright is not a project dependency: set PLAYWRIGHT_MODULE to its entry file. ffmpeg is optional.
import { spawnSync } from "node:child_process";
import { mkdirSync, readdirSync, readFileSync, renameSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { ConvexHttpClient } from "convex/browser";
import { api } from "../../convex/_generated/api.js";

const base = process.argv[2] ?? "http://localhost:3003";
const OUT = fileURLToPath(new URL("../../docs/demo/", import.meta.url));
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || "playwright").then((m) => m.default ?? m);

const SIZE = { width: 1280, height: 800 };
const SESSION_TITLE = "Edit the demo recordings";

// The recording creates one session; remove earlier takes and any live timer so reruns start from the seed.
const config = JSON.parse(readFileSync(new URL("../../.convex/local/default/config.json", import.meta.url), "utf8"));
const convex = new ConvexHttpClient(process.env.NEXT_PUBLIC_CONVEX_URL ?? `http://127.0.0.1:${config.ports.cloud}`);
convex.setAdminAuth(config.adminKey, {
  tokenIdentifier: "https://demo-tempo.invalid/|auth0|demo-maya",
  issuer: "https://demo-tempo.invalid/",
  subject: "auth0|demo-maya",
});
for (const timer of await convex.query(api.timeEntries.listActiveTimers, {}))
  await convex.mutation(api.timeEntries.discardTimer, { entryId: timer._id });
for (const entry of await convex.query(api.timeEntries.listRecent, { limit: 50 }))
  if (entry.title === SESSION_TITLE) await convex.mutation(api.timeEntries.deleteEntry, { entryId: entry._id });
mkdirSync(OUT, { recursive: true });
rmSync(`${OUT}frames`, { recursive: true, force: true });
const browser = await chromium.launch();
const ctx = await browser.newContext({
  viewport: SIZE, timezoneId: "Asia/Kolkata", recordVideo: { dir: `${OUT}frames`, size: SIZE },
});
const page = await ctx.newPage();
const settle = (ms) => page.waitForTimeout(ms);
try {
  await page.goto(`${base}/dashboard`);
  await page.getByText("This week").waitFor();
  await settle(2000);
  // Start a session from the Now page, let the clock run, pause and resume it, then stop it.
  await page.getByPlaceholder("What are you working on?").pressSequentially(SESSION_TITLE, { delay: 45 });
  await settle(500);
  await page.getByRole("button", { name: "Start" }).click();
  await settle(3200);
  await page.screenshot({ path: `${OUT}poster.png` });
  await page.getByRole("button", { name: "Pause" }).click();
  await settle(1600);
  await page.getByRole("button", { name: "Resume" }).click();
  await settle(2200);
  await page.getByRole("button", { name: "Stop" }).click();
  await settle(1800);
  // The finished session joins the log with the rest of the week.
  await page.getByRole("link", { name: "Log", exact: true }).click();
  await settle(3000);
} finally {
  await ctx.close();
  await browser.close();
}

const [webm] = readdirSync(`${OUT}frames`).filter((f) => f.endsWith(".webm"));
renameSync(`${OUT}frames/${webm}`, `${OUT}demo.webm`);
rmSync(`${OUT}frames`, { recursive: true, force: true });
console.log("wrote docs/demo/poster.png docs/demo/demo.webm");

const ffmpeg = (args) => spawnSync("ffmpeg", ["-y", "-hide_banner", "-loglevel", "error", ...args], { stdio: "inherit" });
if (spawnSync("ffmpeg", ["-version"], { stdio: "ignore" }).error) {
  console.log("ffmpeg not found: skipped docs/demo/demo.mp4 and docs/demo/demo.gif");
} else {
  ffmpeg(["-i", `${OUT}demo.webm`, "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23", "-movflags", "+faststart", `${OUT}demo.mp4`]);
  ffmpeg(["-i", `${OUT}demo.webm`, "-vf", "fps=10,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=5", "-loop", "0", `${OUT}demo.gif`]);
  console.log("wrote docs/demo/demo.mp4 docs/demo/demo.gif");
}
