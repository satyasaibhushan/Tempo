import SwiftUI
import TimeCore
import WidgetKit

struct CurrentTimerEntry: TimelineEntry {
    let date: Date
    let timer: WidgetTimerSnapshot?
    let additionalRunningCount: Int
}

struct CurrentTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> CurrentTimerEntry {
        CurrentTimerEntry(
            date: .now,
            timer: WidgetPreviewData.runningTimer,
            additionalRunningCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CurrentTimerEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentTimerEntry>) -> Void) {
        let entry = entry()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func entry(now: Date = .now) -> CurrentTimerEntry {
        let runningTimers = (WidgetSnapshotStore.load()?.activeTimers ?? [])
            .filter { $0.status == .running }

        return CurrentTimerEntry(
            date: now,
            timer: runningTimers.first,
            additionalRunningCount: max(runningTimers.count - 1, 0)
        )
    }
}

struct CurrentTimerWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family
    let entry: CurrentTimerEntry

    var body: some View {
        Group {
            if let timer = entry.timer {
                switch family {
                case .accessoryRectangular:
                    compactTimer(timer)
                default:
                    homeScreenTimer(timer)
                }
            } else {
                emptyState
            }
        }
        .containerBackground(for: .widget) {
            WidgetPalette.timerSurface(for: colorScheme)
        }
        .widgetURL(TempoWidgetURL.now)
    }

    private func homeScreenTimer(_ timer: WidgetTimerSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(WidgetPalette.gold)
                    .frame(width: 7, height: 7)
                Text("TRACKING NOW")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
            }
            .foregroundStyle(WidgetPalette.softGreen)

            liveTimer(timer)
                .font(.system(.title2, design: .rounded, weight: .semibold))

            Spacer(minLength: 0)

            Text(timer.title.isEmpty ? "Untitled session" : timer.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            if entry.additionalRunningCount > 0 {
                Text("+\(entry.additionalRunningCount) more running")
                    .font(.caption2)
                    .foregroundStyle(WidgetPalette.softGreen)
            }
        }
        .foregroundStyle(.white)
    }

    private func compactTimer(_ timer: WidgetTimerSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(timer.title.isEmpty ? "Untitled session" : timer.title)
                .font(.headline)
                .lineLimit(1)
            liveTimer(timer)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .monospacedDigit()
        }
    }

    private func liveTimer(_ timer: WidgetTimerSnapshot) -> some View {
        ExactLiveTimerText(timer: timer)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "timer")
                .font(.title2)
            Text("No timer running")
                .font(.headline)
            Text("Start one in Time.")
                .font(.caption)
                .foregroundStyle(WidgetPalette.softGreen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(.white)
    }
}

struct CurrentTimerWidget: Widget {
    let kind = "CurrentTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentTimerProvider()) { entry in
            CurrentTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("Current timer")
        .description("See the timer that is running right now.")
        #if os(macOS)
        .supportedFamilies([.systemSmall])
        #else
        .supportedFamilies([.systemSmall, .accessoryRectangular])
        #endif
    }
}
