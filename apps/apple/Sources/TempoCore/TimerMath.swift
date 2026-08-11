import Foundation

public enum TimerMath {
    public static let millisecondsPerSecond: Int64 = 1_000

    public static func wholeSecond(_ milliseconds: Int64) -> Int64 {
        milliseconds - milliseconds % millisecondsPerSecond
    }

    public static func nextWholeSecondBoundary(after date: Date) -> Date {
        Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down) + 1)
    }

    public static func elapsedSeconds(
        for segments: [TimeSegment],
        at nowMilliseconds: Int64
    ) -> Int {
        let totalMilliseconds = segments.reduce(into: Int64.zero) { total, segment in
            let effectiveEnd = segment.endTime ?? nowMilliseconds
            total += max(effectiveEnd - segment.startTime, 0)
        }

        return Int(totalMilliseconds / millisecondsPerSecond)
    }

    public static func elapsedSeconds(
        for entry: TimeEntry,
        at nowMilliseconds: Int64
    ) -> Int {
        if entry.status == .completed, let durationSeconds = entry.durationSeconds {
            return durationSeconds
        }

        return elapsedSeconds(for: entry.segments, at: wholeSecond(nowMilliseconds))
    }
}
