import assert from "node:assert/strict";
import test from "node:test";

import {
  applyActiveTimerEdit,
  canContinueEntry,
  createOptimisticTimer,
  elapsedWholeSeconds,
  pauseOptimisticTimer,
  resumeOptimisticTimer,
  toWholeSecond,
} from "./timer-state.ts";

test("active timer edits preserve lifecycle state and retime only the first segment", () => {
  const timer = {
    title: "Old title",
    notes: "Old notes",
    folderId: "old-folder",
    manualLabelIds: ["old-label"],
    status: "running" as const,
    segments: [
      { startTime: 2_000, endTime: 5_000 },
      { startTime: 8_000 },
    ],
    startedAt: 2_000,
  };

  const edited = applyActiveTimerEdit(timer, {
    title: "New title",
    notes: undefined,
    folderId: undefined,
    manualLabelIds: ["new-label"],
    startTime: 1_000,
  });

  assert.deepEqual(edited, {
    ...timer,
    title: "New title",
    notes: undefined,
    folderId: undefined,
    manualLabelIds: ["new-label"],
    segments: [
      { startTime: 1_000, endTime: 5_000 },
      { startTime: 8_000 },
    ],
    startedAt: 1_000,
  });
});

test("only completed entries can be continued", () => {
  assert.equal(canContinueEntry("completed"), true);
  assert.equal(canContinueEntry("running"), false);
  assert.equal(canContinueEntry("paused"), false);
});

test("timer lifecycle timestamps snap to the shared wall-clock second", () => {
  assert.equal(toWholeSecond(5_999), 5_000);

  const started = createOptimisticTimer({ title: "Focus" }, 2_750);
  assert.deepEqual(started.segments, [{ startTime: 2_000 }]);

  const paused = pauseOptimisticTimer(started, 5_250);
  assert.equal(paused.status, "paused");
  assert.deepEqual(paused.segments, [{ startTime: 2_000, endTime: 5_000 }]);

  const resumed = resumeOptimisticTimer(paused, 7_999);
  assert.equal(resumed.status, "running");
  assert.deepEqual(resumed.segments, [
    { startTime: 2_000, endTime: 5_000 },
    { startTime: 7_000 },
  ]);
});

test("every timer advances from the same shared second boundary", () => {
  const clockSecond = 10_000;
  const first = [{ startTime: 2_100 }];
  const second = [{ startTime: 4_950 }];

  assert.equal(elapsedWholeSeconds(first, clockSecond), 8);
  assert.equal(elapsedWholeSeconds(second, clockSecond), 6);
  assert.equal(elapsedWholeSeconds(first, clockSecond + 999), 8);
  assert.equal(elapsedWholeSeconds(second, clockSecond + 999), 6);
  assert.equal(elapsedWholeSeconds(first, clockSecond + 1_000), 9);
  assert.equal(elapsedWholeSeconds(second, clockSecond + 1_000), 7);
});
