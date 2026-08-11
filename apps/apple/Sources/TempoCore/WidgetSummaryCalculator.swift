import Foundation

public enum WidgetSummaryCalculator {
    public static func oldestRelevantDate(
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        weekStart: WeekStart? = nil
    ) -> Date {
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start
            ?? calendar.startOfDay(for: now)
        return min(startOfMonth, startOfWeek(containing: now, calendar: calendar, weekStart: weekStart))
    }

    public static func summary(
        for records: [WidgetEntryRecord],
        activeTimers: [WidgetTimerSnapshot] = [],
        range: WidgetRange,
        folderId: DocumentID? = nil,
        labelId: DocumentID? = nil,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        weekStart: WeekStart? = nil
    ) -> WidgetSummary {
        let intervals = bucketIntervals(
            for: range,
            now: now,
            calendar: calendar,
            weekStart: weekStart
        )
        let activeRecords = activeTimers.map {
            WidgetEntryRecord(
                id: $0.id,
                startedAt: $0.startedAt ?? $0.timerStartDate,
                durationSeconds: $0.elapsedSeconds(at: now),
                folderId: $0.folderId,
                labelIds: $0.labelIds ?? []
            )
        }
        let filteredRecords = (records + activeRecords).filter { record in
            let matchesFolder: Bool
            if folderId == WidgetSnapshotStore.inboxFilterIdentifier {
                matchesFolder = record.folderId == nil
            } else {
                matchesFolder = folderId == nil || record.folderId == folderId
            }
            let matchesLabel = labelId == nil || record.labelIds.contains(labelId ?? "")
            return matchesFolder && matchesLabel
        }

        let buckets = intervals.map { interval in
            let seconds = filteredRecords.reduce(into: 0) { total, record in
                let recordEnd = record.startedAt.addingTimeInterval(TimeInterval(record.durationSeconds))
                let overlapStart = max(record.startedAt, interval.range.lowerBound)
                let overlapEnd = min(recordEnd, interval.range.upperBound)
                total += max(Int(overlapEnd.timeIntervalSince(overlapStart)), 0)
            }

            return WidgetSummaryBucket(
                id: interval.range.lowerBound,
                label: interval.label,
                durationSeconds: seconds
            )
        }

        return WidgetSummary(
            range: range,
            totalSeconds: buckets.reduce(0) { $0 + $1.durationSeconds },
            buckets: buckets
        )
    }

    private static func bucketIntervals(
        for range: WidgetRange,
        now: Date,
        calendar: Calendar,
        weekStart: WeekStart?
    ) -> [(range: Range<Date>, label: String)] {
        switch range {
        case .day:
            let start = calendar.startOfDay(for: now)
            return (0..<6).compactMap { index in
                guard
                    let lower = calendar.date(byAdding: .hour, value: index * 4, to: start),
                    let upper = calendar.date(byAdding: .hour, value: (index + 1) * 4, to: start)
                else {
                    return nil
                }

                return (lower..<upper, lower.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))))
            }
        case .week:
            let start = startOfWeek(containing: now, calendar: calendar, weekStart: weekStart)

            return (0..<7).compactMap { index in
                guard
                    let lower = calendar.date(byAdding: .day, value: index, to: start),
                    let upper = calendar.date(byAdding: .day, value: index + 1, to: start)
                else {
                    return nil
                }

                return (lower..<upper, lower.formatted(.dateTime.weekday(.narrow)))
            }
        case .month:
            guard let month = calendar.dateInterval(of: .month, for: now) else {
                return []
            }

            var intervals: [(range: Range<Date>, label: String)] = []
            var lower = month.start

            while lower < month.end {
                guard let proposedUpper = calendar.date(byAdding: .day, value: 7, to: lower) else {
                    break
                }

                let upper = min(proposedUpper, month.end)
                let startDay = calendar.component(.day, from: lower)
                let endDay = calendar.component(.day, from: upper.addingTimeInterval(-1))
                intervals.append((lower..<upper, "\(startDay)–\(endDay)"))
                lower = upper
            }

            return intervals
        }
    }

    private static func startOfWeek(
        containing date: Date,
        calendar: Calendar,
        weekStart: WeekStart?
    ) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let mondayOffset = (weekday + 5) % 7
        let offset = weekStart == .sunday ? weekday - 1 : mondayOffset
        return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
    }
}
