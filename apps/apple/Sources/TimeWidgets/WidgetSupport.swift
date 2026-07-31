import SwiftUI
import TimeCore

enum WidgetPalette {
    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(widgetHex: 0x242426) : Color(widgetHex: 0xF7F8F2)
    }

    static func timerSurface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(widgetHex: 0x1C1C1E) : Color(widgetHex: 0x22372B)
    }

    static func accent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(widgetHex: 0xD8A25A) : Color(widgetHex: 0x22372B)
    }

    static func ink(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(widgetHex: 0xF2F2F2) : Color(widgetHex: 0x22372B)
    }

    static func mutedInk(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(widgetHex: 0xB8B8B8) : Color(widgetHex: 0x57705F)
    }

    static func line(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(widgetHex: 0x48484A) : Color(widgetHex: 0xDEE2D3)
    }

    static let softGreen = Color(widgetHex: 0x7D9184)
    static let gold = Color(widgetHex: 0xD8A25A)
}

enum TempoWidgetURL {
    static let now = URL(string: "fun.bhushan.time://now")!
}

struct ExactLiveTimerText: View {
    let timer: WidgetTimerSnapshot

    var body: some View {
        Text(
            timerInterval: timer.timerStartDate...Date.distantFuture,
            countsDown: false,
            showsHours: true
        )
        .monospacedDigit()
    }
}

struct LiveDurationText: View {
    let seconds: Int
    let capturedAt: Date
    let runningTimerCount: Int

    var body: some View {
        if runningTimerCount == 1 {
            Text(
                timerInterval: liveStartDate...Date.distantFuture,
                countsDown: false,
                showsHours: true
            )
            .monospacedDigit()
        } else {
            Text(WidgetTimeText.duration(seconds))
                .monospacedDigit()
        }
    }

    private var liveStartDate: Date {
        Date(timeIntervalSince1970: capturedAt.timeIntervalSince1970.rounded(.down))
            .addingTimeInterval(-TimeInterval(seconds))
    }
}

func timerMatchesFilters(
    _ timer: WidgetTimerSnapshot,
    folderId: DocumentID?,
    labelId: DocumentID?
) -> Bool {
    let matchesFolder: Bool
    if folderId == WidgetSnapshotStore.inboxFilterIdentifier {
        matchesFolder = timer.folderId == nil
    } else {
        matchesFolder = folderId == nil || timer.folderId == folderId
    }
    let matchesLabel = labelId == nil || (timer.labelIds ?? []).contains(labelId ?? "")
    return matchesFolder && matchesLabel
}

private extension Color {
    init(widgetHex value: UInt32) {
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum WidgetPreviewData {
    static let runningTimer = WidgetTimerSnapshot(
        id: "preview-timer",
        title: "Focused work",
        folderName: "Inbox",
        status: .running,
        elapsedSeconds: 3_742,
        capturedAt: .now
    )

    static let snapshot: WidgetSnapshot = {
        let calendar = Calendar.current
        let now = Date.now
        let entries = (0..<7).compactMap { offset -> WidgetEntryRecord? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else {
                return nil
            }

            return WidgetEntryRecord(
                id: "preview-\(offset)",
                startedAt: date,
                durationSeconds: (offset + 1) * 1_200,
                folderId: "inbox",
                labelIds: ["focus"]
            )
        }

        return WidgetSnapshot(
            capturedAt: now,
            activeTimers: [runningTimer],
            entries: entries,
            folders: [WidgetFilterOption(id: "inbox", name: "Inbox")],
            labels: [WidgetFilterOption(id: "focus", name: "Focus")]
        )
    }()
}
