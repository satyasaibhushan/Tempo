"use client";

import { useState, useEffect, useMemo, useCallback } from "react";
import { useMutation, useQuery } from "convex/react";
import { api } from "@convex/_generated/api";
import type { Id } from "@convex/_generated/dataModel";
import {
  InboxIcon,
  TagIcon,
  ChevronDown,
  Check,
} from "lucide-react";

import { cn } from "@/lib/utils";
import { FOLDER_COLOR_TOKENS, LABEL_COLOR_TOKENS } from "@tempo/shared";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import type { TimeEntryDoc } from "./entry-card";

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

function toDatetimeLocal(ms: number): string {
  const date = new Date(ms);
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60 * 1000);
  return local.toISOString().slice(0, 16);
}

function fromDatetimeLocal(value: string): number {
  return new Date(value).getTime();
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface FolderDoc {
  _id: Id<"folders">;
  name: string;
  color?: string;
}

interface LabelDoc {
  _id: Id<"labels">;
  name: string;
  color: string;
}

interface EntryDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  mode: "create" | "edit";
  entry?: TimeEntryDoc;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function EntryDialog({
  open,
  onOpenChange,
  mode,
  entry,
}: EntryDialogProps) {
  const createEntry = useMutation(api.timeEntries.createManualEntry);
  const editEntry = useMutation(api.timeEntries.editEntry);
  const allFolders = useQuery(api.folders.listAllFolders, {
    includeArchived: false,
  });
  const allLabels = useQuery(api.labels.listLabels, {});

  const [title, setTitle] = useState("");
  const [notes, setNotes] = useState("");
  const [folderId, setFolderId] = useState<Id<"folders"> | undefined>();
  const [selectedLabelIds, setSelectedLabelIds] = useState<Id<"labels">[]>([]);
  const [startTime, setStartTime] = useState("");
  const [endTime, setEndTime] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [labelsOpen, setLabelsOpen] = useState(false);

  // Reset form when dialog opens
  useEffect(() => {
    if (!open) return;

    if (mode === "edit" && entry) {
      setTitle(entry.title || "");
      setNotes(entry.notes || "");
      setFolderId(entry.folderId);
      setSelectedLabelIds(entry.manualLabelIds as Id<"labels">[]);
      setStartTime(toDatetimeLocal(entry.startedAt));
      setEndTime(entry.endedAt ? toDatetimeLocal(entry.endedAt) : "");
    } else {
      const now = Date.now();
      const oneHourAgo = now - 3600000;
      setTitle("");
      setNotes("");
      setFolderId(undefined);
      setSelectedLabelIds([]);
      setStartTime(toDatetimeLocal(oneHourAgo));
      setEndTime(toDatetimeLocal(now));
    }
    setError(null);
  }, [open, mode, entry]);

  const selectedLabelSet = useMemo(
    () => new Set(selectedLabelIds),
    [selectedLabelIds],
  );

  const toggleLabel = useCallback(
    (labelId: Id<"labels">) => {
      setSelectedLabelIds((prev) =>
        prev.includes(labelId)
          ? prev.filter((id) => id !== labelId)
          : [...prev, labelId],
      );
    },
    [],
  );

  const isValid = useMemo(() => {
    if (!startTime || !endTime) return false;
    const start = fromDatetimeLocal(startTime);
    const end = fromDatetimeLocal(endTime);
    return end > start;
  }, [startTime, endTime]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!isValid) {
      setError("End time must be after start time.");
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const start = fromDatetimeLocal(startTime);
      const end = fromDatetimeLocal(endTime);

      if (mode === "create") {
        await createEntry({
          title: title || "Untitled",
          notes: notes || undefined,
          folderId,
          manualLabelIds: selectedLabelIds,
          startTime: start,
          endTime: end,
        });
      } else if (entry) {
        await editEntry({
          entryId: entry._id,
          title,
          notes: notes || undefined,
          folderId,
          clearFolder: !folderId && !!entry.folderId,
          manualLabelIds: selectedLabelIds,
          startTime: fromDatetimeLocal(startTime),
          endTime: fromDatetimeLocal(endTime),
        });
      }

      onOpenChange(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setSaving(false);
    }
  }

  const selectedFolder = useMemo(
    () =>
      folderId
        ? (allFolders as FolderDoc[] | undefined)?.find(
            (f) => f._id === folderId,
          )
        : undefined,
    [allFolders, folderId],
  );

  const selectedLabels = useMemo(
    () =>
      (allLabels as LabelDoc[] | undefined)?.filter((l) =>
        selectedLabelSet.has(l._id),
      ) ?? [],
    [allLabels, selectedLabelSet],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {mode === "create" ? "New time entry" : "Edit time entry"}
          </DialogTitle>
          <DialogDescription>
            {mode === "create"
              ? "Add a manual time entry with start and end times."
              : "Update this time entry's details."}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          {/* Title */}
          <div className="flex flex-col gap-1.5">
            <label
              htmlFor="entry-title"
              className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]"
            >
              Title
            </label>
            <Input
              id="entry-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="What were you working on?"
              className="rounded-2xl border-transparent bg-[var(--muted)] placeholder:text-[var(--terra-sage)] focus-visible:border-[var(--terra-moss)] focus-visible:ring-0"
            />
          </div>

          {/* Notes */}
          <div className="flex flex-col gap-1.5">
            <label
              htmlFor="entry-notes"
              className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]"
            >
              Notes
            </label>
            <Textarea
              id="entry-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Optional notes..."
              rows={2}
              className="rounded-2xl border-transparent bg-[var(--muted)] placeholder:text-[var(--terra-sage)] focus-visible:border-[var(--terra-moss)] focus-visible:ring-0"
            />
          </div>

          {/* Folder + Labels row */}
          <div className="flex flex-wrap items-start gap-3">
            {/* Folder picker */}
            <div className="flex flex-col gap-1.5">
              <span className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                Folder
              </span>
              <Select
                value={folderId ?? "__inbox__"}
                onValueChange={(val) => {
                  if (val == null) return;
                  setFolderId(
                    val === "__inbox__"
                      ? undefined
                      : (val as Id<"folders">),
                  );
                }}
              >
                <SelectTrigger size="sm" className="gap-1.5">
                  <SelectValue>
                    {selectedFolder ? (
                      <span className="flex items-center gap-1.5">
                        <span
                          className="size-2 rounded-full"
                          style={{
                            backgroundColor: getFolderColor(
                              selectedFolder.color,
                            ),
                          }}
                        />
                        {selectedFolder.name}
                      </span>
                    ) : (
                      <span className="flex items-center gap-1.5">
                        <InboxIcon className="size-3.5 text-[var(--terra-sage)]" />
                        Inbox
                      </span>
                    )}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__inbox__">
                    <span className="flex items-center gap-1.5">
                      <InboxIcon className="size-3.5 text-[var(--terra-sage)]" />
                      Inbox
                    </span>
                  </SelectItem>
                  {(allFolders as FolderDoc[] | undefined)?.map((folder) => (
                    <SelectItem key={folder._id} value={folder._id}>
                      <span className="flex items-center gap-1.5">
                        <span
                          className="size-2 rounded-full"
                          style={{
                            backgroundColor: getFolderColor(folder.color),
                          }}
                        />
                        {folder.name}
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Label multi-select */}
            <div className="flex flex-col gap-1.5">
              <span className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                Labels
              </span>
              <Popover open={labelsOpen} onOpenChange={setLabelsOpen}>
                <PopoverTrigger
                  className={cn(
                    "inline-flex h-7 items-center gap-1.5 rounded-full border border-[var(--border)] bg-[var(--card)] px-2.5 text-[0.8rem] text-[var(--terra-pine)] transition-colors hover:border-[var(--terra-moss)]",
                  )}
                >
                  <TagIcon className="size-3.5 text-[var(--terra-sage)]" />
                  {selectedLabels.length > 0 ? (
                    <span className="flex items-center gap-1">
                      {selectedLabels.slice(0, 2).map((l) => (
                        <span
                          key={l._id}
                          className="inline-flex items-center gap-1 rounded-full bg-[var(--muted)] px-1.5 py-0.5 text-[11px] text-[var(--muted-foreground)]"
                        >
                          <span
                            className="size-1.5 rounded-full"
                            style={{
                              backgroundColor: getLabelColor(l.color),
                            }}
                          />
                          {l.name}
                        </span>
                      ))}
                      {selectedLabels.length > 2 && (
                        <span className="text-xs text-[var(--terra-sage)]">
                          +{selectedLabels.length - 2}
                        </span>
                      )}
                    </span>
                  ) : (
                    <span className="text-[var(--muted-foreground)]">Labels</span>
                  )}
                  <ChevronDown className="ml-1 size-3 text-[var(--terra-sage)]" />
                </PopoverTrigger>
                <PopoverContent className="w-56 rounded-xl p-1" align="start">
                  {(allLabels as LabelDoc[] | undefined)?.length === 0 && (
                    <p className="px-3 py-2 text-sm text-[var(--terra-sage)]">
                      No labels available.
                    </p>
                  )}
                  {(allLabels as LabelDoc[] | undefined)?.map((label) => {
                    const isSelected = selectedLabelSet.has(label._id);
                    return (
                      <button
                        key={label._id}
                        type="button"
                        onClick={() => toggleLabel(label._id)}
                        className="flex w-full items-center gap-2 rounded-lg px-2.5 py-1.5 text-left text-sm text-[var(--terra-pine)] transition-colors hover:bg-[var(--muted)]"
                      >
                        <div
                          className={cn(
                            "flex size-4 shrink-0 items-center justify-center rounded border border-[var(--input)]",
                            isSelected &&
                              "border-[var(--terra-moss)] bg-[var(--terra-moss)]/15",
                          )}
                        >
                          {isSelected && (
                            <Check className="size-3 text-[var(--terra-moss)]" />
                          )}
                        </div>
                        <span
                          className="size-2 shrink-0 rounded-full"
                          style={{
                            backgroundColor: getLabelColor(label.color),
                          }}
                        />
                        <span className="truncate">{label.name}</span>
                      </button>
                    );
                  })}
                </PopoverContent>
              </Popover>
            </div>
          </div>

          {/* Start / End time */}
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label
                htmlFor="entry-start"
                className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]"
              >
                Start
              </label>
              <input
                id="entry-start"
                type="datetime-local"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                className="h-8 w-full rounded-2xl border border-transparent bg-[var(--muted)] px-2.5 text-sm text-[var(--terra-pine)] outline-none transition-colors focus:border-[var(--terra-moss)]"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label
                htmlFor="entry-end"
                className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]"
              >
                End
              </label>
              <input
                id="entry-end"
                type="datetime-local"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                className="h-8 w-full rounded-2xl border border-transparent bg-[var(--muted)] px-2.5 text-sm text-[var(--terra-pine)] outline-none transition-colors focus:border-[var(--terra-moss)]"
              />
            </div>
          </div>

          {/* Validation / error message */}
          {error && (
            <p className="text-sm text-[var(--destructive)]">{error}</p>
          )}

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
              disabled={saving || !isValid}
              className="signal-button"
            >
              {saving
                ? mode === "create"
                  ? "Creating..."
                  : "Saving..."
                : mode === "create"
                  ? "Create entry"
                  : "Save changes"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
