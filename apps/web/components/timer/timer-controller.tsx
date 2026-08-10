"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from "react";
import { useMutation, useQuery } from "convex/react";

import { api } from "@convex/_generated/api";
import type { Id } from "@convex/_generated/dataModel";
import {
  applyActiveTimerEdit,
  createOptimisticTimer,
  pauseOptimisticTimer,
  resumeOptimisticTimer,
  type TimerSnapshot,
} from "@/lib/timer-state";

export interface ActiveTimer extends TimerSnapshot {
  id?: Id<"timeEntries">;
  folderId?: Id<"folders">;
  manualLabelIds: Id<"labels">[];
}

export interface StartTimerInput {
  title?: string;
  notes?: string;
  folderId?: Id<"folders">;
  manualLabelIds?: Id<"labels">[];
}

export interface ContinueTimerInput {
  id: Id<"timeEntries">;
  title: string;
  notes?: string;
  folderId?: Id<"folders">;
  manualLabelIds: Id<"labels">[];
}

export interface EditActiveTimerInput {
  id: Id<"timeEntries">;
  title: string;
  notes?: string;
  folderId?: Id<"folders">;
  manualLabelIds: Id<"labels">[];
  startTime: number;
}

export interface PendingAction {
  action:
    | "start"
    | "continue"
    | "edit"
    | "pause"
    | "resume"
    | "stop"
    | "discard";
  entryId?: Id<"timeEntries">;
}

interface TimerControllerValue {
  /** Active timers (running or paused), oldest first. Undefined while loading. */
  activeTimers: ActiveTimer[] | undefined;
  error: string | null;
  pendingAction: PendingAction | null;
  clearError: () => void;
  start: (input: StartTimerInput) => Promise<boolean>;
  continueFrom: (input: ContinueTimerInput) => Promise<boolean>;
  edit: (input: EditActiveTimerInput) => Promise<boolean>;
  pause: (entryId: Id<"timeEntries">) => Promise<boolean>;
  resume: (entryId: Id<"timeEntries">) => Promise<boolean>;
  stop: (entryId: Id<"timeEntries">) => Promise<boolean>;
  discard: (entryId: Id<"timeEntries">) => Promise<boolean>;
}

const TimerControllerContext = createContext<TimerControllerValue | null>(null);

function messageFromError(error: unknown): string {
  if (error instanceof Error) {
    const match = error.message.match(/Uncaught Error: ([^\n]+)/);
    return match?.[1] ?? error.message;
  }
  return "The timer could not be updated. Please try again.";
}

export function TimerControllerProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const serverTimers = useQuery(api.timeEntries.listActiveTimers, {});
  const startMutation = useMutation(api.timeEntries.startTimer);
  const continueMutation = useMutation(api.timeEntries.continueEntry);
  const editMutation = useMutation(api.timeEntries.editActiveTimer);
  const pauseMutation = useMutation(api.timeEntries.pauseTimer);
  const resumeMutation = useMutation(api.timeEntries.resumeTimer);
  const stopMutation = useMutation(api.timeEntries.stopTimer);
  const discardMutation = useMutation(api.timeEntries.discardTimer);

  // Optimistic layer: per-entry overrides (null = removed) plus at most one
  // not-yet-persisted new timer. Cleared once the mutation settles — Convex
  // updates subscribed queries atomically with mutation completion.
  const [overrides, setOverrides] = useState<
    Record<string, ActiveTimer | null>
  >({});
  const [pendingNew, setPendingNew] = useState<ActiveTimer | null>(null);
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(
    null,
  );
  const [error, setError] = useState<string | null>(null);

  const activeTimers = useMemo<ActiveTimer[] | undefined>(() => {
    if (serverTimers === undefined) return undefined;

    const timers = serverTimers
      .map((timer): ActiveTimer | null => {
        if (timer._id in overrides) return overrides[timer._id];
        return {
          id: timer._id,
          title: timer.title,
          notes: timer.notes,
          folderId: timer.folderId,
          manualLabelIds: timer.manualLabelIds,
          status: timer.status as "running" | "paused",
          segments: timer.segments,
          startedAt: timer.startedAt,
        };
      })
      .filter((timer): timer is ActiveTimer => timer !== null);

    return pendingNew ? [...timers, pendingNew] : timers;
  }, [overrides, pendingNew, serverTimers]);

  const setOverride = useCallback(
    (entryId: Id<"timeEntries">, timer: ActiveTimer | null) => {
      setOverrides((current) => ({ ...current, [entryId]: timer }));
    },
    [],
  );

  const clearOverride = useCallback((entryId: Id<"timeEntries">) => {
    setOverrides((current) => {
      const rest = { ...current };
      delete rest[entryId];
      return rest;
    });
  }, []);

  const run = useCallback(
    async (
      pending: PendingAction,
      mutation: () => Promise<unknown>,
      settle: () => void,
    ) => {
      setPendingAction(pending);
      setError(null);
      try {
        await mutation();
        return true;
      } catch (caught) {
        setError(messageFromError(caught));
        return false;
      } finally {
        settle();
        setPendingAction(null);
      }
    },
    [],
  );

  const start = useCallback(
    async (input: StartTimerInput) => {
      setPendingNew(createOptimisticTimer(input, Date.now()) as ActiveTimer);
      return run(
        { action: "start" },
        () => startMutation(input),
        () => setPendingNew(null),
      );
    },
    [run, startMutation],
  );

  const continueFrom = useCallback(
    async (input: ContinueTimerInput) => {
      setPendingNew(
        createOptimisticTimer(
          {
            title: input.title,
            notes: input.notes,
            folderId: input.folderId,
            manualLabelIds: input.manualLabelIds,
          },
          Date.now(),
        ) as ActiveTimer,
      );
      return run(
        { action: "continue", entryId: input.id },
        () => continueMutation({ sourceEntryId: input.id }),
        () => setPendingNew(null),
      );
    },
    [continueMutation, run],
  );

  const pause = useCallback(
    async (entryId: Id<"timeEntries">) => {
      const timer = activeTimers?.find((t) => t.id === entryId);
      if (!timer || timer.status !== "running") return false;
      setOverride(
        entryId,
        pauseOptimisticTimer(timer, Date.now()) as ActiveTimer,
      );
      return run(
        { action: "pause", entryId },
        () => pauseMutation({ entryId }),
        () => clearOverride(entryId),
      );
    },
    [activeTimers, clearOverride, pauseMutation, run, setOverride],
  );

  const edit = useCallback(
    async (input: EditActiveTimerInput) => {
      const timer = activeTimers?.find((candidate) => candidate.id === input.id);
      if (!timer) return false;

      setOverride(input.id, applyActiveTimerEdit(timer, input) as ActiveTimer);
      return run(
        { action: "edit", entryId: input.id },
        () =>
          editMutation({
            entryId: input.id,
            title: input.title,
            notes: input.notes ?? "",
            folderId: input.folderId,
            clearFolder: input.folderId === undefined,
            manualLabelIds: input.manualLabelIds,
            startTime: input.startTime,
          }),
        () => clearOverride(input.id),
      );
    },
    [activeTimers, clearOverride, editMutation, run, setOverride],
  );

  const resume = useCallback(
    async (entryId: Id<"timeEntries">) => {
      const timer = activeTimers?.find((t) => t.id === entryId);
      if (!timer || timer.status !== "paused") return false;
      setOverride(
        entryId,
        resumeOptimisticTimer(timer, Date.now()) as ActiveTimer,
      );
      return run(
        { action: "resume", entryId },
        () => resumeMutation({ entryId }),
        () => clearOverride(entryId),
      );
    },
    [activeTimers, clearOverride, resumeMutation, run, setOverride],
  );

  const stop = useCallback(
    async (entryId: Id<"timeEntries">) => {
      setOverride(entryId, null);
      return run(
        { action: "stop", entryId },
        () => stopMutation({ entryId }),
        () => clearOverride(entryId),
      );
    },
    [clearOverride, run, setOverride, stopMutation],
  );

  const discard = useCallback(
    async (entryId: Id<"timeEntries">) => {
      setOverride(entryId, null);
      return run(
        { action: "discard", entryId },
        () => discardMutation({ entryId }),
        () => clearOverride(entryId),
      );
    },
    [clearOverride, discardMutation, run, setOverride],
  );

  const value = useMemo<TimerControllerValue>(
    () => ({
      activeTimers,
      error,
      pendingAction,
      clearError: () => setError(null),
      start,
      continueFrom,
      edit,
      pause,
      resume,
      stop,
      discard,
    }),
    [
      activeTimers,
      continueFrom,
      discard,
      edit,
      error,
      pause,
      pendingAction,
      resume,
      start,
      stop,
    ],
  );

  return (
    <TimerControllerContext.Provider value={value}>
      {children}
    </TimerControllerContext.Provider>
  );
}

export function useTimerController(): TimerControllerValue {
  const context = useContext(TimerControllerContext);
  if (!context) {
    throw new Error("useTimerController must be used inside TimerControllerProvider");
  }
  return context;
}
