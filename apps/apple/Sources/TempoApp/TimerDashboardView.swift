import SwiftUI
import TempoCore

struct TimerDashboardView: View {
    @Bindable var store: ConvexTimerStore
    @State private var notes = ""
    @State private var selectedFolderId: DocumentID?
    @State private var selectedLabelIds: Set<DocumentID> = []
    @State private var showingOptions = false
    @State private var editingTimer: TimeEntry?
    @State private var timerTickAnchor = TimerMath.nextWholeSecondBoundary(after: .now)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    #if os(macOS)
                    timerList
                    macStartComposer
                    MacDashboardInsights(store: store)
                    #else
                    startComposer
                    timerList
                    recentEntries
                    #endif
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
            .background(TempoTheme.canvas.ignoresSafeArea())
            .navigationTitle("Tempo")
            .timeNavigationChrome()
            .alert("Couldn’t update timer", isPresented: errorBinding) {
                Button("OK") { store.clearError() }
            } message: {
                Text(store.errorMessage ?? "Please try again.")
            }
            .sheet(item: $editingTimer) { timer in
                ActiveTimerEditorSheet(store: store, timer: timer)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )
    }

    private var header: some View {
        TerraPageHeader(
            kicker: Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)),
            title: greeting,
            subtitle: todaySeconds > 0
                ? "\(TimeText.duration(todaySeconds)) recorded so far today."
                : "Nothing recorded yet today — the first session sets the tone."
        )
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let greeting = switch hour {
        case 0..<5: "Up late"
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
        let firstName = store.profile?.name?.split(separator: " ").first.map(String.init)
        return firstName.map { "\(greeting), \($0)." } ?? "\(greeting)."
    }

    private var todaySeconds: Int {
        let calendar = Calendar.current
        let completed = store.completedEntries
            .filter { calendar.isDateInToday(Date(milliseconds: $0.startedAt)) }
            .reduce(0) { $0 + ($1.durationSeconds ?? 0) }
        let now = Int64((Date.now.timeIntervalSince1970 * 1_000).rounded(.down))
        let active = store.timers
            .filter { calendar.isDateInToday(Date(milliseconds: $0.startedAt)) }
            .reduce(0) { $0 + TimerMath.elapsedSeconds(for: $1, at: now) }
        return completed + active
    }

    private var startComposer: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("START A TIMER")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(TempoTheme.sage)
                Spacer()
                liveStatus
            }

            TextField("What are you working on?", text: $store.draftTitle, axis: .vertical)
                .font(.body.weight(.semibold))
                .foregroundStyle(TempoTheme.ink)
                .timeSentenceInput()
                .onSubmit(start)

            if showingOptions {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(2...4)

                FolderPicker(folders: store.activeFolders, selection: $selectedFolderId)

                DisclosureGroup("Labels · \(selectedLabelIds.count) selected") {
                    VStack(spacing: 12) {
                        LabelSelectionList(labels: store.labels, selection: $selectedLabelIds)
                    }
                    .padding(.top, 10)
                }
                .font(.subheadline.weight(.semibold))
                .tint(TempoTheme.moss)
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showingOptions.toggle() }
                } label: {
                    Label(folderName, systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TempoTheme.mutedInk)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: start) {
                    Label("Start", systemImage: "play.fill")
                        .frame(minWidth: 76)
                }
                .buttonStyle(PrimaryCapsuleButtonStyle())
                .disabled(store.isMutating)
            }
        }
        .terraSurface(padding: 20)
    }

    #if os(macOS)
    private var macStartComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                TextField("What are you working on?", text: $store.draftTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(TempoTheme.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(TempoTheme.muted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onSubmit(start)

                Button(action: start) {
                    Label("Start", systemImage: "play.fill")
                        .frame(minWidth: 84)
                }
                .buttonStyle(PrimaryCapsuleButtonStyle())
                .disabled(store.isMutating)
            }

            HStack(spacing: 8) {
                Menu {
                    Button("Inbox") { selectedFolderId = nil }
                    ForEach(store.activeFolders) { folder in
                        Button(folder.name) { selectedFolderId = folder.id }
                    }
                } label: {
                    MacTimerFilterPill(
                        icon: "folder",
                        text: folderName,
                        active: selectedFolderId != nil
                    )
                }

                Menu {
                    if store.labels.isEmpty {
                        Text("No labels yet")
                    } else {
                        ForEach(store.labels) { label in
                            Button {
                                if selectedLabelIds.contains(label.id) {
                                    selectedLabelIds.remove(label.id)
                                } else {
                                    selectedLabelIds.insert(label.id)
                                }
                            } label: {
                                Label(
                                    label.name,
                                    systemImage: selectedLabelIds.contains(label.id) ? "checkmark" : "circle"
                                )
                            }
                        }
                    }
                } label: {
                    MacTimerFilterPill(
                        icon: "tag",
                        text: selectedLabelIds.isEmpty ? "Labels" : "\(selectedLabelIds.count) labels",
                        active: !selectedLabelIds.isEmpty
                    )
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showingOptions.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Text("Notes")
                        Image(systemName: showingOptions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TempoTheme.sage)
                }
                .buttonStyle(.plain)
            }

            if showingOptions {
                TextField("Optional context for later", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .lineLimit(2...4)
                    .padding(14)
                    .background(TempoTheme.muted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .terraSurface(padding: 20)
    }
    #endif

    private var liveStatus: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(store.runningCount > 0 ? TempoTheme.gold : TempoTheme.line)
                .frame(width: 7, height: 7)
            Text(store.runningCount > 0 ? "\(store.runningCount) live" : "Idle")
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(store.runningCount > 0 ? TempoTheme.mutedInk : TempoTheme.sage)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(TempoTheme.muted, in: Capsule())
    }

    private var folderName: String {
        store.folder(for: selectedFolderId)?.name ?? "Inbox"
    }

    private func start() {
        let title = store.draftTitle
        store.draftTitle = ""
        Task {
            let success = await store.startTimer(
                title: title,
                notes: notes,
                folderId: selectedFolderId,
                labelIds: selectedLabelIds
            )
            if success {
                notes = ""
                selectedFolderId = nil
                selectedLabelIds = []
                showingOptions = false
            } else {
                store.draftTitle = title
            }
        }
    }

    @ViewBuilder
    private var timerList: some View {
        if store.timers.isEmpty {
            #if os(macOS)
            EmptyView()
            #else
            TerraEmptyState(
                icon: "timer",
                title: "No active timers",
                message: "Start with one clear intention. Multiple timers will stay on the same second."
            )
            .terraSurface()
            #endif
        } else {
            TimelineView(.periodic(from: timerTickAnchor, by: 1)) { context in
                LazyVStack(spacing: 14) {
                    ForEach(store.timers) { timer in
                        TimerCard(
                            timer: timer,
                            folderName: store.folder(for: timer.folderId)?.name ?? "Inbox",
                            labels: effectiveLabels(for: timer),
                            now: context.date,
                            onEdit: { editingTimer = timer },
                            onToggle: { store.toggleTimer(timer) },
                            onStop: { store.stopTimer(timer) },
                            onDiscard: { store.discardTimer(timer) }
                        )
                    }
                }
            }
        }
    }

    private func effectiveLabels(for entry: TimeEntry) -> [TempoCore.Label] {
        var ids = Set(entry.manualLabelIds)
        var folderId = entry.folderId
        var visited: Set<DocumentID> = []
        while let current = folderId,
              visited.insert(current).inserted,
              let folder = store.folder(for: current) {
            ids.formUnion(folder.defaultLabelIds)
            folderId = folder.parentFolderId
        }
        return store.labels.filter { ids.contains($0.id) }
    }

    @ViewBuilder
    private var recentEntries: some View {
        if !store.completedEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("RECENTLY RECORDED")
                    .font(.caption.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(TempoTheme.sage)

                ForEach(store.completedEntries.prefix(3)) { entry in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title.isEmpty ? "Untitled session" : entry.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TempoTheme.ink)
                                .lineLimit(1)
                            Text(Date(milliseconds: entry.startedAt).formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(TempoTheme.sage)
                        }
                        Spacer()
                        Text(TimeText.compactDuration(entry.durationSeconds ?? 0))
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(TempoTheme.mutedInk)
                    }
                    if entry.id != store.completedEntries.prefix(3).last?.id {
                        Divider().overlay(TempoTheme.line)
                    }
                }
            }
            .terraSurface()
        }
    }
}

private struct TimerCard: View {
    let timer: TimeEntry
    let folderName: String
    let labels: [TempoCore.Label]
    let now: Date
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onStop: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Circle()
                    .fill(timer.status == .running ? TempoTheme.gold : TempoTheme.sage)
                    .frame(width: 8, height: 8)
                Text(timer.status == .running ? "TRACKING NOW" : "ON HOLD")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                Spacer()
                Menu {
                    Button("Edit Timer", systemImage: "pencil", action: onEdit)
                    Button("Discard Timer", systemImage: "trash", role: .destructive, action: onDiscard)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(TempoTheme.softGreen)
                        .frame(width: 32, height: 32)
                }
            }
            .foregroundStyle(TempoTheme.softGreen)

            Text(TimeText.duration(elapsed))
                .font(.system(size: timerFontSize, weight: .medium, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            VStack(alignment: .leading, spacing: 9) {
                Text(timer.title.isEmpty ? "Untitled session" : timer.title)
                    .font(.headline)
                    .italic(timer.title.isEmpty)
                    .foregroundStyle(timer.title.isEmpty ? TempoTheme.softGreen : Color.white.opacity(0.94))
                if let notes = timer.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(TempoTheme.softGreen)
                        .lineLimit(2)
                }
                HStack {
                    TimerHeroBadge(text: folderName, color: TempoTheme.gold, foreground: Color(hex: "#3c2a12"))
                    ForEach(labels) { label in
                        TimerHeroBadge(
                            text: label.name,
                            color: Color.white.opacity(0.12),
                            foreground: Color(hex: "#cfdcc2")
                        )
                    }
                    Spacer()
                    Button(action: onToggle) {
                        Label(
                            timer.status == .running ? "Pause" : "Resume",
                            systemImage: timer.status == .running ? "pause.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(SecondaryCapsuleButtonStyle())
                    #if os(macOS)
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(HeroGhostButtonStyle())
                    Button(action: onStop) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(LightCapsuleButtonStyle())
                    Button(action: onDiscard) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(HeroGhostButtonStyle())
                    #else
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(LightCircleButtonStyle())
                    #endif
                }
            }
        }
        .foregroundStyle(Color.white.opacity(0.94))
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(timer.status == .running ? TempoTheme.timerSurface : TempoTheme.timerSurfaceSoft)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(TempoTheme.gold.opacity(0.18))
                        .frame(width: 150, height: 150)
                        .blur(radius: 26)
                        .offset(x: 55, y: -65)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var elapsed: Int {
        let milliseconds = Int64((now.timeIntervalSince1970 * 1_000).rounded(.down))
        return TimerMath.elapsedSeconds(for: timer, at: milliseconds)
    }

    private var timerFontSize: CGFloat {
        #if os(macOS)
        64
        #else
        50
        #endif
    }
}

private struct ActiveTimerEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: ConvexTimerStore
    let timer: TimeEntry

    @State private var title: String
    @State private var notes: String
    @State private var folderId: DocumentID?
    @State private var labelIds: Set<DocumentID>
    @State private var start: Date

    init(store: ConvexTimerStore, timer: TimeEntry) {
        self.store = store
        self.timer = timer
        _title = State(initialValue: timer.title)
        _notes = State(initialValue: timer.notes ?? "")
        _folderId = State(initialValue: timer.folderId)
        _labelIds = State(initialValue: Set(timer.manualLabelIds))
        _start = State(initialValue: Date(milliseconds: timer.startedAt))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Timer") {
                    TextField("What are you working on?", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Started") {
                    DatePicker("Start time", selection: $start, in: ...latestAllowedStart)
                    Text("The clock keeps running; pause and resume history stays intact.")
                        .font(.caption)
                        .foregroundStyle(TempoTheme.sage)
                }

                Section("Folder") {
                    FolderPicker(folders: store.activeFolders, selection: $folderId)
                        .labelsHidden()
                }

                Section("Labels") {
                    LabelSelectionList(labels: store.labels, selection: $labelIds)
                }
            }
            .scrollContentBackground(.hidden)
            .background(TempoTheme.canvas)
            .navigationTitle("Edit Active Timer")
            .timeInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(start > latestAllowedStart || store.isMutating)
                }
            }
        }
    }

    private var latestAllowedStart: Date {
        timer.segments.first?.endTime.map(Date.init(milliseconds:)) ?? .now
    }

    private func save() {
        Task {
            let success = await store.editActiveTimer(
                timer,
                title: title,
                notes: notes,
                folderId: folderId,
                labelIds: labelIds,
                start: start
            )
            if success { dismiss() }
        }
    }
}

#if os(macOS)
private struct MacDashboardInsights: View {
    @Bindable var store: ConvexTimerStore
    @State private var weekFolderFilter = "all"
    @State private var weekLabelFilter = "all"

    var body: some View {
        TimelineView(.periodic(from: TimerMath.nextWholeSecondBoundary(after: .now), by: 1)) { context in
            VStack(spacing: 20) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 20) {
                        todayCard(now: context.date)
                            .frame(minWidth: 320, maxWidth: .infinity)
                        weekCard(now: context.date)
                            .frame(width: 420)
                    }
                    VStack(spacing: 20) {
                        todayCard(now: context.date)
                        weekCard(now: context.date)
                    }
                }
                monthCard(now: context.date)
            }
        }
    }

    private func todayCard(now: Date) -> some View {
        let entries = allEntries.filter { Calendar.current.isDateInToday(Date(milliseconds: $0.startedAt)) }
        let seconds = entries.reduce(0) { $0 + duration($1, now: now) }

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(TempoTheme.sage)
                    Text("\(entries.count) \(entries.count == 1 ? "session" : "sessions")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(TempoTheme.ink)
                }
                Spacer()
                Text(TimeText.duration(seconds))
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(TempoTheme.sage)
            }

            if entries.isEmpty {
                Text("Sessions you track today will land here.")
                    .font(.subheadline)
                    .foregroundStyle(TempoTheme.sage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 34)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(TempoTheme.input, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
            } else {
                VStack(spacing: 0) {
                    ForEach(entries.sorted { $0.startedAt > $1.startedAt }) { entry in
                        MacDashboardEntryRow(
                            entry: entry,
                            folderName: store.folder(for: entry.folderId)?.name ?? "Inbox",
                            duration: duration(entry, now: now)
                        )
                        if entry.id != entries.sorted(by: { $0.startedAt > $1.startedAt }).last?.id {
                            Divider().overlay(TempoTheme.line)
                        }
                    }
                }
            }
        }
        .terraSurface(padding: 20)
    }

    private func weekCard(now: Date) -> some View {
        let days = weekDays(now: now)
        let maxSeconds = max(days.map(\.seconds).max() ?? 0, 1)
        let total = days.reduce(0) { $0 + $1.seconds }

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(TempoTheme.sage)
                    Text(total == 0 ? "No time yet" : "\(formatHours(total)) tracked")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(TempoTheme.ink)
                }
                Spacer()
                Menu {
                    Button { weekFolderFilter = "all" } label: {
                        Label("All folders", systemImage: weekFolderFilter == "all" ? "checkmark" : "square.stack.3d.up")
                    }
                    Button { weekFolderFilter = "inbox" } label: {
                        Label("Inbox", systemImage: weekFolderFilter == "inbox" ? "checkmark" : "tray")
                    }
                    ForEach(store.activeFolders) { folder in
                        Button { weekFolderFilter = folder.id } label: {
                            Label(folder.name, systemImage: weekFolderFilter == folder.id ? "checkmark" : "folder")
                        }
                    }
                } label: {
                    MacTimerFilterPill(icon: "folder", text: weekFolderName, active: weekFolderFilter != "all")
                }
                Menu {
                    Button { weekLabelFilter = "all" } label: {
                        Label("All labels", systemImage: weekLabelFilter == "all" ? "checkmark" : "tag")
                    }
                    ForEach(store.labels) { label in
                        Button { weekLabelFilter = label.id } label: {
                            Label(label.name, systemImage: weekLabelFilter == label.id ? "checkmark" : "tag")
                        }
                    }
                } label: {
                    MacTimerFilterPill(icon: "tag", text: weekLabelName, active: weekLabelFilter != "all")
                }
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(days) { day in
                    VStack(spacing: 7) {
                        Spacer(minLength: 0)
                        if day.seconds > 0 {
                            Text(formatHours(day.seconds))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(TempoTheme.sage)
                        }
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Calendar.current.isDateInToday(day.date) ? TempoTheme.clay : TempoTheme.moss.opacity(0.75))
                            .frame(
                                height: day.seconds == 0
                                    ? 4
                                    : max(8, CGFloat(day.seconds) / CGFloat(maxSeconds) * 108)
                            )
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Calendar.current.isDateInToday(day.date) ? TempoTheme.clay : TempoTheme.sage)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
        }
        .terraSurface(padding: 20)
    }

    private func monthCard(now: Date) -> some View {
        let calendar = Calendar.current
        let monthEntries = allEntries.filter {
            calendar.isDate(Date(milliseconds: $0.startedAt), equalTo: now, toGranularity: .month)
        }
        let total = monthEntries.reduce(0) { $0 + duration($1, now: now) }
        let folders = breakdownByFolder(entries: monthEntries, now: now)
        let labels = breakdownByLabel(entries: monthEntries, now: now)

        return VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THIS MONTH")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(TempoTheme.sage)
                Text(total == 0 ? "No time yet" : "\(TimeText.duration(total)) tracked")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(TempoTheme.ink)
            }

            HStack(alignment: .top, spacing: 28) {
                MacBreakdown(title: "By folder", items: folders)
                MacBreakdown(title: "By label", items: labels)
            }
        }
        .terraSurface(padding: 20)
    }

    private var allEntries: [TimeEntry] {
        store.timers + store.completedEntries
    }

    private func duration(_ entry: TimeEntry, now: Date) -> Int {
        if let duration = entry.durationSeconds { return duration }
        return TimerMath.elapsedSeconds(for: entry, at: now.millisecondsSince1970)
    }

    private func weekDays(now: Date) -> [MacWeekDay] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: startOfToday)
        let mondayOffset = (weekday + 5) % 7
        let offset = store.profile?.weekStart == .sunday ? weekday - 1 : mondayOffset
        let start = calendar.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
        let filtered = allEntries.filter(matchesWeekFilters)

        return (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: index, to: start) ?? start
            let seconds = filtered
                .filter { calendar.isDate(Date(milliseconds: $0.startedAt), inSameDayAs: date) }
                .reduce(0) { $0 + duration($1, now: now) }
            return MacWeekDay(date: date, seconds: seconds)
        }
    }

    private func matchesWeekFilters(_ entry: TimeEntry) -> Bool {
        if weekFolderFilter == "inbox", entry.folderId != nil { return false }
        if weekFolderFilter != "all", weekFolderFilter != "inbox" {
            guard let folderId = entry.folderId, folderSubtree(weekFolderFilter).contains(folderId) else { return false }
        }
        if weekLabelFilter != "all", !effectiveLabelIds(for: entry).contains(weekLabelFilter) { return false }
        return true
    }

    private func folderSubtree(_ root: DocumentID) -> Set<DocumentID> {
        var result: Set<DocumentID> = []
        var queue = [root]
        while let current = queue.popLast() {
            guard result.insert(current).inserted else { continue }
            queue.append(contentsOf: store.folders.filter { $0.parentFolderId == current }.map(\.id))
        }
        return result
    }

    private func effectiveLabelIds(for entry: TimeEntry) -> Set<DocumentID> {
        var ids = Set(entry.manualLabelIds)
        var folderId = entry.folderId
        var visited: Set<DocumentID> = []
        while let current = folderId, visited.insert(current).inserted, let folder = store.folder(for: current) {
            ids.formUnion(folder.defaultLabelIds)
            folderId = folder.parentFolderId
        }
        return ids
    }

    private func breakdownByFolder(entries: [TimeEntry], now: Date) -> [MacBreakdownItem] {
        var totals: [DocumentID: Int] = [:]
        for entry in entries { totals[entry.folderId ?? "inbox", default: 0] += duration(entry, now: now) }
        return totals.compactMap { id, seconds in
            if id == "inbox" { return MacBreakdownItem(id: id, name: "Inbox", color: TempoTheme.clay, seconds: seconds) }
            guard let folder = store.folder(for: id) else { return nil }
            return MacBreakdownItem(
                id: id,
                name: folder.name,
                color: folder.color.map(Color.init(hex:)) ?? TempoTheme.gold,
                seconds: seconds
            )
        }.sorted { $0.seconds > $1.seconds }
    }

    private func breakdownByLabel(entries: [TimeEntry], now: Date) -> [MacBreakdownItem] {
        var totals: [DocumentID: Int] = [:]
        for entry in entries {
            for id in effectiveLabelIds(for: entry) { totals[id, default: 0] += duration(entry, now: now) }
        }
        return totals.compactMap { id, seconds in
            guard let label = store.label(for: id) else { return nil }
            return MacBreakdownItem(id: id, name: label.name, color: TimeColorToken.label(label.color), seconds: seconds)
        }.sorted { $0.seconds > $1.seconds }
    }

    private var weekFolderName: String {
        if weekFolderFilter == "all" { return "Folders" }
        if weekFolderFilter == "inbox" { return "Inbox" }
        return store.folder(for: weekFolderFilter)?.name ?? "Folders"
    }

    private var weekLabelName: String {
        weekLabelFilter == "all" ? "Labels" : (store.label(for: weekLabelFilter)?.name ?? "Labels")
    }

    private func formatHours(_ seconds: Int) -> String {
        if seconds == 0 { return "0" }
        if seconds < 3_600 { return "\(Int((Double(seconds) / 60).rounded()))m" }
        let hours = Double(seconds) / 3_600
        if hours >= 10 { return "\(Int(hours.rounded()))h" }
        return String(format: "%.1fh", hours).replacingOccurrences(of: ".0h", with: "h")
    }
}

private struct MacWeekDay: Identifiable {
    let date: Date
    let seconds: Int
    var id: Date { date }
}

private struct MacTimerFilterPill: View {
    let icon: String
    let text: String
    let active: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
        }
        .font(.custom("Avenir Next", size: 12.8).weight(.semibold))
        .foregroundStyle(active ? TempoTheme.moss : TempoTheme.mutedInk)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(active ? TempoTheme.moss.opacity(0.10) : TempoTheme.surface, in: Capsule())
        .overlay {
            Capsule().stroke(active ? TempoTheme.moss : TempoTheme.line, lineWidth: 1)
        }
    }
}

private struct MacDashboardEntryRow: View {
    let entry: TimeEntry
    let folderName: String
    let duration: Int

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.status == .running ? TempoTheme.gold : TempoTheme.moss)
                .frame(width: 3, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(entry.title.isEmpty ? TempoTheme.sage : TempoTheme.ink)
                    .lineLimit(1)
                Text("\(Date(milliseconds: entry.startedAt).formatted(date: .omitted, time: .shortened)) · \(folderName)")
                    .font(.caption)
                    .foregroundStyle(TempoTheme.sage)
            }
            Spacer()
            Text(TimeText.duration(duration))
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(TempoTheme.ink)
        }
        .padding(.vertical, 11)
    }
}

private struct MacBreakdownItem: Identifiable {
    let id: DocumentID
    let name: String
    let color: Color
    let seconds: Int
}

private struct MacBreakdown: View {
    let title: String
    let items: [MacBreakdownItem]

    var body: some View {
        let maxSeconds = max(items.map(\.seconds).max() ?? 0, 1)
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(TempoTheme.sage)
            if items.isEmpty {
                Text("No tracked time yet.")
                    .font(.subheadline)
                    .foregroundStyle(TempoTheme.sage)
            } else {
                ForEach(items.prefix(5)) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Circle().fill(item.color).frame(width: 10, height: 10)
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TempoTheme.ink)
                                .lineLimit(1)
                            Spacer()
                            Text(TimeText.duration(item.seconds))
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(TempoTheme.sage)
                        }
                        GeometryReader { proxy in
                            Capsule()
                                .fill(TempoTheme.input)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(item.color)
                                        .frame(width: max(3, proxy.size.width * CGFloat(item.seconds) / CGFloat(maxSeconds)))
                                }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif

private struct TimerHeroBadge: View {
    let text: String
    let color: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .semibold))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(color, in: Capsule())
    }
}

struct PrimaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundStyle(TempoTheme.primaryForeground)
            .background(
                (configuration.isPressed ? TempoTheme.timerSurfaceSoft : TempoTheme.ink),
                in: Capsule()
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct SecondaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .foregroundStyle(Color.white)
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.2), in: Capsule())
    }
}

private struct LightCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 42, height: 42)
            .foregroundStyle(TempoTheme.ink)
            .background(Color.white.opacity(configuration.isPressed ? 0.7 : 0.94), in: Circle())
    }
}

private struct LightCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundStyle(TempoTheme.ink)
            .background(Color.white.opacity(configuration.isPressed ? 0.82 : 0.94), in: Capsule())
    }
}

private struct HeroGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 42, height: 42)
            .foregroundStyle(configuration.isPressed ? Color(hex: "#e8b4a0") : TempoTheme.softGreen)
            .background(Color.white.opacity(configuration.isPressed ? 0.1 : 0), in: Circle())
    }
}
