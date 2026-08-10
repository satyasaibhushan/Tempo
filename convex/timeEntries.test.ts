import assert from "node:assert/strict";
import test from "node:test";

import { retimeActiveTimerSegments } from "./timeEntryLogic.ts";

test("retiming an active timer preserves later pause and resume segments", () => {
  assert.deepEqual(
    retimeActiveTimerSegments(
      [
        { startTime: 2_000, endTime: 5_000 },
        { startTime: 8_000 },
      ],
      1_250,
      10_000,
    ),
    [
      { startTime: 1_000, endTime: 5_000 },
      { startTime: 8_000 },
    ],
  );
});

test("retiming an active timer rejects a start after its first segment", () => {
  assert.throws(
    () =>
      retimeActiveTimerSegments(
        [
          { startTime: 2_000, endTime: 5_000 },
          { startTime: 8_000 },
        ],
        6_000,
        10_000,
      ),
    /before the timer's first pause/,
  );
});
