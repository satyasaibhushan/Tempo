import Foundation

public enum WidgetRange: String, Codable, CaseIterable, Sendable {
    case day
    case week
    case month
}

public struct WidgetFilterOption: Codable, Equatable, Identifiable, Sendable {
    public let id: DocumentID
    public let name: String

    public init(id: DocumentID, name: String) {
        self.id = id
        self.name = name
    }
}

public struct WidgetTimerSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: DocumentID
    public let title: String
    public let folderName: String?
    public let startedAt: Date?
    public let folderId: DocumentID?
    public let labelIds: [DocumentID]?
    public let status: TimerStatus
    public let elapsedSeconds: Int
    public let capturedAt: Date

    public init(
        id: DocumentID,
        title: String,
        folderName: String? = nil,
        startedAt: Date? = nil,
        folderId: DocumentID? = nil,
        labelIds: [DocumentID]? = nil,
        status: TimerStatus,
        elapsedSeconds: Int,
        capturedAt: Date
    ) {
        self.id = id
        self.title = title
        self.folderName = folderName
        self.startedAt = startedAt
        self.folderId = folderId
        self.labelIds = labelIds
        self.status = status
        self.elapsedSeconds = elapsedSeconds
        self.capturedAt = capturedAt
    }

    public var timerStartDate: Date {
        capturedAt.wholeSecond.addingTimeInterval(TimeInterval(-elapsedSeconds))
    }

    public func elapsedSeconds(at date: Date) -> Int {
        guard status == .running else {
            return elapsedSeconds
        }

        let secondsSinceCapture = max(
            Int(date.wholeSecond.timeIntervalSince(capturedAt.wholeSecond)),
            0
        )
        return elapsedSeconds + secondsSinceCapture
    }
}

public struct WidgetEntryRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: DocumentID
    public let startedAt: Date
    public let durationSeconds: Int
    public let folderId: DocumentID?
    public let labelIds: [DocumentID]

    public init(
        id: DocumentID,
        startedAt: Date,
        durationSeconds: Int,
        folderId: DocumentID? = nil,
        labelIds: [DocumentID] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.folderId = folderId
        self.labelIds = labelIds
    }
}

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public let capturedAt: Date
    public let activeTimers: [WidgetTimerSnapshot]
    public let entries: [WidgetEntryRecord]
    public let folders: [WidgetFilterOption]
    public let labels: [WidgetFilterOption]
    public let weekStart: WeekStart?

    public init(
        capturedAt: Date,
        activeTimers: [WidgetTimerSnapshot] = [],
        entries: [WidgetEntryRecord] = [],
        folders: [WidgetFilterOption] = [],
        labels: [WidgetFilterOption] = [],
        weekStart: WeekStart? = nil
    ) {
        self.capturedAt = capturedAt
        self.activeTimers = activeTimers
        self.entries = entries
        self.folders = folders
        self.labels = labels
        self.weekStart = weekStart
    }

    public static let empty = WidgetSnapshot(capturedAt: .distantPast)

    public func hasSameWidgetContent(as other: WidgetSnapshot) -> Bool {
        guard
            entries == other.entries,
            folders == other.folders,
            labels == other.labels,
            weekStart == other.weekStart,
            activeTimers.count == other.activeTimers.count
        else {
            return false
        }

        let otherTimers = Dictionary(uniqueKeysWithValues: other.activeTimers.map { ($0.id, $0) })
        return activeTimers.allSatisfy { timer in
            guard let otherTimer = otherTimers[timer.id] else { return false }
            return timer.hasSameWidgetContent(as: otherTimer)
        }
    }
}

private extension WidgetTimerSnapshot {
    func hasSameWidgetContent(as other: WidgetTimerSnapshot) -> Bool {
        guard
            id == other.id,
            title == other.title,
            folderName == other.folderName,
            startedAt == other.startedAt,
            folderId == other.folderId,
            Set(labelIds ?? []) == Set(other.labelIds ?? []),
            status == other.status
        else {
            return false
        }

        if status == .running {
            return timerStartDate == other.timerStartDate
        }

        return elapsedSeconds == other.elapsedSeconds
    }
}

public struct WidgetSummaryBucket: Equatable, Identifiable, Sendable {
    public let id: Date
    public let label: String
    public let durationSeconds: Int

    public init(id: Date, label: String, durationSeconds: Int) {
        self.id = id
        self.label = label
        self.durationSeconds = durationSeconds
    }
}

public struct WidgetSummary: Equatable, Sendable {
    public let range: WidgetRange
    public let totalSeconds: Int
    public let buckets: [WidgetSummaryBucket]

    public init(range: WidgetRange, totalSeconds: Int, buckets: [WidgetSummaryBucket]) {
        self.range = range
        self.totalSeconds = totalSeconds
        self.buckets = buckets
    }
}

public enum WidgetTimeText {
    public static func duration(_ seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3_600
        let minutes = safeSeconds % 3_600 / 60
        let remainingSeconds = safeSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

private extension Date {
    var wholeSecond: Date {
        Date(timeIntervalSince1970: timeIntervalSince1970.rounded(.down))
    }
}

public enum WidgetSnapshotStore {
    public static let appGroupIdentifier = "group.fun.bhushan.tempo"
    public static let inboxFilterIdentifier = "__inbox__"
    private static let snapshotKey = "time.widget.snapshot.v1"

    public enum SaveResult: Equatable, Sendable {
        case saved
        case unchanged
        case failed
    }

    #if os(macOS)
    private static var macOSFallbackSuiteName: String? {
        Bundle.main.object(forInfoDictionaryKey: "TempoWidgetPreferenceSuite") as? String
    }
    #endif

    @discardableResult
    public static func save(
        _ snapshot: WidgetSnapshot,
        suiteName: String = appGroupIdentifier
    ) -> Bool {
        #if os(macOS)
        let fallbackSuiteName = suiteName == appGroupIdentifier ? macOSFallbackSuiteName : nil
        #else
        let fallbackSuiteName: String? = nil
        #endif

        return save(
            snapshot,
            primarySuiteName: suiteName,
            fallbackSuiteName: fallbackSuiteName
        )
    }

    public static func load(
        suiteName: String = appGroupIdentifier
    ) -> WidgetSnapshot? {
        #if os(macOS)
        if suiteName == appGroupIdentifier, let macOSFallbackSuiteName {
            return load(primarySuiteName: macOSFallbackSuiteName, fallbackSuiteName: nil)
        }
        #endif

        return load(
            primarySuiteName: suiteName,
            fallbackSuiteName: nil
        )
    }

    public static func saveIfChanged(
        _ snapshot: WidgetSnapshot,
        suiteName: String = appGroupIdentifier
    ) -> SaveResult {
        if let current = load(suiteName: suiteName), current.hasSameWidgetContent(as: snapshot) {
            return .unchanged
        }

        return save(snapshot, suiteName: suiteName) ? .saved : .failed
    }

    @discardableResult
    static func save(
        _ snapshot: WidgetSnapshot,
        primarySuiteName: String,
        fallbackSuiteName: String?
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return false
        }

        let primarySaved = write(data, suiteName: primarySuiteName)
        let fallbackSaved = fallbackSuiteName.map {
            write(data, suiteName: $0, synchronize: true)
        }

        return fallbackSaved ?? primarySaved
    }

    static func load(
        primarySuiteName: String,
        fallbackSuiteName: String?
    ) -> WidgetSnapshot? {
        if let snapshot = read(suiteName: primarySuiteName) {
            return snapshot
        }

        guard let fallbackSuiteName else {
            return nil
        }

        return read(suiteName: fallbackSuiteName)
    }

    private static func write(
        _ data: Data,
        suiteName: String,
        synchronize: Bool = false
    ) -> Bool {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return false
        }

        defaults.set(data, forKey: snapshotKey)
        return !synchronize || defaults.synchronize()
    }

    private static func read(suiteName: String) -> WidgetSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: snapshotKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
