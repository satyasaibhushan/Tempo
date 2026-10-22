"use client";

import type { ReactNode } from "react";
import { useEffect, useRef } from "react";
import { useConvexAuth, useMutation, useQuery } from "convex/react";

import { api } from "@convex/_generated/api";

export function CurrentUserBootstrap({ children }: { children: ReactNode }) {
  const { isAuthenticated, isLoading } = useConvexAuth();
  return (
    <ProvisionedUser isAuthenticated={isAuthenticated} isLoading={isLoading}>
      {children}
    </ProvisionedUser>
  );
}

// Demo mode has no Auth0 session: the Convex client is already acting as the demo identity.
export function DemoCurrentUserBootstrap({ children }: { children: ReactNode }) {
  return (
    <ProvisionedUser isAuthenticated isLoading={false}>
      {children}
    </ProvisionedUser>
  );
}

function ProvisionedUser({
  children,
  isAuthenticated,
  isLoading,
}: {
  children: ReactNode;
  isAuthenticated: boolean;
  isLoading: boolean;
}) {
  const currentUser = useQuery(api.users.current, isAuthenticated ? {} : "skip");
  const ensureCurrentUser = useMutation(api.users.ensureCurrentUser);
  const hasProvisionedRef = useRef(false);

  useEffect(() => {
    if (!isAuthenticated) {
      hasProvisionedRef.current = false;
    }
  }, [isAuthenticated]);

  useEffect(() => {
    if (isLoading || !isAuthenticated || currentUser !== null) {
      return;
    }

    if (currentUser === undefined || hasProvisionedRef.current) {
      return;
    }

    hasProvisionedRef.current = true;

    void ensureCurrentUser({
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC",
    }).catch(() => {
      hasProvisionedRef.current = false;
    });
  }, [currentUser, ensureCurrentUser, isAuthenticated, isLoading]);

  if (isLoading || !isAuthenticated || currentUser === undefined || currentUser === null) {
    return null;
  }

  return children;
}
