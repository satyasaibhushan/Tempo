import SwiftUI
import TempoCore

struct EntriesView: View {
    @Bindable var store: ConvexTimerStore
    @State private var searchText = ""
    @State private var folderFilter = "all"
    @State private var labelFilter = "all"
    @State private var range: EntryRange = .week
    @State private var folderFilterOpen = false
    @State private var labelFilterOpen = false
    @State private var folderSearch = ""
    @State private var labelSearch = ""
    @State private var creatingEntry = false
    @State private var editingEntry: TimeEntry?
    @State private var deletingEntry: TimeEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pageHeader
                    filters
                    #if os(macOS)
                    macEntriesList
                    #else
                    summary
                    entriesList
                    #endif
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
            .background(TempoTheme.canvas.ignoresSafeArea())
            .navigationTitle("Log")
            .timeNavigationChrome()
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creatingEntry = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(TempoTheme.accent)
                }
                #endif
            }
            .timeEntrySearchable(text: $searchText, prompt: "Search entries")
            .sheet(isPresented: $creatingEntry) {
                EntryEditorSheet(store: store, entry: nil)
            }
            .sheet(item: $editingEntry) { entry in
                EntryEditorSheet(store: store, entry: entry)
            }
            .sheet(item: $deletingEntry) { entry in
                #if os(iOS)
                EntryDeleteSheet(store: store, entry: entry)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                #else
                EntryDeleteSheet(store: store, entry: entry)
                #endif
            }
        }
    }

    @ViewBuilder
    private var pageHeader: some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: 20) {
            TerraPageHeader(
                kicker: "Archive / entries",
                title: "The time ledger.",
                subtitle: "Browse, filter, and edit your tracked time. Add manual entries for time you forgot to track."
            )
            Button {
                creatingEntry = true
            } label: {
                Label("Manual Entry", systemImage: "plus")
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
        }
        #else
        TerraPageHeader(
            kicker: "Record / entries",
            title: "See where time went.",
            subtitle: "Search, filter, continue, or correct any completed session."
        )
        #endif
    }

    @ViewBuilder
    private var filters: some View {
        #if os(macOS)
        VStack(spacing: 12) {
            TerraSearchField(text: $searchText, prompt: "Search entries")

            HStack(spacing: 4) {
                ForEach(EntryRange.allCases) { option in
                    Button {
                        range = option
                    } label: {
                        Text(option.title)
                            .font(.custom("Avenir Next", size: 14).weight(.semibold))
                            .foregroundStyle(range == option ? TempoTheme.ink : TempoTheme.sage)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                range == option ? TempoTheme.surface : Color.clear,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .shadow(
                                color: range == option ? TempoTheme.ink.opacity(0.12) : .clear,
                                radius: 2,
                                y: 1
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(TempoTheme.muted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("Entry date range")

            HStack(spacing: 8) {
                Button {
                    folderFilterOpen.toggle()
                } label: {
                    TerraFilterTrigger(
                        icon: folderFilter == "inbox" ? "tray" : "square.stack.3d.up",
                        text: selectedFolderName,
                        active: folderFilter != "all"
                    )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $folderFilterOpen, arrowEdge: .bottom) {
                    FolderFilterPopover(
                        folders: store.activeFolders,
                        selection: $folderFilter,
                        searchText: $folderSearch,
                        onSelect: { folderFilterOpen = false }
                    )
                }

                Button {
                    labelFilterOpen.toggle()
                } label: {
                    TerraFilterTrigger(
                        icon: "tag",
                        text: selectedLabelName,
                        active: labelFilter != "all"
                    )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $labelFilterOpen, arrowEdge: .bottom) {
                    LabelFilterPopover(
                        labels: store.labels,
                        selection: $labelFilter,
                        searchText: $labelSearch,
                        onSelect: { labelFilterOpen = false }
                    )
                }

                Spacer(minLength: 0)

                if hasActiveFilters {
                    Button {
                        folderFilter = "all"
                        labelFilter = "all"
                        searchText = ""
                    } label: {
                        Label("Clear", systemImage: "xmark")
                            .font(.custom("Avenir Next", size: 12).weight(.semibold))
                            .foregroundStyle(TempoTheme.clay)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .terraSurface(padding: 16)
        #else
        VStack(spacing: 12) {
            Picker("Range", selection: $range) {
                ForEach(EntryRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                Menu {
                    Picker("Folder", selection: $folderFilter) {
                        Text("All folders").tag("all")
                        Text("Inbox").tag("inbox")
                        ForEach(store.activeFolders) { folder in
                            Text(folder.name).tag(folder.id)
                        }
                    }
                } label: {
                    FilterPill(
                        icon: "folder",
                        text: selectedFolderName,
                        active: folderFilter != "all"
                    )
                }

                Menu {
                    Picker("Label", selection: $labelFilter) {
                        Text("All labels").tag("all")
                        ForEach(store.labels) { label in
                            Text(label.name).tag(label.id)
                        }
                    }
                } label: {
                    FilterPill(
                        icon: "tag",
                        text: selectedLabelName,
                        active: labelFilter != "all"
                    )
                }

                Spacer(minLength: 0)

                if folderFilter != "all" || labelFilter != "all" {
                    Button("Clear") {
                        folderFilter = "all"
                        labelFilter = "all"
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TempoTheme.clay)
                }
            }
        }
        .terraSurface(padding: 14)
        #endif
    }

    private var hasActiveFilters: Bool {
        folderFilter != "all" || labelFilter != "all" || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var selectedFolderName: String {
        if folderFilter == "all" { return "Folders" }
        if folderFilter == "inbox" { return "Inbox" }
        return store.folder(for: folderFilter)?.name ?? "Folders"
    }

    private var selectedLabelName: String {
        guard labelFilter != "all" else { return "Labels" }
        return store.label(for: labelFilter)?.name ?? "Labels"
    }

    private var summary: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("TRACKED")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(TempoTheme.sage)
                Text(TimeText.duration(filteredEntries.reduce(0) { $0 + ($1.durationSeconds ?? 0) }))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(TempoTheme.ink)
            }
            Spacer()
            Text("\(filteredEntries.count) sessions")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TempoTheme.mutedInk)
        }
        .terraSurface()
    }

    #if os(macOS)
    @ViewBuilder
    private var macEntriesList: some View {
        if groupedEntries.isEmpty {
            TerraEmptyState(
                icon: "book.closed",
                title: "No time entries",
                message: "Start tracking time or create a manual entry to get started."
            )
            .terraSurface(padding: 20)
        } else {
            VStack(spacing: 32) {
                ForEach(groupedEntries) { group in
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(group.title.uppercased())
                                .font(.custom("Avenir Next", size: 12).weight(.bold))
                                .tracking(1.2)
                            Spacer()
                            Text(TimeText.duration(group.totalSeconds))
                                .font(.custom("Avenir Next", size: 12).weight(.bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(TempoTheme.sage)
                        .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                                MacEntryRow(
                                    entry: entry,
                                    folder: store.folder(for: entry.folderId),
                                    labels: entry.manualLabelIds.compactMap(store.label),
                                    onContinue: { Task { _ = await store.continueEntry(entry) } },
                                    onEdit: { editingEntry = entry },
                                    onDelete: { deletingEntry = entry }
                                )
                                if index < group.entries.count - 1 {
                                    Rectangle()
                                        .fill(TempoTheme.line)
                                        .frame(height: 1)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .background(TempoTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: TempoTheme.ink.opacity(0.06), radius: 1, y: 1)
                    }
                }
            }
            .terraSurface(padding: 20)
        }
    }

    private var groupedEntries: [MacEntryDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) {
            calendar.startOfDay(for: Date(milliseconds: $0.startedAt))
        }
        return grouped.map { date, entries in
            let title: String
            if calendar.isDateInToday(date) {
                title = "Today"
            } else if calendar.isDateInYesterday(date) {
                title = "Yesterday"
            } else {
                title = date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
            }
            return MacEntryDayGroup(
                date: date,
                title: title,
                totalSeconds: entries.reduce(0) { $0 + ($1.durationSeconds ?? 0) },
                entries: entries.sorted { $0.startedAt > $1.startedAt }
            )
        }
        .sorted { $0.date > $1.date }
    }
    #endif

    @ViewBuilder
    private var entriesList: some View {
        if filteredEntries.isEmpty {
            TerraEmptyState(
                icon: "book.closed",
                title: "No matching entries",
                message: "Adjust the filters or add a manual session."
            )
            .terraSurface()
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filteredEntries) { entry in
                    EntryRow(
                        entry: entry,
                        folder: store.folder(for: entry.folderId),
                        labels: entry.manualLabelIds.compactMap(store.label),
                        onContinue: { Task { _ = await store.continueEntry(entry) } },
                        onEdit: { editingEntry = entry },
                        onDelete: { deletingEntry = entry }
                    )
                }
            }
        }
    }

    private var filteredEntries: [TimeEntry] {
        let calendar = Calendar.current
        let now = Date.now
        let startDate: Date? = switch range {
        case .all: nil
        case .today: calendar.startOfDay(for: now)
        case .week: calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
        case .month: calendar.date(byAdding: .month, value: -1, to: now)
        }

        return store.completedEntries.filter { entry in
            if let startDate, Date(milliseconds: entry.startedAt) < startDate { return false }
            if folderFilter == "inbox", entry.folderId != nil { return false }
            if folderFilter != "all", folderFilter != "inbox", entry.folderId != folderFilter { return false }
            if labelFilter != "all", !effectiveLabelIds(for: entry).contains(labelFilter) { return false }
            if !searchText.isEmpty {
                let haystack = "\(entry.title) \(entry.notes ?? "")".localizedLowercase
                if !haystack.contains(searchText.localizedLowercase) { return false }
            }
            return true
        }
    }

    private func effectiveLabelIds(for entry: TimeEntry) -> Set<DocumentID> {
        var ids = Set(entry.manualLabelIds)
        var folderId = entry.folderId
        var visited: Set<DocumentID> = []
        while let current = folderId, !visited.contains(current), let folder = store.folder(for: current) {
            visited.insert(current)
            ids.formUnion(folder.defaultLabelIds)
            folderId = folder.parentFolderId
        }
        return ids
    }
}

private enum EntryRange: String, CaseIterable, Equatable, Identifiable {
    case today
    case week
    case month
    case all

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

#if os(macOS)
private struct MacEntryDayGroup: Identifiable {
    let date: Date
    let title: String
    let totalSeconds: Int
    let entries: [TimeEntry]
    var id: Date { date }
}

private struct TerraFilterTrigger: View {
    let icon: String
    let text: String
    let active: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .opacity(0.75)
            Text(text)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .opacity(0.55)
        }
        .font(.custom("Avenir Next", size: 12.8).weight(.semibold))
        .foregroundStyle(active ? TempoTheme.moss : TempoTheme.mutedInk)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(
            active ? TempoTheme.moss.opacity(0.10) : TempoTheme.surface,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(active ? TempoTheme.moss : TempoTheme.line, lineWidth: 1)
        }
    }
}

private struct FolderFilterPopover: View {
    let folders: [Folder]
    @Binding var selection: String
    @Binding var searchText: String
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TerraSearchField(text: $searchText, prompt: "Find a folder…")
                .padding(10)

            Rectangle().fill(TempoTheme.line).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCOPE")
                        .font(.custom("Avenir Next", size: 10).weight(.bold))
                        .tracking(1)
                        .foregroundStyle(TempoTheme.sage)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)

                    FilterOptionRow(
                        icon: "square.stack.3d.up",
                        title: "All folders",
                        selected: selection == "all"
                    ) { choose("all") }
                    FilterOptionRow(
                        icon: "tray",
                        title: "Inbox",
                        tint: TempoTheme.clay,
                        selected: selection == "inbox"
                    ) { choose("inbox") }

                    if !filteredFolders.isEmpty {
                        Rectangle().fill(TempoTheme.line).frame(height: 1).padding(.vertical, 4)
                        Text("FOLDERS")
                            .font(.custom("Avenir Next", size: 10).weight(.bold))
                            .tracking(1)
                            .foregroundStyle(TempoTheme.sage)
                            .padding(.horizontal, 10)
                        ForEach(filteredFolders) { folder in
                            FilterOptionRow(
                                dotColor: TimeColorToken.folder(folder.color),
                                icon: "folder",
                                title: folder.name,
                                selected: selection == folder.id
                            ) { choose(folder.id) }
                        }
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 270)
        }
        .frame(width: 288)
        .background(TempoTheme.popover)
    }

    private var filteredFolders: [Folder] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return folders }
        return folders.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func choose(_ value: String) {
        selection = value
        searchText = ""
        onSelect()
    }
}

private struct LabelFilterPopover: View {
    let labels: [TempoCore.Label]
    @Binding var selection: String
    @Binding var searchText: String
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TerraSearchField(text: $searchText, prompt: "Find a label…")
                .padding(10)

            Rectangle().fill(TempoTheme.line).frame(height: 1)

            ScrollView {
                VStack(spacing: 4) {
                    FilterOptionRow(
                        icon: "tag",
                        title: "All labels",
                        selected: selection == "all"
                    ) { choose("all") }

                    ForEach(filteredLabels) { label in
                        FilterOptionRow(
                            dotColor: TimeColorToken.label(label.color),
                            title: label.name,
                            selected: selection == label.id
                        ) { choose(label.id) }
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 270)
        }
        .frame(width: 256)
        .background(TempoTheme.popover)
    }

    private var filteredLabels: [TempoCore.Label] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return labels }
        return labels.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func choose(_ value: String) {
        selection = value
        searchText = ""
        onSelect()
    }
}

private struct FilterOptionRow: View {
    var dotColor: Color?
    var icon: String?
    let title: String
    var tint = TempoTheme.sage
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let dotColor {
                    Circle().fill(dotColor).frame(width: 10, height: 10)
                }
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(tint)
                        .frame(width: 15)
                }
                Text(title)
                    .font(.custom("Avenir Next", size: 13))
                    .foregroundStyle(TempoTheme.ink)
                    .lineLimit(1)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(TempoTheme.moss)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(hovering ? TempoTheme.muted : Color.clear, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct MacEntryRow: View {
    let entry: TimeEntry
    let folder: Folder?
    let labels: [TempoCore.Label]
    let onContinue: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(TimeColorToken.folder(folder?.color))
                .frame(width: 3)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.custom("Avenir Next", size: 14).weight(entry.title.isEmpty ? .medium : .semibold))
                    .italic(entry.title.isEmpty)
                    .foregroundStyle(entry.title.isEmpty ? TempoTheme.sage : TempoTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text(timeRange)
                        .monospacedDigit()
                    Text(folder?.name ?? "Inbox")
                        .fontWeight(.medium)
                    ForEach(labels) { label in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(TimeColorToken.label(label.color))
                                .frame(width: 6, height: 6)
                            Text(label.name)
                        }
                        .font(.custom("Avenir Next", size: 11).weight(.medium))
                        .foregroundStyle(TempoTheme.mutedInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(TempoTheme.muted, in: Capsule())
                    }
                }
                .font(.custom("Avenir Next", size: 12))
                .foregroundStyle(TempoTheme.sage)
            }

            Spacer(minLength: 12)

            Text(TimeText.duration(entry.durationSeconds ?? 0))
                .font(.custom("Avenir Next", size: 14).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(TempoTheme.ink)

            HStack(spacing: 2) {
                MacEntryAction(icon: "play.fill", help: "Continue as a new timer", action: onContinue)
                MacEntryAction(icon: "pencil", help: "Edit entry", action: onEdit)
                MacEntryAction(icon: "trash", help: "Delete entry", tint: TempoTheme.clay, action: onDelete)
            }
            .frame(width: 92, alignment: .trailing)
            .opacity(hovering ? 1 : 0)
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .frame(minHeight: 58)
        .background(hovering ? TempoTheme.muted.opacity(0.5) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    private var timeRange: String {
        let start = Date(milliseconds: entry.startedAt).formatted(date: .omitted, time: .shortened)
        guard let endedAt = entry.endedAt else { return "\(start) – now" }
        let end = Date(milliseconds: endedAt).formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }
}

private struct MacEntryAction: View {
    let icon: String
    let help: String
    var tint = TempoTheme.sage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
#endif

private struct FilterPill: View {
    let icon: String
    let text: String
    let active: Bool

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .foregroundStyle(active ? Color.white : TempoTheme.mutedInk)
            .background(active ? TempoTheme.moss : TempoTheme.muted, in: Capsule())
    }
}

private struct EntryRow: View {
    let entry: TimeEntry
    let folder: Folder?
    let labels: [TempoCore.Label]
    let onContinue: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title.isEmpty ? "Untitled session" : entry.title)
                        .font(.headline)
                        .italic(entry.title.isEmpty)
                        .foregroundStyle(TempoTheme.ink)
                    Text(Date(milliseconds: entry.startedAt).formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(TempoTheme.sage)
                }
                Spacer()
                Text(TimeText.compactDuration(entry.durationSeconds ?? 0))
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(TempoTheme.ink)
            }

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(TempoTheme.mutedInk)
                    .lineLimit(2)
            }

            HStack(spacing: 7) {
                TerraBadge(text: folder?.name ?? "Inbox", color: TempoTheme.gold, icon: "folder.fill")
                ForEach(labels.prefix(2)) { label in
                    TerraBadge(text: label.name, color: TimeColorToken.label(label.color))
                }
                Spacer()
                Menu {
                    Button("Continue", systemImage: "play.fill", action: onContinue)
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(TempoTheme.mutedInk)
                }
            }
        }
        .terraSurface()
    }
}

private struct EntryDeleteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: ConvexTimerStore
    let entry: TimeEntry
    @State private var deleting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(TempoTheme.destructive)
                Text("Delete time entry")
                    .font(.headline)
                    .foregroundStyle(TempoTheme.destructive)
            }

            Text("This entry will be permanently removed. This action cannot be undone.")
                .font(.subheadline)
                .foregroundStyle(TempoTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title.isEmpty ? "Untitled" : entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TempoTheme.ink)
                        .lineLimit(1)
                    Text(Date(milliseconds: entry.startedAt).formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(TempoTheme.sage)
                }
                Spacer()
                Text(TimeText.duration(entry.durationSeconds ?? 0))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(TempoTheme.sage)
            }
            .padding(16)
            .background(TempoTheme.muted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TempoTheme.line, lineWidth: 1)
            }

            HStack(spacing: 12) {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                Button(role: .destructive) {
                    removeEntry()
                } label: {
                    if deleting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Delete entry")
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(TempoTheme.destructive)
                .disabled(deleting || store.isMutating)
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .background(TempoTheme.popover)
    }

    private func removeEntry() {
        deleting = true
        Task {
            let success = await store.deleteEntry(entry)
            deleting = false
            if success { dismiss() }
        }
    }
}

private struct EntryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: ConvexTimerStore
    let entry: TimeEntry?

    @State private var title: String
    @State private var notes: String
    @State private var folderId: DocumentID?
    @State private var labelIds: Set<DocumentID>
    @State private var start: Date
    @State private var end: Date

    init(store: ConvexTimerStore, entry: TimeEntry?) {
        self.store = store
        self.entry = entry
        _title = State(initialValue: entry?.title ?? "")
        _notes = State(initialValue: entry?.notes ?? "")
        _folderId = State(initialValue: entry?.folderId)
        _labelIds = State(initialValue: Set(entry?.manualLabelIds ?? []))
        _start = State(initialValue: entry.map { Date(milliseconds: $0.startedAt) } ?? Date.now.addingTimeInterval(-3_600))
        _end = State(initialValue: entry?.endedAt.map(Date.init(milliseconds:)) ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("What did you work on?", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Time") {
                    DatePicker("Started", selection: $start)
                    DatePicker("Ended", selection: $end)
                    if end <= start {
                        Text("End time must be after start time.")
                            .font(.caption)
                            .foregroundStyle(TempoTheme.destructive)
                    }
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
            .navigationTitle(entry == nil ? "Add Entry" : "Edit Entry")
            .timeInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(end <= start || store.isMutating)
                }
            }
        }
    }

    private func save() {
        Task {
            let success: Bool
            if let entry {
                success = await store.editEntry(
                    entry,
                    title: title,
                    notes: notes,
                    folderId: folderId,
                    labelIds: labelIds,
                    start: start,
                    end: end
                )
            } else {
                success = await store.createManualEntry(
                    title: title,
                    notes: notes,
                    folderId: folderId,
                    labelIds: labelIds,
                    start: start,
                    end: end
                )
            }
            if success { dismiss() }
        }
    }
}
