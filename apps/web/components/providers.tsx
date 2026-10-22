"use client";

import { Auth0Provider, useUser } from "@auth0/nextjs-auth0";
import {
  ConvexProvider,
  ConvexProviderWithAuth,
  ConvexReactClient,
} from "convex/react";
import { useCallback, useMemo } from "react";

import { DEMO_IDENTITY, demoEnabled } from "@/lib/demo";

const convexUrl = process.env.NEXT_PUBLIC_CONVEX_URL;

if (!convexUrl) {
  throw new Error("Missing NEXT_PUBLIC_CONVEX_URL in apps/web/.env.local.");
}

const convex = new ConvexReactClient(convexUrl);
if (demoEnabled) {
  // setAdminAuth is the client's acting-as mechanism (used by the Convex dashboard); it is not in the
  // public type surface, so the demo path reaches it through a narrow structural type.
  const actingAs = convex as unknown as {
    setAdminAuth(token: string, identity: typeof DEMO_IDENTITY): void;
  };
  actingAs.setAdminAuth(process.env.NEXT_PUBLIC_TEMPO_DEMO_ADMIN_KEY ?? "", DEMO_IDENTITY);
}

type Auth0SessionUser = {
  email?: string;
  name?: string;
  nickname?: string;
  picture?: string;
  sub: string;
};

function useAuthFromNextJsAuth0() {
  const { error, isLoading, user } = useUser();

  const fetchAccessToken = useCallback(async () => {
    const response = await fetch("/api/auth/convex-token", {
      cache: "no-store",
    });

    if (response.status === 401) {
      window.location.assign("/auth/login");
      return null;
    }

    if (!response.ok) {
      return null;
    }

    const data = (await response.json()) as { token?: string };

    return typeof data.token === "string" ? data.token : null;
  }, []);

  return useMemo(
    () => ({
      isAuthenticated: Boolean(user) && !error,
      isLoading,
      fetchAccessToken,
    }),
    [error, fetchAccessToken, isLoading, user],
  );
}

export function AppProviders({
  children,
  user,
}: {
  children: React.ReactNode;
  user?: Auth0SessionUser;
}) {
  if (demoEnabled) {
    return <ConvexProvider client={convex}>{children}</ConvexProvider>;
  }

  return (
    <Auth0Provider user={user}>
      <ConvexProviderWithAuth client={convex} useAuth={useAuthFromNextJsAuth0}>
        {children}
      </ConvexProviderWithAuth>
    </Auth0Provider>
  );
}
