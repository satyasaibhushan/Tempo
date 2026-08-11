"use client";

import { useState, useEffect } from "react";
import { useQuery, useMutation } from "convex/react";
import { api } from "@convex/_generated/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LoadingState } from "@/components/states";
import { Check, ExternalLink, Loader2, Pencil, Trash2, X } from "lucide-react";

import { AccountDeleteDialog } from "@/components/account-delete-dialog";

export default function SettingsPage() {
  const user = useQuery(api.users.current, {});
  const updateProfile = useMutation(api.users.updateProfile);
  const updatePreferences = useMutation(api.users.updatePreferences);

  // Edit mode toggles
  const [editingProfile, setEditingProfile] = useState(false);
  const [editingPrefs, setEditingPrefs] = useState(false);

  // Profile form state
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [profileSaving, setProfileSaving] = useState(false);

  // Preferences form state
  const [timezone, setTimezone] = useState("");
  const [weekStart, setWeekStart] = useState<"monday" | "sunday">("monday");
  const [timeFormat, setTimeFormat] = useState<"12h" | "24h">("24h");
  const [prefsSaving, setPrefsSaving] = useState(false);
  const [showDeleteAccount, setShowDeleteAccount] = useState(false);

  // Sync form state from server data
  useEffect(() => {
    if (user) {
      setName(user.name ?? "");
      setEmail(user.email ?? "");
      setTimezone(user.timezone);
      setWeekStart(user.weekStart);
      setTimeFormat(user.timeFormat);
    }
  }, [user]);

  function cancelProfileEdit() {
    if (user) {
      setName(user.name ?? "");
      setEmail(user.email ?? "");
    }
    setEditingProfile(false);
  }

  function cancelPrefsEdit() {
    if (user) {
      setTimezone(user.timezone);
      setWeekStart(user.weekStart);
      setTimeFormat(user.timeFormat);
    }
    setEditingPrefs(false);
  }

  async function saveProfile() {
    setProfileSaving(true);
    try {
      await updateProfile({ name, email });
      setEditingProfile(false);
    } finally {
      setProfileSaving(false);
    }
  }

  async function savePreferences() {
    setPrefsSaving(true);
    try {
      await updatePreferences({ timezone, weekStart, timeFormat });
      setEditingPrefs(false);
    } finally {
      setPrefsSaving(false);
    }
  }

  if (user === undefined) {
    return <LoadingState message="Loading settings..." />;
  }

  if (user === null) {
    return null;
  }

  return (
    <section className="grid gap-6">
      {/* Header */}
      <div className="page-hero">
        <p className="page-kicker">System / setup</p>
        <h1 className="page-title">Tune the instrument.</h1>
        <p className="page-subtitle">
          Personal settings that shape how the app displays time and organizes
          your day.
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Profile */}
        <div className="surface-panel p-5 md:p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-lg font-medium tracking-tight text-[var(--terra-pine)]">
                Profile
              </h2>
              <p className="mt-2 text-sm text-[var(--terra-sage)]">
                Your display name and email.
              </p>
            </div>
            {!editingProfile && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setEditingProfile(true)}
                className="gap-1.5 text-[var(--terra-sage)] hover:text-[var(--terra-pine)]"
              >
                <Pencil className="size-3.5" />
                Edit
              </Button>
            )}
          </div>

          <div className="mt-6 grid gap-4">
            {editingProfile ? (
              <>
                <div>
                  <label className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Name
                  </label>
                  <Input
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="mt-1.5"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Email
                  </label>
                  <Input
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="mt-1.5"
                  />
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    onClick={cancelProfileEdit}
                    disabled={profileSaving}
                    className="flex-1 gap-1.5 rounded-xl"
                  >
                    <X className="size-3.5" />
                    Cancel
                  </Button>
                  <Button
                    onClick={saveProfile}
                    disabled={profileSaving}
                    className="signal-button flex-1 gap-2 rounded-xl"
                  >
                    {profileSaving ? (
                      <Loader2 className="size-4 animate-spin" />
                    ) : (
                      <Check className="size-4" />
                    )}
                    Save
                  </Button>
                </div>
              </>
            ) : (
              <>
                <div className="rounded-2xl border border-[var(--border)] bg-[var(--muted)]/50 px-4 py-3">
                  <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Name
                  </div>
                  <div className="mt-1 text-sm text-[var(--terra-pine)]">
                    {user.name || "Not set"}
                  </div>
                </div>
                <div className="rounded-2xl border border-[var(--border)] bg-[var(--muted)]/50 px-4 py-3">
                  <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Email
                  </div>
                  <div className="mt-1 text-sm text-[var(--terra-pine)]">
                    {user.email || "Not set"}
                  </div>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Preferences */}
        <div className="surface-panel p-5 md:p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-lg font-medium tracking-tight text-[var(--terra-pine)]">
                Preferences
              </h2>
              <p className="mt-2 text-sm text-[var(--terra-sage)]">
                Timezone, time format, and week start.
              </p>
            </div>
            {!editingPrefs && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setEditingPrefs(true)}
                className="gap-1.5 text-[var(--terra-sage)] hover:text-[var(--terra-pine)]"
              >
                <Pencil className="size-3.5" />
                Edit
              </Button>
            )}
          </div>

          <div className="mt-6 grid gap-4">
            {editingPrefs ? (
              <>
                <div>
                  <label className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Timezone
                  </label>
                  <Input
                    value={timezone}
                    onChange={(e) => setTimezone(e.target.value)}
                    placeholder="e.g. America/New_York"
                    className="mt-1.5"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Time Format
                  </label>
                  <div className="mt-1.5 flex gap-2">
                    {(["24h", "12h"] as const).map((fmt) => (
                      <button
                        key={fmt}
                        type="button"
                        onClick={() => setTimeFormat(fmt)}
                        className={`flex-1 rounded-xl border px-4 py-2.5 text-sm font-medium transition ${
                          timeFormat === fmt
                            ? "border-[var(--terra-moss)]/30 bg-[var(--terra-moss)]/10 text-[var(--terra-moss)]"
                            : "border-[var(--border)] bg-[var(--card)] text-[var(--muted-foreground)] hover:border-[var(--terra-moss)]/40"
                        }`}
                      >
                        {fmt}
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <label className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Week Start
                  </label>
                  <div className="mt-1.5 flex gap-2">
                    {(["monday", "sunday"] as const).map((day) => (
                      <button
                        key={day}
                        type="button"
                        onClick={() => setWeekStart(day)}
                        className={`flex-1 rounded-xl border px-4 py-2.5 text-sm font-medium capitalize transition ${
                          weekStart === day
                            ? "border-[var(--terra-moss)]/30 bg-[var(--terra-moss)]/10 text-[var(--terra-moss)]"
                            : "border-[var(--border)] bg-[var(--card)] text-[var(--muted-foreground)] hover:border-[var(--terra-moss)]/40"
                        }`}
                      >
                        {day}
                      </button>
                    ))}
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    onClick={cancelPrefsEdit}
                    disabled={prefsSaving}
                    className="flex-1 gap-1.5 rounded-xl"
                  >
                    <X className="size-3.5" />
                    Cancel
                  </Button>
                  <Button
                    onClick={savePreferences}
                    disabled={prefsSaving}
                    className="signal-button flex-1 gap-2 rounded-xl"
                  >
                    {prefsSaving ? (
                      <Loader2 className="size-4 animate-spin" />
                    ) : (
                      <Check className="size-4" />
                    )}
                    Save
                  </Button>
                </div>
              </>
            ) : (
              <>
                <div className="rounded-2xl border border-[var(--border)] bg-[var(--muted)]/50 px-4 py-3">
                  <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Timezone
                  </div>
                  <div className="mt-1 text-sm text-[var(--terra-pine)]">
                    {user.timezone}
                  </div>
                </div>
                <div className="rounded-2xl border border-[var(--border)] bg-[var(--muted)]/50 px-4 py-3">
                  <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Time Format
                  </div>
                  <div className="mt-1 text-sm text-[var(--terra-pine)]">
                    {user.timeFormat}
                  </div>
                </div>
                <div className="rounded-2xl border border-[var(--border)] bg-[var(--muted)]/50 px-4 py-3">
                  <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                    Week Start
                  </div>
                  <div className="mt-1 text-sm capitalize text-[var(--terra-pine)]">
                    {user.weekStart}
                  </div>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Account */}
        <div className="surface-panel p-5 md:p-6 lg:col-span-2">
          <h2 className="text-lg font-medium tracking-tight text-[var(--terra-pine)]">
            Account
          </h2>
          <p className="mt-2 text-sm text-[var(--terra-sage)]">
            Auth provider and session management.
          </p>

          <div className="mt-6 flex items-center justify-between rounded-2xl border border-[var(--border)] bg-[var(--muted)]/50 px-4 py-4">
            <div>
              <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                Provider
              </div>
              <div className="mt-1 text-sm text-[var(--terra-pine)]">
                Auth0 (Apple + Google + Email)
              </div>
            </div>
            <a
              className="inline-flex items-center justify-center rounded-xl border border-[var(--border)] bg-[var(--card)] px-4 py-2 text-sm font-medium text-[var(--terra-pine)] transition hover:border-[var(--terra-moss)]/40 hover:bg-[var(--secondary)]"
              href="/auth/logout"
            >
              Log out
            </a>
          </div>

          <div className="mt-4 grid gap-3 md:grid-cols-2">
            <div className="flex items-center justify-between rounded-2xl border border-[var(--border)] bg-[var(--muted)]/50 px-4 py-4">
              <div>
                <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                  Legal &amp; support
                </div>
                <div className="mt-1 flex gap-4 text-sm">
                  <a className="inline-flex items-center gap-1 hover:underline" href="/privacy">
                    Privacy <ExternalLink className="size-3" />
                  </a>
                  <a className="inline-flex items-center gap-1 hover:underline" href="/support">
                    Support <ExternalLink className="size-3" />
                  </a>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between gap-4 rounded-2xl border border-[var(--destructive)]/25 bg-[var(--destructive)]/5 px-4 py-4">
              <div>
                <div className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--destructive)]">
                  Danger zone
                </div>
                <div className="mt-1 text-sm text-[var(--terra-sage)]">
                  Permanently remove this account and its data.
                </div>
              </div>
              <Button
                variant="outline"
                onClick={() => setShowDeleteAccount(true)}
                className="shrink-0 gap-2 border-[var(--destructive)]/30 text-[var(--destructive)] hover:bg-[var(--destructive)]/10"
              >
                <Trash2 className="size-4" />
                Delete account
              </Button>
            </div>
          </div>
        </div>
      </div>

      <AccountDeleteDialog
        open={showDeleteAccount}
        onOpenChange={setShowDeleteAccount}
      />
    </section>
  );
}
