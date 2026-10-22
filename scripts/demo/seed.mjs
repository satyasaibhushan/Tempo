// Seeds the local Convex deployment for the demo through the app's own mutations, acting as the fixed
// demo identity with the local deployment's admin key (read from .convex/local/default/config.json).
// Everything here is fictional. Reruns are no-ops once the demo user has folders.
//   node scripts/demo/seed.mjs
import { readFileSync } from "node:fs";

// Entry times are laid out in the demo account's time zone so the week reads naturally in the browser.
process.env.TZ = "Asia/Kolkata";
import { ConvexHttpClient } from "convex/browser";
import { api } from "../../convex/_generated/api.js";

const config = JSON.parse(readFileSync(new URL("../../.convex/local/default/config.json", import.meta.url), "utf8"));
const url = process.env.NEXT_PUBLIC_CONVEX_URL ?? `http://127.0.0.1:${config.ports.cloud}`;
const DEMO_IDENTITY = {
  tokenIdentifier: "https://demo-tempo.invalid/|auth0|demo-maya",
  issuer: "https://demo-tempo.invalid/",
  subject: "auth0|demo-maya",
  name: "Maya Iyer",
  email: "maya.iyer@example.com",
};

const client = new ConvexHttpClient(url);
client.setAdminAuth(config.adminKey, DEMO_IDENTITY);

await client.mutation(api.users.ensureCurrentUser, { timezone: "Asia/Kolkata" });
const existing = await client.query(api.folders.listAllFolders, {});
if (existing.length) {
  console.log("demo data already present; nothing seeded");
  process.exit(0);
}

const label = async (name, color) => client.mutation(api.labels.createLabel, { name, color });
const labels = {
  deep: await label("Deep work", "#2f6f5e"),
  meetings: await label("Meetings", "#b7613a"),
  writing: await label("Writing", "#7a5c99"),
  admin: await label("Admin", "#8a8f6a"),
};
const folder = (args) => client.mutation(api.folders.createFolder, args);
const portfolio = await folder({ name: "Portfolio", color: "#2f6f5e", defaultLabelIds: [labels.deep] });
const client1 = await folder({ name: "Client work", color: "#b7613a" });
const acme = await folder({ name: "Acme redesign", parentFolderId: client1, defaultLabelIds: [labels.deep] });
const learning = await folder({ name: "Learning", color: "#7a5c99" });

const HOUR = 3_600_000;
const at = (daysAgo, hour, minute = 0) => {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  d.setHours(hour, minute, 0, 0);
  return d.getTime();
};
const entries = [
  [6, 9, 0, 1.75, "Record product demos", portfolio, []],
  [6, 14, 0, 1.0, "Weekly sync", acme, [labels.meetings]],
  [5, 8, 30, 2.5, "Checkout flow states", acme, []],
  [5, 16, 0, 0.75, "Invoices and expenses", null, [labels.admin]],
  [4, 9, 0, 1.5, "Write the about page", portfolio, [labels.writing]],
  [4, 11, 0, 2.0, "Settings page polish", acme, []],
  [3, 10, 0, 1.25, "Rust ownership chapter", learning, []],
  [3, 15, 0, 0.5, "Design review", acme, [labels.meetings]],
  [2, 9, 15, 2.25, "Portfolio mobile layout", portfolio, []],
  [2, 13, 0, 1.0, "Edit project blurbs", portfolio, [labels.writing]],
  [1, 9, 0, 1.5, "Checkout flow states", acme, []],
  [1, 14, 30, 0.75, "Piano theory notes", learning, []],
  [0, 8, 45, 1.25, "Record product demos", portfolio, []],
];
for (const [daysAgo, hour, minute, hours, title, folderId, manualLabelIds] of entries) {
  const startTime = at(daysAgo, hour, minute);
  if (startTime + hours * HOUR > Date.now()) continue;
  await client.mutation(api.timeEntries.createManualEntry, {
    title, startTime, endTime: startTime + hours * HOUR, manualLabelIds,
    ...(folderId ? { folderId } : {}),
  });
}
console.log("seeded demo labels, folders, and a week of entries");
