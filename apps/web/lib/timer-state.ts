export type TimerStatus = "running" | "paused";

export interface TimerSegment {
  startTime: number;
  endTime?: number;
}

export interface TimerSnapshot {
  id?: string;
  title: string;
  notes?: string;
  folderId?: string;
  manualLabelIds: string[];
  status: TimerStatus;
  segments: TimerSegment[];
  startedAt: number;
}

export interface TimerDraft {
  title?: string;
  notes?: string;
  folderId?: string;
  manualLabelIds?: string[];
}

export interface ActiveTimerEdit {
  title: string;
  notes?: string;
  folderId?: string;
  manualLabelIds: string[];
  startTime: number;
}

const SECOND_MS = 1_000;

/** Drop sub-second precision so every timer shares wall-clock boundaries. */
export function toWholeSecond(timestamp: number): number {
  return Math.floor(timestamp / SECOND_MS) * SECOND_MS;
}

export function elapsedWholeSeconds(
  segments: TimerSegment[],
  now: number,
): number {
  const clockSecond = toWholeSecond(now);
  let elapsedMilliseconds = 0;

  for (const segment of segments) {
    const start = toWholeSecond(segment.startTime);
    const end =
      segment.endTime === undefined
        ? clockSecond
        : toWholeSecond(segment.endTime);
    elapsedMilliseconds += Math.max(0, end - start);
  }

  return elapsedMilliseconds / SECOND_MS;
}

export function canContinueEntry(entryStatus: string): boolean {
  return entryStatus === "completed";
}

export function createOptimisticTimer(
  draft: TimerDraft,
  now: number,
): TimerSnapshot {
  const startTime = toWholeSecond(now);
  return {
    title: draft.title ?? "",
    notes: draft.notes,
    folderId: draft.folderId,
    manualLabelIds: draft.manualLabelIds ?? [],
    status: "running",
    segments: [{ startTime }],
    startedAt: startTime,
  };
}

export function applyActiveTimerEdit(
  timer: TimerSnapshot,
  edit: ActiveTimerEdit,
): TimerSnapshot {
  const startTime = toWholeSecond(edit.startTime);
  return {
    ...timer,
    title: edit.title,
    notes: edit.notes,
    folderId: edit.folderId,
    manualLabelIds: edit.manualLabelIds,
    startedAt: startTime,
    segments: timer.segments.map((segment, index) =>
      index === 0 ? { ...segment, startTime } : segment,
    ),
  };
}

export function pauseOptimisticTimer(
  timer: TimerSnapshot,
  now: number,
): TimerSnapshot {
  const endTime = toWholeSecond(now);
  return {
    ...timer,
    status: "paused",
    segments: timer.segments.map((segment, index) =>
      index === timer.segments.length - 1 && segment.endTime === undefined
        ? { ...segment, endTime }
        : segment,
    ),
  };
}

export function resumeOptimisticTimer(
  timer: TimerSnapshot,
  now: number,
): TimerSnapshot {
  const startTime = toWholeSecond(now);
  return {
    ...timer,
    status: "running",
    segments: [...timer.segments, { startTime }],
  };
}
