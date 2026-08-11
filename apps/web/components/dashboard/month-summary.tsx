"use client";

import { useMemo } from "react";
import { useQuery } from "convex/react";

import { api } from "@convex/_generated/api";
import type { Doc } from "@convex/_generated/dataModel";
import { FOLDER_COLOR_TOKENS, LABEL_COLOR_TOKENS, formatDurationClock } from "@tempo/shared";
import {
  effectiveLabelIds,
  entryDurationSeconds,
  totalTrackedSeconds,
} from "@/lib/reporting";
import { cn } from "@/lib/utils";
import { useWholeSecondClock } from "@/lib/whole-second-clock";

interface BreakdownItem {
  id: string;
  name: string;
  color: string;
  seconds: number;
}

function tokenColor(
  color: string | undefined,
  tokens: readonly { id: string; value: string }[],
): string {
  if (!color) return tokens[0].value;
  return tokens.find((token) => token.id === color)?.value ?? color;
}

function addSeconds(
  totals: Map<string, number>,
  key: string,
  seconds: number,
) {
  totals.set(key, (totals.get(key) ?? 0) + seconds);
}

function Breakdown({ title, items }: { title: string; items: BreakdownItem[] }) {
  const max = Math.max(...items.map((item) => item.seconds), 1);

  return (
    <div>
      <p className="text-xs font-bold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
        {title}
      </p>
      <div className="mt-3 grid gap-3">
        {items.length === 0 ? (
          <p className="text-sm text-[var(--terra-sage)]">No tracked time yet.</p>
        ) : (
          items.slice(0, 5).map((item) => (
            <div key={item.id} className="grid gap-1.5">
              <div className="flex items-center justify-between gap-3 text-sm">
                <span className="flex min-w-0 items-center gap-2 font-semibold text-[var(--terra-pine)]">
                  <span
                    className="size-2.5 shrink-0 rounded-full"
                    style={{ backgroundColor: item.color }}
                  />
                  <span className="truncate">{item.name}</span>
                </span>
                <span className="shrink-0 font-bold tabular-nums text-[var(--terra-sage)]">
                  {formatDurationClock(item.seconds)}
                </span>
              </div>
              <div className="h-1.5 overflow-hidden rounded-full bg-[var(--input)]">
                <div
                  className="h-full rounded-full transition-[width] duration-300"
                  style={{
                    width: `${Math.max(3, (item.seconds / max) * 100)}%`,
                    backgroundColor: item.color,
                  }}
                />
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export function MonthSummary({ className }: { className?: string }) {
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1).getTime();
  const entries = useQuery(api.timeEntries.listByDateRange, {
    startDate: monthStart,
    endDate: nextMonth,
  });
  const folders = useQuery(api.folders.listAllFolders, {});
  const labels = useQuery(api.labels.listLabels, {});
  const clockNow = useWholeSecondClock(
    entries?.some((entry) => entry.status === "running") ?? false,
  );

  const summary = useMemo(() => {
    const currentEntries = entries ?? [];
    const currentFolders = folders ?? [];
    const currentLabels = labels ?? [];
    const foldersById = new Map<string, Doc<"folders">>(
      currentFolders.map((folder) => [folder._id, folder]),
    );
    const folderTotals = new Map<string, number>();
    const labelTotals = new Map<string, number>();

    for (const entry of currentEntries) {
      const seconds = entryDurationSeconds(entry, clockNow);
      addSeconds(folderTotals, entry.folderId ?? "inbox", seconds);
      for (const labelId of effectiveLabelIds(entry, foldersById)) {
        addSeconds(labelTotals, labelId, seconds);
      }
    }

    const folderItems: BreakdownItem[] = [
      {
        id: "inbox",
        name: "Inbox",
        color: "var(--terra-clay)",
        seconds: folderTotals.get("inbox") ?? 0,
      },
      ...currentFolders.map((folder) => ({
        id: folder._id as string,
        name: folder.name,
        color: tokenColor(folder.color, FOLDER_COLOR_TOKENS),
        seconds: folderTotals.get(folder._id) ?? 0,
      })),
    ].filter((item) => item.seconds > 0);

    const labelItems: BreakdownItem[] = currentLabels
      .map((label) => ({
        id: label._id as string,
        name: label.name,
        color: tokenColor(label.color, LABEL_COLOR_TOKENS),
        seconds: labelTotals.get(label._id) ?? 0,
      }))
      .filter((item) => item.seconds > 0);

    folderItems.sort((a, b) => b.seconds - a.seconds);
    labelItems.sort((a, b) => b.seconds - a.seconds);

    return {
      total: totalTrackedSeconds(currentEntries, clockNow),
      folderItems,
      labelItems,
    };
  }, [clockNow, entries, folders, labels]);

  return (
    <section className={cn("surface-panel p-5 md:p-6", className)}>
      <div>
        <p className="page-kicker">This month</p>
        <p className="mt-1 text-lg font-bold tracking-[-0.01em] text-[var(--terra-pine)]">
          {summary.total === 0
            ? "No time yet"
            : `${formatDurationClock(summary.total)} tracked`}
        </p>
      </div>

      <div className="mt-6 grid gap-7 md:grid-cols-2">
        <Breakdown title="By folder" items={summary.folderItems} />
        <Breakdown title="By label" items={summary.labelItems} />
      </div>
    </section>
  );
}
