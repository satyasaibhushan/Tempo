"use client";

import { useState } from "react";
import type { Id } from "@convex/_generated/dataModel";
import { Play, Pencil, Trash2 } from "lucide-react";
import { format } from "date-fns";

import { cn } from "@/lib/utils";
import { formatDurationClock } from "@tempo/shared";
import { FOLDER_COLOR_TOKENS, LABEL_COLOR_TOKENS } from "@tempo/shared";
import { Button } from "@/components/ui/button";
import { EntryDeleteDialog } from "./entry-delete-dialog";
import { useTimerController } from "@/components/timer/timer-controller";
import { canContinueEntry } from "@/lib/timer-state";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Segment {
  startTime: number;
  endTime?: number;
}

export interface TimeEntryDoc {
  _id: Id<"timeEntries">;
  title: string;
  notes?: string;
  folderId?: Id<"folders">;
  manualLabelIds: string[];
  status: string;
  segments: Segment[];
  startedAt: number;
  endedAt?: number;
  durationSeconds?: number;
  createdAt: number;
  updatedAt: number;
}

export interface FolderDoc {
  _id: Id<"folders">;
  name: string;
  color?: string;
}

export interface LabelDoc {
  _id: Id<"labels">;
  name: string;
  color: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function getFolderColor(color?: string): string {
  if (!color) return FOLDER_COLOR_TOKENS[0].value;
  const token = FOLDER_COLOR_TOKENS.find((t) => t.id === color);
  return token?.value ?? color;
}

function getLabelColor(color: string): string {
  const token = LABEL_COLOR_TOKENS.find((t) => t.id === color);
  return token?.value ?? color;
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

function formatTimeRange(entry: TimeEntryDoc): string {
  const start = format(new Date(entry.startedAt), "h:mm a");
  if (entry.endedAt) {
    const end = format(new Date(entry.endedAt), "h:mm a");
    return `${start} – ${end}`;
  }
  return `${start} – now`;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export interface EntryCardProps {
  entry: TimeEntryDoc;
  folders: FolderDoc[];
  labels: LabelDoc[];
  onEdit?: (entry: TimeEntryDoc) => void;
  compact?: boolean;
}

export function EntryCard({ entry, folders, labels, onEdit, compact }: EntryCardProps) {
  const { continueFrom } = useTimerController();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [continuing, setContinuing] = useState(false);

  const folder = entry.folderId
    ? folders.find((f) => f._id === entry.folderId)
    : undefined;

  const entryLabels = labels.filter((l) =>
    entry.manualLabelIds.includes(l._id),
  );

  const duration = computeDuration(entry);
  const isRunning = entry.status === "running";
  const canContinue = canContinueEntry(entry.status);

  async function handleContinue() {
    setContinuing(true);
    try {
      await continueFrom({
        id: entry._id,
        title: entry.title,
        notes: entry.notes,
        folderId: entry.folderId,
        manualLabelIds: entry.manualLabelIds as Id<"labels">[],
      });
    } finally {
      setContinuing(false);
    }
  }

  return (
    <>
      <div
        className={cn(
          "group relative flex items-center gap-3 border-b border-[var(--border)] py-3.5 pl-4 pr-1 last:border-b-0 transition-colors hover:bg-[var(--muted)]/50",
          compact && "py-3",
        )}
      >
        <span
          className="absolute inset-y-3 left-0 w-[3px] rounded-full"
          style={{
            backgroundColor: isRunning
              ? "var(--terra-amber)"
              : getFolderColor(folder?.color),
          }}
        />

        {/* Title + metadata */}
        <div className="flex min-w-0 flex-1 flex-col gap-1">
          <div className="flex items-center gap-2">
            <span
              className={cn(
                "truncate text-sm font-semibold tracking-[-0.01em] text-[var(--terra-pine)]",
                !entry.title && "font-medium italic text-[var(--terra-sage)]",
              )}
            >
              {entry.title || "Untitled"}
            </span>

            {isRunning && (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-[var(--terra-amber)]/25 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-[#7d5a24]">
                <span className="size-1.5 animate-pulse rounded-full bg-[var(--terra-amber)]" />
                Live
              </span>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-x-2.5 gap-y-1 text-xs text-[var(--terra-sage)]">
            <span className="tabular-nums">{formatTimeRange(entry)}</span>

            <span className="font-medium">{folder ? folder.name : "Inbox"}</span>

            {entryLabels.map((label) => (
              <span
                key={label._id}
                className="inline-flex items-center gap-1.5 rounded-full bg-[var(--muted)] px-2 py-0.5 text-[11px] font-medium text-[var(--muted-foreground)]"
              >
                <span
                  className="size-1.5 rounded-full"
                  style={{ backgroundColor: getLabelColor(label.color) }}
                />
                {label.name}
              </span>
            ))}
          </div>
        </div>

        {/* Duration */}
        <span
          className={cn(
            "shrink-0 text-sm font-bold tabular-nums text-[var(--terra-pine)]",
            isRunning && "text-[#9b6c1f]",
          )}
        >
          {formatDurationClock(duration)}
        </span>

        {/* Actions — visible on hover */}
        <div className="flex shrink-0 items-center gap-0.5 opacity-0 transition-opacity focus-within:opacity-100 group-hover:opacity-100">
          <Button
            variant="ghost"
            size="icon-xs"
            onClick={handleContinue}
            disabled={continuing || !canContinue}
            className="rounded-full text-[var(--terra-sage)] hover:bg-[var(--terra-moss)]/15 hover:text-[var(--terra-moss)] disabled:opacity-20"
            title={
              canContinue
                ? "Continue as a new timer"
                : "Only completed entries can be continued"
            }
          >
            <Play className="size-3" />
          </Button>
          <Button
            variant="ghost"
            size="icon-xs"
            onClick={() => onEdit?.(entry)}
            className="rounded-full text-[var(--terra-sage)] hover:bg-[var(--secondary)] hover:text-[var(--terra-pine)]"
            title="Edit entry"
          >
            <Pencil className="size-3" />
          </Button>
          <Button
            variant="ghost"
            size="icon-xs"
            onClick={() => setDeleteOpen(true)}
            className="rounded-full text-[var(--terra-sage)] hover:bg-[var(--terra-clay)]/15 hover:text-[var(--terra-clay)]"
            title="Delete entry"
          >
            <Trash2 className="size-3" />
          </Button>
        </div>
      </div>

      <EntryDeleteDialog
        open={deleteOpen}
        onOpenChange={setDeleteOpen}
        entry={entry}
      />
    </>
  );
}
