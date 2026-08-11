import Foundation
import Testing
@testable import TempoCore

@Test func cachedIDTokenMustOutliveTheAuthenticationWindow() {
    let token = "header.eyJleHAiOjEwMDB9.signature"

    #expect(
        IDTokenLifetime.isUsable(
            token,
            at: Date(timeIntervalSince1970: 900),
            minimumTTL: 60
        )
    )
    #expect(
        !IDTokenLifetime.isUsable(
            token,
            at: Date(timeIntervalSince1970: 950),
            minimumTTL: 60
        )
    )
}

@Test func malformedOrClaimlessIDTokensAreRejected() {
    #expect(!IDTokenLifetime.isUsable("not-a-jwt"))
    #expect(!IDTokenLifetime.isUsable("header.e30.signature"))
}

@Test func wholeSecondUsesTheSharedWallClockBoundary() {
    #expect(TimerMath.wholeSecond(12_999) == 12_000)
    #expect(TimerMath.wholeSecond(13_000) == 13_000)
}

@Test func timerRefreshesConvergeOnTheNextWallClockSecond() {
    let earlyViewPhase = Date(timeIntervalSince1970: 12.125)
    let lateViewPhase = Date(timeIntervalSince1970: 12.875)
    let expectedBoundary = Date(timeIntervalSince1970: 13)

    #expect(TimerMath.nextWholeSecondBoundary(after: earlyViewPhase) == expectedBoundary)
    #expect(TimerMath.nextWholeSecondBoundary(after: lateViewPhase) == expectedBoundary)
}

@Test func widgetTimerUsesTheSharedWallClockSecond() {
    let timer = WidgetTimerSnapshot(
        id: "timer-1",
        title: "Focused work",
        status: .running,
        elapsedSeconds: 11,
        capturedAt: Date(timeIntervalSince1970: 12.875)
    )

    #expect(timer.timerStartDate == Date(timeIntervalSince1970: 1))
    #expect(timer.elapsedSeconds(at: Date(timeIntervalSince1970: 13.1)) == 12)
}

@Test func widgetDurationMatchesTheAppClockFormat() {
    #expect(WidgetTimeText.duration(80) == "00:01:20")
}

@Test func pausedWidgetTimerDoesNotAdvance() {
    let timer = WidgetTimerSnapshot(
        id: "timer-1",
        title: "Paused work",
        status: .paused,
        elapsedSeconds: 11,
        capturedAt: Date(timeIntervalSince1970: 12.875)
    )

    #expect(timer.elapsedSeconds(at: Date(timeIntervalSince1970: 100)) == 11)
}

@Test func runningSegmentsAdvanceFromTheSameSecond() {
    let now: Int64 = 25_999
    let first = [TimeSegment(startTime: 1_000)]
    let second = [TimeSegment(startTime: 3_000)]

    #expect(TimerMath.elapsedSeconds(for: first, at: TimerMath.wholeSecond(now)) == 24)
    #expect(TimerMath.elapsedSeconds(for: second, at: TimerMath.wholeSecond(now)) == 22)
}

@Test func pausedSegmentsDoNotKeepAdvancing() {
    let segments = [
        TimeSegment(startTime: 1_000, endTime: 6_000),
        TimeSegment(startTime: 10_000, endTime: 13_000),
    ]

    #expect(TimerMath.elapsedSeconds(for: segments, at: 50_000) == 8)
}

@Test func completedEntryUsesItsStoredDuration() {
    let entry = TimeEntry(
        id: "entry-1",
        userId: "user-1",
        title: "Focused work",
        status: .completed,
        segments: [TimeSegment(startTime: 1_000, endTime: 10_000)],
        startedAt: 1_000,
        endedAt: 10_000,
        durationSeconds: 42,
        createdAt: 1_000,
        updatedAt: 10_000
    )

    #expect(TimerMath.elapsedSeconds(for: entry, at: 90_000) == 42)
}

@Test func environmentAcceptsOnlyConvexCloudHTTPSURLs() throws {
    let environment = try NativeEnvironment(
        convexURLString: "https://example-deployment.convex.cloud"
    )

    #expect(environment.convexURL.host == "example-deployment.convex.cloud")
    #expect(throws: NativeEnvironment.ConfigurationError.self) {
        try NativeEnvironment(convexURLString: "http://example.com")
    }
}

@Test func environmentUsesRuntimeValueBeforeEmbeddedBuildValue() throws {
    let environment = try NativeEnvironment.configured(
        environment: [
            "CONVEX_URL": "https://runtime-deployment.convex.cloud",
        ],
        infoDictionary: [
            "ConvexURL": "https://embedded-deployment.convex.cloud",
        ]
    )

    #expect(environment.convexURL.host == "runtime-deployment.convex.cloud")
}

@Test func environmentUsesEmbeddedBuildValueWhenRuntimeValueIsMissing() throws {
    let environment = try NativeEnvironment.configured(
        environment: [:],
        infoDictionary: [
            "ConvexURL": "https://embedded-deployment.convex.cloud",
        ]
    )

    #expect(environment.convexURL.host == "embedded-deployment.convex.cloud")
}

@Test func environmentRejectsMissingConfiguration() {
    #expect(throws: NativeEnvironment.ConfigurationError.missingConvexURL) {
        try NativeEnvironment.configured(environment: [:], infoDictionary: [:])
    }
}

@Test func convexModelsDecodeDocumentMetadata() throws {
    let json = """
    {
      "_id": "entry-1",
      "_creationTime": 1000.5,
      "userId": "user-1",
      "title": "",
      "manualLabelIds": [],
      "status": "running",
      "segments": [{ "startTime": 1000 }],
      "startedAt": 1000,
      "createdAt": 1000,
      "updatedAt": 1000
    }
    """

    let entry = try JSONDecoder().decode(TimeEntry.self, from: Data(json.utf8))

    #expect(entry.id == "entry-1")
    #expect(entry.creationTime == 1000.5)
    #expect(entry.status == .running)
}

@Test func widgetSummaryAppliesFolderAndLabelFilters() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: 12)))
    let matchingStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: 9)))
    let records = [
        WidgetEntryRecord(
            id: "matching",
            startedAt: matchingStart,
            durationSeconds: 3_600,
            folderId: "work",
            labelIds: ["focus"]
        ),
        WidgetEntryRecord(
            id: "wrong-label",
            startedAt: matchingStart,
            durationSeconds: 7_200,
            folderId: "work",
            labelIds: ["admin"]
        ),
    ]

    let summary = WidgetSummaryCalculator.summary(
        for: records,
        range: .week,
        folderId: "work",
        labelId: "focus",
        now: now,
        calendar: calendar
    )

    #expect(summary.totalSeconds == 3_600)
    #expect(summary.buckets.count == 7)
}

@Test func widgetDaySummarySplitsEntriesAcrossBuckets() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: 12)))
    let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: 3, minute: 30)))
    let record = WidgetEntryRecord(id: "split", startedAt: start, durationSeconds: 3_600)

    let summary = WidgetSummaryCalculator.summary(
        for: [record],
        range: .day,
        now: now,
        calendar: calendar
    )

    #expect(summary.buckets.map(\.durationSeconds) == [1_800, 1_800, 0, 0, 0, 0])
    #expect(summary.totalSeconds == 3_600)
}

@Test func widgetSummaryTreatsMissingFolderAsInbox() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: 12)))
    let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: 9)))
    let records = [
        WidgetEntryRecord(id: "inbox", startedAt: start, durationSeconds: 1_800),
        WidgetEntryRecord(
            id: "folder",
            startedAt: start,
            durationSeconds: 3_600,
            folderId: "work"
        ),
    ]

    let summary = WidgetSummaryCalculator.summary(
        for: records,
        range: .day,
        folderId: WidgetSnapshotStore.inboxFilterIdentifier,
        now: now,
        calendar: calendar
    )

    #expect(summary.totalSeconds == 1_800)
}

@Test func widgetWeekSummaryIncludesTheMatchingRunningTimer() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let now = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 13, hour: 17))
    )
    let timer = WidgetTimerSnapshot(
        id: "timer-1",
        title: "Focused work",
        startedAt: now.addingTimeInterval(-12),
        folderId: "work",
        labelIds: ["focus"],
        status: .running,
        elapsedSeconds: 11,
        capturedAt: now.addingTimeInterval(-1)
    )

    let summary = WidgetSummaryCalculator.summary(
        for: [],
        activeTimers: [timer],
        range: .week,
        folderId: "work",
        labelId: "focus",
        now: now,
        calendar: calendar,
        weekStart: .monday
    )

    #expect(summary.totalSeconds == 12)
    #expect(summary.buckets.map(\.durationSeconds) == [12, 0, 0, 0, 0, 0, 0])
}

@Test func widgetSnapshotLoadsFromFallbackPreferences() throws {
    let primarySuiteName = "fun.bhushan.tempo.tests.primary.\(UUID().uuidString)"
    let fallbackSuiteName = "fun.bhushan.tempo.tests.fallback.\(UUID().uuidString)"
    defer {
        UserDefaults.standard.removePersistentDomain(forName: primarySuiteName)
        UserDefaults.standard.removePersistentDomain(forName: fallbackSuiteName)
    }

    let snapshot = WidgetSnapshot(
        capturedAt: Date(timeIntervalSince1970: 1_000),
        folders: [WidgetFilterOption(id: "work", name: "Work")],
        labels: [WidgetFilterOption(id: "focus", name: "Focus")]
    )

    #expect(
        WidgetSnapshotStore.save(
            snapshot,
            primarySuiteName: primarySuiteName,
            fallbackSuiteName: fallbackSuiteName
        )
    )
    UserDefaults.standard.removePersistentDomain(forName: primarySuiteName)

    #expect(
        WidgetSnapshotStore.load(
            primarySuiteName: primarySuiteName,
            fallbackSuiteName: fallbackSuiteName
        ) == snapshot
    )
}

@Test func equivalentLiveWidgetSnapshotsDoNotRequireAnotherReload() {
    let firstCapture = Date(timeIntervalSince1970: 100)
    let first = WidgetSnapshot(
        capturedAt: firstCapture,
        activeTimers: [
            WidgetTimerSnapshot(
                id: "timer-1",
                title: "Focused work",
                startedAt: Date(timeIntervalSince1970: 10),
                status: .running,
                elapsedSeconds: 40,
                capturedAt: firstCapture
            ),
        ]
    )
    let laterCapture = firstCapture.addingTimeInterval(10)
    let equivalent = WidgetSnapshot(
        capturedAt: laterCapture,
        activeTimers: [
            WidgetTimerSnapshot(
                id: "timer-1",
                title: "Focused work",
                startedAt: Date(timeIntervalSince1970: 10),
                status: .running,
                elapsedSeconds: 50,
                capturedAt: laterCapture
            ),
        ]
    )
    let paused = WidgetSnapshot(
        capturedAt: laterCapture,
        activeTimers: [
            WidgetTimerSnapshot(
                id: "timer-1",
                title: "Focused work",
                startedAt: Date(timeIntervalSince1970: 10),
                status: .paused,
                elapsedSeconds: 50,
                capturedAt: laterCapture
            ),
        ]
    )

    #expect(first.hasSameWidgetContent(as: equivalent))
    #expect(!first.hasSameWidgetContent(as: paused))
}

@Test func widgetStoreSkipsEquivalentLiveSnapshotWrites() {
    let suiteName = "fun.bhushan.tempo.tests.unchanged.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let firstCapture = Date(timeIntervalSince1970: 100)
    let first = WidgetSnapshot(
        capturedAt: firstCapture,
        activeTimers: [
            WidgetTimerSnapshot(
                id: "timer-1",
                title: "Focused work",
                status: .running,
                elapsedSeconds: 40,
                capturedAt: firstCapture
            ),
        ]
    )
    let laterCapture = firstCapture.addingTimeInterval(10)
    let equivalent = WidgetSnapshot(
        capturedAt: laterCapture,
        activeTimers: [
            WidgetTimerSnapshot(
                id: "timer-1",
                title: "Focused work",
                status: .running,
                elapsedSeconds: 50,
                capturedAt: laterCapture
            ),
        ]
    )

    #expect(WidgetSnapshotStore.saveIfChanged(first, suiteName: suiteName) == .saved)
    #expect(WidgetSnapshotStore.saveIfChanged(equivalent, suiteName: suiteName) == .unchanged)
    #expect(WidgetSnapshotStore.load(suiteName: suiteName) == first)
}

@Test func widgetHistoryStartsAtTheEarliestVisibleRange() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let now = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 12))
    )
    let expectedMondayStart = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 27))
    )
    let expectedSundayStart = try #require(
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 26))
    )

    #expect(
        WidgetSummaryCalculator.oldestRelevantDate(
            now: now,
            calendar: calendar,
            weekStart: .monday
        ) == expectedMondayStart
    )
    #expect(
        WidgetSummaryCalculator.oldestRelevantDate(
            now: now,
            calendar: calendar,
            weekStart: .sunday
        ) == expectedSundayStart
    )
}
