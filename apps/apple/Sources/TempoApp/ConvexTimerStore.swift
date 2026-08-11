import Combine
@preconcurrency import ConvexMobile
import Foundation
import Observation
import TempoCore
import WidgetKit

@MainActor
@Observable
final class ConvexTimerStore {
    var draftTitle = ""
    private(set) var profile: UserProfile?
    private(set) var timers: [TimeEntry] = []
    private(set) var completedEntries: [TimeEntry] = []
    private(set) var folders: [Folder] = []
    private(set) var labels: [TempoCore.Label] = []
    private(set) var pendingMutationCount = 0
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let client: ConvexClient
    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []
    @ObservationIgnored
    private var loadedWidgetSources: Set<WidgetSource> = []
    @ObservationIgnored
    private var widgetPublicationTask: Task<Void, Never>?

    init(client: ConvexClient) {
        self.client = client
        subscribeToBackend()
    }

    var runningCount: Int {
        timers.count { $0.status == .running }
    }

    var isMutating: Bool {
        pendingMutationCount > 0
    }

    var activeFolders: [Folder] {
        folders.filter { !$0.archived }
    }

    func folder(for id: DocumentID?) -> Folder? {
        guard let id else { return nil }
        return folders.first { $0.id == id }
    }

    func label(for id: DocumentID) -> TempoCore.Label? {
        labels.first { $0.id == id }
    }

    func updateProfile(name: String, email: String) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Users.updateProfile,
                with: [
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
                ]
            )
        }
    }

    func updatePreferences(
        timezone: String,
        timeFormat: TimeFormat,
        weekStart: WeekStart
    ) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Users.updatePreferences,
                with: [
                    "timezone": timezone.trimmingCharacters(in: .whitespacesAndNewlines),
                    "timeFormat": timeFormat.rawValue,
                    "weekStart": weekStart.rawValue,
                ]
            )
        }
    }

    func startTimer() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        draftTitle = ""
        mutate {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.TimeEntries.start,
                with: ["title": title]
            )
        }
    }

    func startTimer(
        title: String,
        notes: String,
        folderId: DocumentID?,
        labelIds: Set<DocumentID>
    ) async -> Bool {
        var args: [String: ConvexEncodable?] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "manualLabelIds": convexIds(labelIds),
        ]
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanNotes.isEmpty { args["notes"] = cleanNotes }
        if let folderId { args["folderId"] = folderId }
        return await performMutation(ConvexAPI.TimeEntries.start, args: consume args)
    }

    func toggleTimer(_ timer: TimeEntry) {
        let mutation = timer.status == .running
            ? ConvexAPI.TimeEntries.pause
            : ConvexAPI.TimeEntries.resume
        mutate {
            let _: DocumentID = try await self.client.mutation(
                mutation,
                with: ["entryId": timer.id]
            )
        }
    }

    func editActiveTimer(
        _ timer: TimeEntry,
        title: String,
        notes: String,
        folderId: DocumentID?,
        labelIds: Set<DocumentID>,
        start: Date
    ) async -> Bool {
        var args: [String: ConvexEncodable?] = [
            "entryId": timer.id,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "notes": notes.trimmingCharacters(in: .whitespacesAndNewlines),
            "manualLabelIds": convexIds(labelIds),
            "startTime": Double(start.millisecondsSince1970),
        ]
        if let folderId {
            args["folderId"] = folderId
        } else {
            args["clearFolder"] = true
        }
        return await performMutation(ConvexAPI.TimeEntries.editActive, args: consume args)
    }

    func stopTimer(_ timer: TimeEntry) {
        mutate {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.TimeEntries.stop,
                with: ["entryId": timer.id]
            )
        }
    }

    func discardTimer(_ timer: TimeEntry) {
        mutate {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.TimeEntries.discard,
                with: ["entryId": timer.id]
            )
        }
    }

    func continueEntry(_ entry: TimeEntry) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.TimeEntries.continueEntry,
                with: ["sourceEntryId": entry.id]
            )
        }
    }

    func createManualEntry(
        title: String,
        notes: String,
        folderId: DocumentID?,
        labelIds: Set<DocumentID>,
        start: Date,
        end: Date
    ) async -> Bool {
        var args: [String: ConvexEncodable?] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "manualLabelIds": convexIds(labelIds),
            "startTime": Double(start.millisecondsSince1970),
            "endTime": Double(end.millisecondsSince1970),
        ]
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanNotes.isEmpty { args["notes"] = cleanNotes }
        if let folderId { args["folderId"] = folderId }
        return await performMutation(ConvexAPI.TimeEntries.createManual, args: consume args)
    }

    func editEntry(
        _ entry: TimeEntry,
        title: String,
        notes: String,
        folderId: DocumentID?,
        labelIds: Set<DocumentID>,
        start: Date,
        end: Date
    ) async -> Bool {
        var args: [String: ConvexEncodable?] = [
            "entryId": entry.id,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "notes": notes.trimmingCharacters(in: .whitespacesAndNewlines),
            "manualLabelIds": convexIds(labelIds),
            "startTime": Double(start.millisecondsSince1970),
            "endTime": Double(end.millisecondsSince1970),
        ]
        if let folderId {
            args["folderId"] = folderId
        } else {
            args["clearFolder"] = true
        }
        return await performMutation(ConvexAPI.TimeEntries.edit, args: consume args)
    }

    func deleteEntry(_ entry: TimeEntry) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.TimeEntries.delete,
                with: ["entryId": entry.id]
            )
        }
    }

    func createFolder(
        name: String,
        color: String?,
        parentFolderId: DocumentID?,
        defaultLabelIds: Set<DocumentID>
    ) async -> Bool {
        var args: [String: ConvexEncodable?] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "defaultLabelIds": convexIds(defaultLabelIds),
        ]
        if let color { args["color"] = color }
        if let parentFolderId { args["parentFolderId"] = parentFolderId }
        return await performMutation(ConvexAPI.Folders.create, args: consume args)
    }

    func updateFolder(
        _ folder: Folder,
        name: String,
        parentFolderId: DocumentID?,
        defaultLabelIds: Set<DocumentID>
    ) async -> Bool {
        let renamed = await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Folders.rename,
                with: ["folderId": folder.id, "name": name.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
        }
        guard renamed else { return false }

        let moved = await performMutation {
            var args: [String: ConvexEncodable?] = ["folderId": folder.id]
            if let parentFolderId { args["newParentFolderId"] = parentFolderId }
            let _: DocumentID = try await self.client.mutation(ConvexAPI.Folders.move, with: args)
        }
        guard moved else { return false }

        return await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Folders.updateDefaultLabels,
                with: ["folderId": folder.id, "defaultLabelIds": convexIds(defaultLabelIds)]
            )
        }
    }

    func setFolderArchived(_ folder: Folder, archived: Bool) async -> Bool {
        await performMutation {
            let mutation = archived ? ConvexAPI.Folders.archive : ConvexAPI.Folders.unarchive
            let _: DocumentID = try await self.client.mutation(mutation, with: ["folderId": folder.id])
        }
    }

    func deleteFolder(_ folder: Folder) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Folders.delete,
                with: ["folderId": folder.id]
            )
        }
    }

    func createLabel(name: String, color: String) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Labels.create,
                with: ["name": name.trimmingCharacters(in: .whitespacesAndNewlines), "color": color]
            )
        }
    }

    func updateLabel(_ label: TempoCore.Label, name: String, color: String) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Labels.update,
                with: [
                    "labelId": label.id,
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "color": color,
                ]
            )
        }
    }

    func deleteLabel(_ label: TempoCore.Label) async -> Bool {
        await performMutation {
            let _: DocumentID = try await self.client.mutation(
                ConvexAPI.Labels.delete,
                with: ["labelId": label.id]
            )
        }
    }

    func deleteAccount() async -> Bool {
        await performMutation {
            let _: Bool = try await self.client.action(
                ConvexAPI.AccountDeletion.deleteCurrent
            )
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func subscribeToBackend() {
        subscribe(
            source: .profile,
            client.subscribe(
                to: ConvexAPI.Users.current,
                yielding: UserProfile?.self
            )
        ) { store, profile in
            guard store.profile != profile else { return false }
            store.profile = profile
            return true
        }

        subscribe(
            source: .timers,
            client.subscribe(
                to: ConvexAPI.TimeEntries.listActive,
                yielding: [TimeEntry].self
            )
        ) { store, timers in
            guard store.timers != timers else { return false }
            store.timers = timers
            return true
        }

        subscribe(
            source: .entries,
            client.subscribe(
                to: ConvexAPI.TimeEntries.listRecent,
                with: ["limit": 1_000.0],
                yielding: [TimeEntry].self
            )
        ) { store, entries in
            guard store.completedEntries != entries else { return false }
            store.completedEntries = entries
            return true
        }

        subscribe(
            source: .folders,
            client.subscribe(
                to: ConvexAPI.Folders.listAll,
                yielding: [Folder].self
            )
        ) { store, folders in
            guard store.folders != folders else { return false }
            store.folders = folders
            return true
        }

        subscribe(
            source: .labels,
            client.subscribe(
                to: ConvexAPI.Labels.list,
                yielding: [TempoCore.Label].self
            )
        ) { store, labels in
            guard store.labels != labels else { return false }
            store.labels = labels
            return true
        }
    }

    private func subscribe<Value>(
        source: WidgetSource,
        _ publisher: AnyPublisher<Value, ClientError>,
        apply: @escaping (ConvexTimerStore, Value) -> Bool
    ) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard case .failure(let error) = completion else { return }
                    self?.errorMessage = error.localizedDescription
                },
                receiveValue: { [weak self] value in
                    guard let self else { return }
                    let changed = apply(self, value)
                    let becameReady = self.loadedWidgetSources.insert(source).inserted
                        && self.loadedWidgetSources.count == WidgetSource.allCases.count
                    guard self.loadedWidgetSources.count == WidgetSource.allCases.count else { return }
                    if changed || becameReady {
                        self.scheduleWidgetSnapshotPublication()
                    }
                }
            )
            .store(in: &subscriptions)
    }

    private func mutate(_ operation: @escaping () async throws -> Void) {
        pendingMutationCount += 1
        errorMessage = nil

        Task {
            defer { pendingMutationCount -= 1 }
            do {
                try await operation()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func performMutation(_ operation: @escaping () async throws -> Void) async -> Bool {
        pendingMutationCount += 1
        errorMessage = nil
        defer { pendingMutationCount -= 1 }

        do {
            try await operation()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func performMutation(
        _ name: String,
        args: sending [String: ConvexEncodable?]
    ) async -> Bool {
        pendingMutationCount += 1
        errorMessage = nil
        defer { pendingMutationCount -= 1 }

        do {
            let _: DocumentID = try await client.mutation(name, with: consume args)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func scheduleWidgetSnapshotPublication() {
        widgetPublicationTask?.cancel()
        widgetPublicationTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(250))
            } catch {
                return
            }

            guard let self else { return }
            let snapshot = self.makeWidgetSnapshot()
            let result = await Task.detached(priority: .utility) {
                WidgetSnapshotStore.saveIfChanged(snapshot)
            }.value

            guard !Task.isCancelled, result == .saved else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func makeWidgetSnapshot(now: Date = .now) -> WidgetSnapshot {
        let nowMilliseconds = Int64((now.timeIntervalSince1970 * 1_000).rounded(.down))
        let foldersById = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0) })
        let activeSnapshots = timers.map { timer in
            WidgetTimerSnapshot(
                id: timer.id,
                title: timer.title,
                folderName: timer.folderId.flatMap { foldersById[$0]?.name } ?? "Inbox",
                startedAt: Date(timeIntervalSince1970: TimeInterval(timer.startedAt) / 1_000),
                folderId: timer.folderId,
                labelIds: effectiveLabelIds(for: timer, foldersById: foldersById),
                status: timer.status,
                elapsedSeconds: TimerMath.elapsedSeconds(for: timer, at: nowMilliseconds),
                capturedAt: now
            )
        }
        let oldestRelevantDate = WidgetSummaryCalculator.oldestRelevantDate(
            now: now,
            weekStart: profile?.weekStart
        )
        let records = completedEntries.compactMap { entry -> WidgetEntryRecord? in
            guard let durationSeconds = entry.durationSeconds else { return nil }
            let startedAt = Date(timeIntervalSince1970: TimeInterval(entry.startedAt) / 1_000)
            guard startedAt.addingTimeInterval(TimeInterval(durationSeconds)) > oldestRelevantDate else {
                return nil
            }
            return WidgetEntryRecord(
                id: entry.id,
                startedAt: startedAt,
                durationSeconds: durationSeconds,
                folderId: entry.folderId,
                labelIds: effectiveLabelIds(for: entry, foldersById: foldersById)
            )
        }
        let snapshot = WidgetSnapshot(
            capturedAt: now,
            activeTimers: activeSnapshots,
            entries: records,
            folders: [
                WidgetFilterOption(
                    id: WidgetSnapshotStore.inboxFilterIdentifier,
                    name: "Inbox"
                ),
            ] + folders.filter { !$0.archived }.map {
                WidgetFilterOption(id: $0.id, name: $0.name)
            },
            labels: labels.map { WidgetFilterOption(id: $0.id, name: $0.name) },
            weekStart: profile?.weekStart
        )
        return snapshot
    }

    private func effectiveLabelIds(
        for entry: TimeEntry,
        foldersById: [DocumentID: Folder]
    ) -> [DocumentID] {
        var result = Set(entry.manualLabelIds)
        var folderId = entry.folderId
        var visited: Set<DocumentID> = []

        while
            let currentId = folderId,
            visited.insert(currentId).inserted,
            let folder = foldersById[currentId]
        {
            result.formUnion(folder.defaultLabelIds)
            folderId = folder.parentFolderId
        }

        return result.sorted()
    }
}

private enum WidgetSource: CaseIterable {
    case profile
    case timers
    case entries
    case folders
    case labels
}

private func convexIds<S: Sequence>(_ ids: S) -> [ConvexEncodable?]
where S.Element == DocumentID {
    ids.map { $0 }
}
