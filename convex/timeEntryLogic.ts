export interface EditableTimerSegment {
  startTime: number;
  endTime?: number;
}

const SECOND_MS = 1_000;

function wholeSecond(timestamp: number): number {
  return Math.floor(timestamp / SECOND_MS) * SECOND_MS;
}

/**
 * Move an active timer's initial start without flattening later pause/resume
 * segments. The new start must remain inside the timer's first segment.
 */
export function retimeActiveTimerSegments(
  segments: EditableTimerSegment[],
  requestedStart: number,
  now: number,
): EditableTimerSegment[] {
  const first = segments[0];
  if (!first) throw new Error("Timer has no tracked segments");

  const startTime = wholeSecond(requestedStart);
  const currentTime = wholeSecond(now);
  if (startTime > currentTime) {
    throw new Error("Start time cannot be in the future");
  }
  if (first.endTime !== undefined && startTime > first.endTime) {
    throw new Error("Start time must be before the timer's first pause");
  }

  return [{ ...first, startTime }, ...segments.slice(1)];
}
