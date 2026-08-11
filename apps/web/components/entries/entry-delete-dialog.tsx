"use client";

import { useState } from "react";
import { useMutation } from "convex/react";
import { api } from "@convex/_generated/api";
import { AlertTriangle } from "lucide-react";

import { formatDurationClock } from "@tempo/shared";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import type { TimeEntryDoc } from "./entry-card";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function computeDuration(entry: TimeEntryDoc): number {
  if (entry.durationSeconds != null) return entry.durationSeconds;
  let total = 0;
  for (const seg of entry.segments) {
    const end = seg.endTime ?? Date.now();
    total += Math.max(0, end - seg.startTime);
  }
  return Math.floor(total / 1000);
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

interface EntryDeleteDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  entry: TimeEntryDoc;
}

export function EntryDeleteDialog({
  open,
  onOpenChange,
  entry,
}: EntryDeleteDialogProps) {
  const deleteEntry = useMutation(api.timeEntries.deleteEntry);
  const [deleting, setDeleting] = useState(false);

  async function handleDelete() {
    setDeleting(true);
    try {
      await deleteEntry({ entryId: entry._id });
      onOpenChange(false);
    } finally {
      setDeleting(false);
    }
  }

  const duration = computeDuration(entry);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-[var(--destructive)]">
            <AlertTriangle className="size-4" />
            Delete time entry
          </DialogTitle>
          <DialogDescription>
            This entry will be permanently removed. This action cannot be undone.
          </DialogDescription>
        </DialogHeader>

        <div className="flex items-center justify-between gap-3 rounded-2xl border border-[var(--border)] bg-[var(--muted)] px-4 py-3">
          <span className="truncate text-sm font-medium text-[var(--terra-pine)]">
            {entry.title || "Untitled"}
          </span>
          <span className="shrink-0 text-sm tabular-nums text-[var(--terra-sage)]">
            {formatDurationClock(duration)}
          </span>
        </div>

        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
          >
            Cancel
          </Button>
          <Button
            type="button"
            variant="destructive"
            disabled={deleting}
            onClick={handleDelete}
            className="rounded-full bg-[var(--destructive)] text-white hover:bg-[var(--destructive)]/90"
          >
            {deleting ? "Deleting..." : "Delete entry"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
