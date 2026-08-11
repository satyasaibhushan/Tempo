import AppIntents
import Charts
import SwiftUI
import TempoCore
import WidgetKit

struct SummaryWidgetEntry: TimelineEntry {
    let date: Date
    let summary: WidgetSummary
    let filterDescription: String
    let runningTimerCount: Int
}

struct SummaryWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SummaryWidgetEntry {
        makeEntry(
            configuration: SummaryWidgetIntent(range: .week),
            snapshot: WidgetPreviewData.snapshot,
            now: .now
        )
    }

    func snapshot(
        for configuration: SummaryWidgetIntent,
        in context: Context
    ) async -> SummaryWidgetEntry {
        makeEntry(configuration: configuration, snapshot: loadedSnapshot, now: .now)
    }

    func timeline(
        for configuration: SummaryWidgetIntent,
        in context: Context
    ) async -> Timeline<SummaryWidgetEntry> {
        let now = Date.now
        let entry = makeEntry(configuration: configuration, snapshot: loadedSnapshot, now: now)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private var loadedSnapshot: WidgetSnapshot {
        WidgetSnapshotStore.load() ?? .empty
    }

    private func makeEntry(
        configuration: SummaryWidgetIntent,
        snapshot: WidgetSnapshot,
        now: Date
    ) -> SummaryWidgetEntry {
        let folderId = configuration.folder?.filterId
        let labelId = configuration.label?.filterId
        let summary = WidgetSummaryCalculator.summary(
            for: snapshot.entries,
            activeTimers: snapshot.activeTimers,
            range: configuration.range.widgetRange,
            folderId: folderId,
            labelId: labelId,
            now: now,
            weekStart: snapshot.weekStart
        )
        let filters = [configuration.folder?.selectedName, configuration.label?.selectedName].compactMap { $0 }
        let runningTimerCount = snapshot.activeTimers.filter {
            $0.status == .running && timerMatchesFilters($0, folderId: folderId, labelId: labelId)
        }.count

        return SummaryWidgetEntry(
            date: now,
            summary: summary,
            filterDescription: filters.isEmpty ? "All time" : filters.joined(separator: " · "),
            runningTimerCount: runningTimerCount
        )
    }
}

struct SummaryWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: SummaryWidgetEntry

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.summary.range.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(WidgetPalette.mutedInk(for: colorScheme))

                LiveDurationText(
                    seconds: entry.summary.totalSeconds,
                    capturedAt: entry.date,
                    runningTimerCount: entry.runningTimerCount
                )
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(WidgetPalette.ink(for: colorScheme))
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)

                Text(entry.filterDescription)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.mutedInk(for: colorScheme))
                    .lineLimit(1)
            }
            .frame(width: 94, alignment: .leading)

            Chart(entry.summary.buckets) { bucket in
                BarMark(
                    x: .value("Bucket", bucket.label),
                    y: .value("Seconds", bucket.durationSeconds)
                )
                .foregroundStyle(WidgetPalette.accent(for: colorScheme).gradient)
                .cornerRadius(4)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(WidgetPalette.mutedInk(for: colorScheme))
                        }
                    }
                    AxisGridLine().foregroundStyle(WidgetPalette.line(for: colorScheme).opacity(0.7))
                }
            }
        }
        .containerBackground(for: .widget) {
            WidgetPalette.surface(for: colorScheme)
        }
        .widgetURL(TempoWidgetURL.now)
    }
}

struct SummaryWidget: Widget {
    let kind = "SummaryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SummaryWidgetIntent.self,
            provider: SummaryWidgetProvider()
        ) { entry in
            SummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Tracked time")
        .description("Compare your tracked time by day, week, or month with optional filters.")
        .supportedFamilies([.systemMedium])
    }
}

struct LiveWeekWidgetEntry: TimelineEntry {
    let date: Date
    let timer: WidgetTimerSnapshot?
    let summary: WidgetSummary
    let filterDescription: String
    let runningTimerCount: Int
}

struct LiveWeekWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LiveWeekWidgetEntry {
        makeEntry(
            configuration: LiveWeekWidgetIntent(),
            snapshot: WidgetPreviewData.snapshot,
            now: .now
        )
    }

    func snapshot(
        for configuration: LiveWeekWidgetIntent,
        in context: Context
    ) async -> LiveWeekWidgetEntry {
        makeEntry(configuration: configuration, snapshot: loadedSnapshot, now: .now)
    }

    func timeline(
        for configuration: LiveWeekWidgetIntent,
        in context: Context
    ) async -> Timeline<LiveWeekWidgetEntry> {
        let now = Date.now
        let entry = makeEntry(configuration: configuration, snapshot: loadedSnapshot, now: now)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private var loadedSnapshot: WidgetSnapshot {
        WidgetSnapshotStore.load() ?? .empty
    }

    private func makeEntry(
        configuration: LiveWeekWidgetIntent,
        snapshot: WidgetSnapshot,
        now: Date
    ) -> LiveWeekWidgetEntry {
        let folderId = configuration.folder?.filterId
        let labelId = configuration.label?.filterId
        let runningTimers = snapshot.activeTimers.filter {
            $0.status == .running && timerMatchesFilters($0, folderId: folderId, labelId: labelId)
        }
        let timer = runningTimers.first
        let summary = WidgetSummaryCalculator.summary(
            for: snapshot.entries,
            activeTimers: snapshot.activeTimers,
            range: .week,
            folderId: folderId,
            labelId: labelId,
            now: now,
            weekStart: snapshot.weekStart
        )
        let filters = [
            configuration.folder?.selectedName,
            configuration.label?.selectedName,
        ].compactMap { $0 }

        return LiveWeekWidgetEntry(
            date: now,
            timer: timer,
            summary: summary,
            filterDescription: filters.isEmpty ? "All time" : filters.joined(separator: " · "),
            runningTimerCount: runningTimers.count
        )
    }
}

struct LiveWeekWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: LiveWeekWidgetEntry

    var body: some View {
        HStack(spacing: 14) {
            livePane
                .frame(width: 132)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("THIS WEEK")
                        .font(.caption2.weight(.bold))
                        .tracking(0.9)
                        .foregroundStyle(WidgetPalette.mutedInk(for: colorScheme))
                    Spacer()
                    LiveDurationText(
                        seconds: entry.summary.totalSeconds,
                        capturedAt: entry.date,
                        runningTimerCount: entry.runningTimerCount
                    )
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(WidgetPalette.ink(for: colorScheme))
                }

                Chart(entry.summary.buckets) { bucket in
                    BarMark(
                        x: .value("Day", bucket.label),
                        y: .value("Seconds", bucket.durationSeconds)
                    )
                    .foregroundStyle(WidgetPalette.accent(for: colorScheme).gradient)
                    .cornerRadius(4)
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(WidgetPalette.mutedInk(for: colorScheme))
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(WidgetPalette.line(for: colorScheme).opacity(0.65))
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            WidgetPalette.surface(for: colorScheme)
        }
        .widgetURL(TempoWidgetURL.now)
    }

    private var livePane: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Circle()
                    .fill(entry.timer == nil ? WidgetPalette.softGreen : WidgetPalette.gold)
                    .frame(width: 6, height: 6)
                Text(entry.timer == nil ? "NOT RUNNING" : "TRACKING NOW")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
            }
            .foregroundStyle(WidgetPalette.softGreen)

            if let timer = entry.timer {
                ExactLiveTimerText(timer: timer)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)

                Text(timer.title.isEmpty ? "Untitled session" : timer.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            } else {
                Text("00:00:00")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("Start a matching timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Text(entry.filterDescription)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetPalette.softGreen)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WidgetPalette.timerSurface(for: colorScheme))
        )
    }
}

struct LiveWeekWidget: Widget {
    let kind = "LiveWeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: LiveWeekWidgetIntent.self,
            provider: LiveWeekWidgetProvider()
        ) { entry in
            LiveWeekWidgetView(entry: entry)
        }
        .configurationDisplayName("Live week")
        .description("See a matching live timer and its weekly breakdown together.")
        .supportedFamilies([.systemMedium])
    }
}
