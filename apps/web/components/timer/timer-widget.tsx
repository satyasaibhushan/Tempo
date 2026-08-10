"use client";

import { useCallback, useState } from "react";
import { useQuery } from "convex/react";
import {
  ChevronDown,
  ChevronUp,
  Loader2,
  Pause,
  Pencil,
  Play,
  Square,
  Trash2,
} from "lucide-react";

import { api } from "@convex/_generated/api";
import type { Id } from "@convex/_generated/dataModel";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { FolderPicker } from "./folder-picker";
import { LabelPicker } from "./label-picker";
import { TimerDisplay } from "./timer-display";
import { ActiveTimerDialog } from "./active-timer-dialog";
import { useTimerController, type ActiveTimer } from "./timer-controller";

function ErrorNotice({
  error,
  onDismiss,
}: {
  error: string | null;
  onDismiss: () => void;
}) {
  if (!error) return null;

  return (
    <button
      type="button"
      onClick={onDismiss}
      className="w-full rounded-2xl border border-[var(--terra-clay)]/30 bg-[var(--terra-clay)]/10 px-4 py-3 text-left text-[13px] leading-5 text-[#8a4630] transition-colors hover:bg-[var(--terra-clay)]/15"
    >
      <span className="mr-2 font-bold">Timer error.</span>
      {error}
      <span className="ml-2 text-[11px] font-semibold uppercase tracking-wide opacity-60">
        Dismiss
      </span>
    </button>
  );
}

/** One active timer, rendered as a deep-pine hero card. */
export function ActiveTimerCard({
  timer,
  className,
}: {
  timer: ActiveTimer;
  className?: string;
}) {
  const { discard, pause, pendingAction, resume, stop } = useTimerController();
  const [editing, setEditing] = useState(false);
  const [editorMaximumStart, setEditorMaximumStart] = useState(timer.startedAt);

  const allLabels = useQuery(api.labels.listLabels, {});
  const allFolders = useQuery(api.folders.listAllFolders, {});
  const inheritedLabelIds = useQuery(
    api.folders.getInheritedLabels,
    timer.folderId ? { folderId: timer.folderId } : "skip",
  );

  const isRunning = timer.status === "running";
  const isBusy =
    pendingAction !== null &&
    (pendingAction.entryId === timer.id || timer.id === undefined);

  const folder = timer.folderId
    ? allFolders?.find((f) => f._id === timer.folderId)
    : undefined;

  const labelIds = new Set<string>([
    ...timer.manualLabelIds,
    ...((inheritedLabelIds as Id<"labels">[] | undefined) ?? []),
  ]);
  const labels = (allLabels ?? []).filter((label) => labelIds.has(label._id));

  return (
    <>
      <section
        className={cn(
          "relative overflow-hidden rounded-3xl bg-[var(--terra-pine)] p-6 text-[var(--terra-hero-foreground)] md:p-8",
          !isRunning && "bg-[var(--terra-pine-soft)]",
          className,
        )}
      >
      <div
        className="pointer-events-none absolute -right-16 -top-20 size-[300px] rounded-full"
        style={{
          background: isRunning
            ? "radial-gradient(circle, rgba(196,112,79,0.35), transparent 70%)"
            : "radial-gradient(circle, rgba(125,145,132,0.3), transparent 70%)",
        }}
      />

      <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.1em] text-[var(--terra-hero-muted)]">
        <span
          className={cn(
            "size-[9px] rounded-full",
            isRunning
              ? "animate-pulse bg-[var(--terra-amber)]"
              : "bg-[var(--terra-sage)]",
          )}
        />
        {isRunning ? "Tracking now" : "On hold"}
      </div>

      <div className="relative mt-2 flex flex-wrap items-end justify-between gap-6">
        <div className="min-w-0">
          <TimerDisplay
            segments={timer.segments}
            status={timer.status}
            className="text-[clamp(2.6rem,7vw,4.5rem)]"
          />
          <p
            className={cn(
              "mt-1 text-[17px] font-medium text-[#dfe7d2]",
              !timer.title && "italic opacity-70",
            )}
          >
            {timer.title || "Untitled session"}
          </p>
          {timer.notes && (
            <p className="mt-1 max-w-xl text-[13px] leading-5 text-[var(--terra-hero-muted)]">
              {timer.notes}
            </p>
          )}
          <div className="mt-2.5 flex flex-wrap gap-[7px]">
            <span className="rounded-full bg-[var(--terra-amber)] px-[11px] py-1 text-[11.5px] font-semibold text-[#3c2a12]">
              {folder ? folder.name : "Inbox"}
            </span>
            {labels.map((label) => (
              <span
                key={label._id}
                className="rounded-full bg-[#eef1e4]/12 px-[11px] py-1 text-[11.5px] font-semibold text-[#cfdcc2]"
              >
                {label.name}
              </span>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-2.5">
          {isRunning ? (
            <Button
              onClick={() => timer.id && void pause(timer.id)}
              disabled={isBusy || !timer.id}
              className="h-11 rounded-full bg-[#eef1e4]/15 px-5 font-semibold text-[var(--terra-hero-foreground)] transition-transform hover:-translate-y-px hover:bg-[#eef1e4]/25"
            >
              <Pause className="size-4 fill-current" />
              Pause
            </Button>
          ) : (
            <Button
              onClick={() => timer.id && void resume(timer.id)}
              disabled={isBusy || !timer.id}
              className="h-11 rounded-full bg-[#eef1e4]/15 px-5 font-semibold text-[var(--terra-hero-foreground)] transition-transform hover:-translate-y-px hover:bg-[#eef1e4]/25"
            >
              <Play className="size-4 fill-current" />
              Resume
            </Button>
          )}
          <Button
            onClick={() => timer.id && void stop(timer.id)}
            disabled={isBusy || !timer.id}
            className="h-11 rounded-full bg-[#eef1e4] px-6 font-semibold text-[var(--terra-pine)] transition-transform hover:-translate-y-px hover:bg-white"
          >
            <Square className="size-3.5 fill-current" />
            Stop
          </Button>
          <Button
            variant="ghost"
            size="icon-lg"
            onClick={() => {
              setEditorMaximumStart(timer.segments[0]?.endTime ?? Date.now());
              setEditing(true);
            }}
            disabled={isBusy || !timer.id}
            className="rounded-full text-[var(--terra-hero-muted)] hover:bg-[#eef1e4]/10 hover:text-[var(--terra-hero-foreground)]"
            title="Edit active timer"
          >
            <Pencil className="size-4" />
          </Button>
          <Button
            variant="ghost"
            size="icon-lg"
            onClick={() => timer.id && void discard(timer.id)}
            disabled={isBusy || !timer.id}
            className="rounded-full text-[var(--terra-hero-muted)] hover:bg-[#eef1e4]/10 hover:text-[#e8b4a0]"
            title="Discard timer"
          >
            <Trash2 className="size-4" />
          </Button>
        </div>
      </div>
      </section>
      {editing && (
        <ActiveTimerDialog
          open
          onOpenChange={setEditing}
          timer={timer}
          maximumStart={editorMaximumStart}
        />
      )}
    </>
  );
}

/** Form card for starting another timer. Always available — timers can overlap. */
export function StartTimerCard({ className }: { className?: string }) {
  const { pendingAction, start } = useTimerController();

  const [title, setTitle] = useState("");
  const [notes, setNotes] = useState("");
  const [folderId, setFolderId] = useState<Id<"folders"> | undefined>();
  const [labelIds, setLabelIds] = useState<Id<"labels">[]>([]);
  const [showNotes, setShowNotes] = useState(false);

  const inheritedLabelIds = useQuery(
    api.folders.getInheritedLabels,
    folderId ? { folderId } : "skip",
  );

  const isStarting =
    pendingAction?.action === "start" || pendingAction?.action === "continue";

  const handleStart = useCallback(async () => {
    const started = await start({
      title: title || undefined,
      notes: notes || undefined,
      folderId,
      manualLabelIds: labelIds.length > 0 ? labelIds : undefined,
    });

    if (started) {
      setTitle("");
      setNotes("");
      setFolderId(undefined);
      setLabelIds([]);
      setShowNotes(false);
    }
  }, [folderId, labelIds, notes, start, title]);

  return (
    <section className={cn("surface-panel p-5 md:p-6", className)}>
      <div className="flex flex-wrap items-center gap-3">
        <Input
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="What are you working on?"
          className="h-11 min-w-52 flex-1 rounded-2xl border-transparent bg-[var(--muted)] px-4 text-[15px] font-medium shadow-none placeholder:text-[var(--terra-sage)] focus-visible:border-[var(--terra-moss)] focus-visible:ring-0"
          onKeyDown={(event) => {
            if (event.key === "Enter" && !event.shiftKey) {
              event.preventDefault();
              void handleStart();
            }
          }}
        />
        <Button
          onClick={() => void handleStart()}
          disabled={isStarting}
          className="signal-button h-11 gap-2 px-6"
        >
          {isStarting ? (
            <Loader2 className="size-4 animate-spin" />
          ) : (
            <Play className="size-4 fill-current" />
          )}
          Start
        </Button>
      </div>

      <div className="mt-3 flex flex-wrap items-center gap-2">
        <FolderPicker value={folderId} onChange={setFolderId} />
        <LabelPicker
          value={labelIds}
          onChange={setLabelIds}
          inheritedLabelIds={
            (inheritedLabelIds as Id<"labels">[] | undefined) ?? undefined
          }
        />
        <button
          type="button"
          onClick={() => setShowNotes((current) => !current)}
          className="ml-auto inline-flex items-center gap-1.5 text-xs font-semibold text-[var(--terra-sage)] transition-colors hover:text-[var(--terra-pine)]"
        >
          Notes
          {showNotes ? (
            <ChevronUp className="size-3" />
          ) : (
            <ChevronDown className="size-3" />
          )}
        </button>
      </div>

      {showNotes && (
        <Textarea
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
          placeholder="Optional context for later"
          className="mt-3 min-h-20 rounded-2xl border-transparent bg-[var(--muted)] text-sm placeholder:text-[var(--terra-sage)] focus-visible:border-[var(--terra-moss)] focus-visible:ring-0"
        />
      )}
    </section>
  );
}

/** The dashboard timer area: every active timer as a hero card + start form. */
export function TimerWidget({ className }: { className?: string }) {
  const { activeTimers, clearError, error } = useTimerController();

  if (activeTimers === undefined) {
    return (
      <div className={cn("surface-panel grid min-h-40 place-items-center", className)}>
        <div className="flex items-center gap-2.5 text-sm font-medium text-[var(--terra-sage)]">
          <Loader2 className="size-4 animate-spin" />
          Loading timers…
        </div>
      </div>
    );
  }

  return (
    <div className={cn("grid gap-4", className)}>
      {activeTimers.map((timer, index) => (
        <ActiveTimerCard key={timer.id ?? `pending-${index}`} timer={timer} />
      ))}
      <ErrorNotice error={error} onDismiss={clearError} />
      <StartTimerCard />
    </div>
  );
}
