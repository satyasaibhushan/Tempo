"use client";

import { useMemo } from "react";
import { format, isToday, isYesterday, startOfDay } from "date-fns";

import { formatDurationClock } from "@tempo/shared";
import { LoadingState, EmptyState } from "@/components/states";
import { EntryCard } from "./entry-card";
import type { TimeEntryDoc, FolderDoc, LabelDoc } from "./entry-card";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

interface DayGroup {
  date: Date;
  label: string;
  totalSeconds: number;
  entries: TimeEntryDoc[];
}

function computeDuration(entry: TimeEntryDoc): number {
  if (entry.durationSeconds != null) return entry.durationSeconds;
  let total = 0;
  for (const seg of entry.segments) {
    const end = seg.endTime ?? Date.now();
    total += Math.max(0, end - seg.startTime);
  }
  return Math.floor(total / 1000);
}

function formatDayLabel(date: Date): string {
  if (isToday(date)) return "Today";
  if (isYesterday(date)) return "Yesterday";
  return format(date, "EEE, MMM d");
}

function groupByDay(entries: TimeEntryDoc[]): DayGroup[] {
  const map = new Map<string, DayGroup>();

  for (const entry of entries) {
    const day = startOfDay(new Date(entry.startedAt));
    const key = day.toISOString();

    if (!map.has(key)) {
      map.set(key, {
        date: day,
        label: formatDayLabel(day),
        totalSeconds: 0,
        entries: [],
      });
    }

    const group = map.get(key)!;
    group.entries.push(entry);
    group.totalSeconds += computeDuration(entry);
  }

  // Sort groups descending by date
  return Array.from(map.values()).sort(
    (a, b) => b.date.getTime() - a.date.getTime(),
  );
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

interface EntriesListProps {
  entries: TimeEntryDoc[] | undefined;
  folders: FolderDoc[];
  labels: LabelDoc[];
  isLoading: boolean;
  onEditEntry: (entry: TimeEntryDoc) => void;
}

export function EntriesList({
  entries,
  folders,
  labels,
  isLoading,
  onEditEntry,
}: EntriesListProps) {
  const groups = useMemo(
    () => (entries ? groupByDay(entries) : []),
    [entries],
  );

  if (isLoading) {
    return <LoadingState message="Loading entries..." />;
  }

  if (!entries || entries.length === 0) {
    return (
      <EmptyState
        title="No time entries"
        description="Start tracking time or create a manual entry to get started."
      />
    );
  }

  return (
    <div className="flex flex-col gap-8">
      {groups.map((group) => (
        <div key={group.date.toISOString()} className="flex flex-col gap-2">
          {/* Day header */}
          <div className="flex items-baseline justify-between px-1">
            <span className="text-xs font-bold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
              {group.label}
            </span>
            <span className="text-xs font-bold tabular-nums text-[var(--terra-sage)]">
              {formatDurationClock(group.totalSeconds)}
            </span>
          </div>

          {/* Entry cards */}
          <div className="surface-panel flex flex-col px-1">
            {group.entries.map((entry) => (
              <EntryCard
                key={entry._id}
                entry={entry}
                folders={folders}
                labels={labels}
                onEdit={onEditEntry}
              />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
