"use client";

import { formatDurationClock } from "@tempo/shared";
import { cn } from "@/lib/utils";
import { elapsedWholeSeconds, type TimerSegment } from "@/lib/timer-state";
import { useWholeSecondClock } from "@/lib/whole-second-clock";

export function TimerDisplay({
  segments,
  status,
  className,
}: {
  segments: TimerSegment[];
  status: "running" | "paused" | "completed";
  className?: string;
}) {
  const clockSecond = useWholeSecondClock(status === "running");
  const elapsed = elapsedWholeSeconds(segments, clockSecond);

  return (
    <div
      className={cn(
        "select-none font-semibold leading-none tracking-[-0.03em] tabular-nums",
        className,
      )}
      aria-live="polite"
      aria-atomic
    >
      {formatDurationClock(elapsed, { includeSeconds: true })}
    </div>
  );
}
