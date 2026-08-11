"use client";

import { useQuery } from "convex/react";
import { format } from "date-fns";

import { api } from "@convex/_generated/api";
import { formatDurationClock } from "@tempo/shared";
import { EntryCard } from "@/components/entries/entry-card";
import { WeekChart } from "@/components/dashboard/week-chart";
import { MonthSummary } from "@/components/dashboard/month-summary";
import { LoadingState } from "@/components/states";
import { TimerWidget } from "@/components/timer/timer-widget";
import { totalTrackedSeconds } from "@/lib/reporting";
import { useWholeSecondClock } from "@/lib/whole-second-clock";

function greetingForHour(hour: number): string {
  if (hour < 5) return "Up late";
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

export default function DashboardPage() {
  const now = new Date();
  const todayStart = new Date(now);
  todayStart.setHours(0, 0, 0, 0);
  const tomorrowStart = new Date(todayStart);
  tomorrowStart.setDate(tomorrowStart.getDate() + 1);

  const user = useQuery(api.users.current, {});
  const todayEntries = useQuery(api.timeEntries.listByDateRange, {
    startDate: todayStart.getTime(),
    endDate: tomorrowStart.getTime(),
  });
  const allFolders = useQuery(api.folders.listAllFolders, {});
  const allLabels = useQuery(api.labels.listLabels, {});
  const clockNow = useWholeSecondClock(
    todayEntries?.some((entry) => entry.status === "running") ?? false,
  );

  const todaySeconds = totalTrackedSeconds(todayEntries ?? [], clockNow);

  const firstName = user?.name?.split(" ")[0];

  return (
    <section className="grid gap-6">
      <div className="page-hero">
        <p className="page-kicker">{format(now, "EEEE, d MMMM")}</p>
        <h1 className="page-title">
          {greetingForHour(now.getHours())}
          {firstName ? `, ${firstName}` : ""}.
        </h1>
        <p className="page-subtitle">
          {todaySeconds > 0
            ? `${formatDurationClock(todaySeconds)} recorded so far today.`
            : "Nothing recorded yet today — the first session sets the tone."}
        </p>
      </div>

      <TimerWidget />

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_420px]">
        <section className="surface-panel p-5 md:p-6">
          <div className="flex items-baseline justify-between gap-3">
            <div>
              <p className="page-kicker">Today</p>
              <p className="mt-1 text-lg font-bold tracking-[-0.01em] text-[var(--terra-pine)]">
                {todayEntries?.length ?? 0}{" "}
                {todayEntries?.length === 1 ? "session" : "sessions"}
              </p>
            </div>
            <span className="text-sm font-bold tabular-nums text-[var(--terra-sage)]">
              {formatDurationClock(todaySeconds)}
            </span>
          </div>

          <div className="mt-3 flex flex-col">
            {todayEntries === undefined ? (
              <LoadingState message="Loading entries…" className="py-12" />
            ) : todayEntries.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-[var(--input)] px-5 py-12 text-center text-sm leading-6 text-[var(--terra-sage)]">
                Sessions you track today will land here.
              </div>
            ) : (
              [...todayEntries]
                .sort((a, b) => b.startedAt - a.startedAt)
                .map((entry) => (
                  <EntryCard
                    key={entry._id}
                    entry={entry}
                    folders={allFolders ?? []}
                    labels={allLabels ?? []}
                    compact
                  />
                ))
            )}
          </div>
        </section>

        <WeekChart weekStart={user?.weekStart ?? "monday"} />
      </div>

      <MonthSummary />
    </section>
  );
}
