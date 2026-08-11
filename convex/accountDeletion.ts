import { v } from "convex/values";

import { internal } from "./_generated/api";
import { action, internalMutation } from "./_generated/server";
import { findUserByAuthSubject } from "./helpers";

type Auth0TokenResponse = {
  access_token?: unknown;
};

function requiredEnvironmentValue(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Account deletion is not configured: missing ${name}.`);
  }
  return value;
}

function auth0Origin(domain: string): string {
  return domain.startsWith("https://") ? domain : `https://${domain}`;
}

export const deleteLocalAccountData = internalMutation({
  args: {
    authSubject: v.string(),
  },
  handler: async (ctx, args) => {
    const user = await findUserByAuthSubject(ctx, args.authSubject);
    if (!user) return false;

    const [entries, folders, labels] = await Promise.all([
      ctx.db
        .query("timeEntries")
        .withIndex("by_user", (q) => q.eq("userId", user._id))
        .collect(),
      ctx.db
        .query("folders")
        .withIndex("by_user", (q) => q.eq("userId", user._id))
        .collect(),
      ctx.db
        .query("labels")
        .withIndex("by_user", (q) => q.eq("userId", user._id))
        .collect(),
    ]);

    for (const entry of entries) await ctx.db.delete(entry._id);
    for (const folder of folders) await ctx.db.delete(folder._id);
    for (const label of labels) await ctx.db.delete(label._id);
    await ctx.db.delete(user._id);

    return true;
  },
});

/** Permanently remove the signed-in user's Auth0 identity and Tempo data. */
export const deleteCurrentAccount = action({
  args: {},
  handler: async (ctx): Promise<boolean> => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Unauthorized");

    const origin = auth0Origin(requiredEnvironmentValue("AUTH0_DOMAIN"));
    const clientId = requiredEnvironmentValue("AUTH0_MANAGEMENT_CLIENT_ID");
    const clientSecret = requiredEnvironmentValue(
      "AUTH0_MANAGEMENT_CLIENT_SECRET",
    );

    const tokenResponse = await fetch(`${origin}/oauth/token`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        grant_type: "client_credentials",
        client_id: clientId,
        client_secret: clientSecret,
        audience: `${origin}/api/v2/`,
      }),
    });

    if (!tokenResponse.ok) {
      throw new Error("Tempo could not authorize account deletion.");
    }

    const tokenBody = (await tokenResponse.json()) as Auth0TokenResponse;
    if (typeof tokenBody.access_token !== "string") {
      throw new Error("Auth0 returned an invalid account deletion token.");
    }

    const deleteResponse = await fetch(
      `${origin}/api/v2/users/${encodeURIComponent(identity.subject)}`,
      {
        method: "DELETE",
        headers: { authorization: `Bearer ${tokenBody.access_token}` },
      },
    );

    if (!deleteResponse.ok && deleteResponse.status !== 404) {
      throw new Error("Tempo could not delete your Auth0 identity.");
    }

    await ctx.runMutation(internal.accountDeletion.deleteLocalAccountData, {
      authSubject: identity.subject,
    });

    return true;
  },
});
