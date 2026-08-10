"use client";

import { useMemo, useState } from "react";
import { useQuery } from "convex/react";

import { api } from "@convex/_generated/api";
import type { Id } from "@convex/_generated/dataModel";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { FolderPicker } from "./folder-picker";
import { LabelPicker } from "./label-picker";
import { type ActiveTimer, useTimerController } from "./timer-controller";

function toDatetimeLocal(timestamp: number): string {
  const date = new Date(timestamp);
  const local = new Date(timestamp - date.getTimezoneOffset() * 60_000);
  return local.toISOString().slice(0, 16);
}

export function ActiveTimerDialog({
  open,
  onOpenChange,
  timer,
  maximumStart,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  timer: ActiveTimer;
  maximumStart: number;
}) {
  const { edit, pendingAction } = useTimerController();
  const [title, setTitle] = useState(timer.title);
  const [notes, setNotes] = useState(timer.notes ?? "");
  const [folderId, setFolderId] = useState<Id<"folders"> | undefined>(
    timer.folderId,
  );
  const [labelIds, setLabelIds] = useState<Id<"labels">[]>(
    timer.manualLabelIds,
  );
  const [startTime, setStartTime] = useState(toDatetimeLocal(timer.startedAt));
  const [error, setError] = useState<string | null>(null);

  const inheritedLabelIds = useQuery(
    api.folders.getInheritedLabels,
    folderId ? { folderId } : "skip",
  );
  const parsedStart = useMemo(() => new Date(startTime).getTime(), [startTime]);
  const isValid = Number.isFinite(parsedStart) && parsedStart <= maximumStart;
  const saving =
    pendingAction?.action === "edit" && pendingAction.entryId === timer.id;

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    if (!timer.id || !isValid) {
      setError(
        "Start time must be before the timer's first pause and cannot be in the future.",
      );
      return;
    }

    const saved = await edit({
      id: timer.id,
      title: title.trim(),
      notes: notes.trim() || undefined,
      folderId,
      manualLabelIds: labelIds,
      startTime: parsedStart,
    });
    if (saved) onOpenChange(false);
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Edit active timer</DialogTitle>
          <DialogDescription>
            Correct its details or start time without stopping the clock.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <label className="flex flex-col gap-1.5 text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
            Title
            <Input
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder="What are you working on?"
              className="rounded-2xl border-transparent bg-[var(--muted)] normal-case tracking-normal text-[var(--terra-pine)] focus-visible:border-[var(--terra-moss)] focus-visible:ring-0"
            />
          </label>

          <label className="flex flex-col gap-1.5 text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
            Notes
            <Textarea
              value={notes}
              onChange={(event) => setNotes(event.target.value)}
              rows={2}
              placeholder="Optional context"
              className="rounded-2xl border-transparent bg-[var(--muted)] normal-case tracking-normal text-[var(--terra-pine)] focus-visible:border-[var(--terra-moss)] focus-visible:ring-0"
            />
          </label>

          <div className="flex flex-wrap gap-3">
            <FolderPicker value={folderId} onChange={setFolderId} />
            <LabelPicker
              value={labelIds}
              onChange={setLabelIds}
              inheritedLabelIds={inheritedLabelIds}
            />
          </div>

          <label className="flex flex-col gap-1.5 text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
            Started
            <input
              type="datetime-local"
              value={startTime}
              max={toDatetimeLocal(maximumStart)}
              onChange={(event) => setStartTime(event.target.value)}
              className="h-9 rounded-2xl border border-transparent bg-[var(--muted)] px-3 text-sm font-normal normal-case tracking-normal text-[var(--terra-pine)] outline-none focus:border-[var(--terra-moss)]"
            />
          </label>

          {!isValid && (
            <p className="text-sm text-[var(--destructive)]">
              Start time must be before the timer&apos;s first pause and cannot be in the future.
            </p>
          )}
          {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={saving || !timer.id || !isValid}
              className="signal-button"
            >
              {saving ? "Saving..." : "Save changes"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
