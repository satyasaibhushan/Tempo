import SwiftUI
import TempoCore

struct FoldersView: View {
    @Bindable var store: ConvexTimerStore
    @State private var showingArchived = false
    #if os(macOS)
    @State private var macSort = MacFolderSort.manual
    @State private var expandedFolderIds: Set<DocumentID> = []
    #endif
    @State private var editorTarget: FolderEditorTarget?
    @State private var deletingFolder: Folder?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pageHeader

                    #if os(macOS)
                    macFolderTree
                    #else
                    archivedToggle

                    if visibleNodes.isEmpty {
                        TerraEmptyState(
                            icon: "folder",
                            title: "No folders yet",
                            message: "Inbox is always available. Add a folder when your time needs more structure."
                        )
                        .terraSurface()
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(visibleNodes) { node in
                                FolderRow(
                                    node: node,
                                    labels: node.folder.defaultLabelIds.compactMap(store.label),
                                    onEdit: { editorTarget = FolderEditorTarget(folder: node.folder) },
                                    onAddChild: {
                                        editorTarget = FolderEditorTarget(parentFolderId: node.folder.id)
                                    },
                                    onArchive: {
                                        Task {
                                            _ = await store.setFolderArchived(
                                                node.folder,
                                                archived: !node.folder.archived
                                            )
                                        }
                                    },
                                    onDelete: { deletingFolder = node.folder }
                                )
                            }
                        }
                    }
                    #endif
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
            .background(TempoTheme.canvas.ignoresSafeArea())
            .navigationTitle("Folders")
            .timeNavigationChrome()
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editorTarget = FolderEditorTarget()
                    } label: {
                        Label("New Folder", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(TempoTheme.accent)
                }
                #endif
            }
            .sheet(item: $editorTarget) { target in
                FolderEditorSheet(store: store, target: target)
            }
            .confirmationDialog(
                "Delete this folder?",
                isPresented: Binding(
                    get: { deletingFolder != nil },
                    set: { if !$0 { deletingFolder = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Folder", role: .destructive) {
                    guard let deletingFolder else { return }
                    Task { _ = await store.deleteFolder(deletingFolder) }
                    self.deletingFolder = nil
                }
            } message: {
                Text("Entries move to Inbox and direct child folders move to the root.")
            }
        }
    }

    @ViewBuilder
    private var pageHeader: some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: 20) {
            TerraPageHeader(
                kicker: "Structure / folders",
                title: "Give time a place.",
                subtitle: "One recursive hierarchy. Inbox at the root for uncategorized entries. Folders can have default labels that cascade to children."
            )
            Button {
                editorTarget = FolderEditorTarget()
            } label: {
                Label("New Folder", systemImage: "plus")
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
        }
        #else
        TerraPageHeader(
            kicker: "Structure / folders",
            title: "Give time a place.",
            subtitle: "Folders form one hierarchy. Default labels cascade through every child."
        )
        #endif
    }

    private var archivedToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(store.activeFolders.count) active folders")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TempoTheme.ink)
                Text("Inbox remains at the root")
                    .font(.caption)
                    .foregroundStyle(TempoTheme.sage)
            }
            Spacer()
            Toggle("Archived", isOn: $showingArchived)
                .labelsHidden()
                .tint(TempoTheme.moss)
            Text("Archived")
                .font(.caption.weight(.semibold))
                .foregroundStyle(TempoTheme.mutedInk)
        }
        .terraSurface(padding: 14)
    }

    #if os(macOS)
    private var macFolderTree: some View {
        VStack(spacing: 4) {
            HStack {
                Text("FOLDERS")
                    .font(.custom("Avenir Next", size: 11).weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(TempoTheme.sage)
                Spacer()
                Menu {
                    ForEach(MacFolderSort.allCases) { option in
                        Button { macSort = option } label: {
                            Label(option.title, systemImage: macSort == option ? "checkmark" : "line.3.horizontal.decrease")
                        }
                    }
                    Divider()
                    Button {
                        showingArchived.toggle()
                    } label: {
                        Label(showingArchived ? "Hide archived" : "Show archived", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TempoTheme.sage)
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button {
                    editorTarget = FolderEditorTarget()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TempoTheme.sage)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("New folder")
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            HStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TempoTheme.sage)
                    .frame(width: 24, height: 24)
                    .background(TempoTheme.muted, in: RoundedRectangle(cornerRadius: 8))
                Text("Inbox")
                    .font(.custom("Avenir Next", size: 14).weight(.medium))
                    .foregroundStyle(TempoTheme.ink)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 44)

            if macVisibleNodes.isEmpty {
                TerraEmptyState(
                    icon: "folder",
                    title: "No folders yet",
                    message: "Create a folder to organize your time entries."
                )
            } else {
                ForEach(macVisibleNodes) { node in
                    MacFolderRow(
                        node: node,
                        expanded: expandedFolderIds.contains(node.folder.id),
                        hasChildren: hasChildren(node.folder.id),
                        onToggle: {
                            if expandedFolderIds.contains(node.folder.id) {
                                expandedFolderIds.remove(node.folder.id)
                            } else {
                                expandedFolderIds.insert(node.folder.id)
                            }
                        },
                        onEdit: { editorTarget = FolderEditorTarget(folder: node.folder) },
                        onAddChild: { editorTarget = FolderEditorTarget(parentFolderId: node.folder.id) },
                        onArchive: {
                            Task {
                                _ = await store.setFolderArchived(node.folder, archived: !node.folder.archived)
                            }
                        },
                        onDelete: { deletingFolder = node.folder }
                    )
                }
            }
        }
        .terraSurface(padding: 20)
    }

    private var macVisibleNodes: [FolderNode] {
        let folders = store.folders.filter { showingArchived || !$0.archived }
        let ids = Set(folders.map(\.id))
        let grouped = Dictionary(grouping: folders) { folder -> DocumentID? in
            guard let parent = folder.parentFolderId, ids.contains(parent) else { return nil }
            return parent
        }
        var result: [FolderNode] = []

        func append(parent: DocumentID?, depth: Int) {
            for folder in (grouped[parent] ?? []).sorted(by: macFolderSort) {
                result.append(FolderNode(folder: folder, depth: depth))
                if expandedFolderIds.contains(folder.id) {
                    append(parent: folder.id, depth: depth + 1)
                }
            }
        }

        append(parent: nil, depth: 0)
        return result
    }

    private func macFolderSort(_ lhs: Folder, _ rhs: Folder) -> Bool {
        switch macSort {
        case .manual:
            if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
        case .created:
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        case .updated:
            if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private func hasChildren(_ id: DocumentID) -> Bool {
        store.folders.contains { $0.parentFolderId == id && (showingArchived || !$0.archived) }
    }
    #endif

    private var visibleNodes: [FolderNode] {
        let folders = store.folders.filter { showingArchived || !$0.archived }
        let ids = Set(folders.map(\.id))
        let grouped = Dictionary(grouping: folders) { folder -> DocumentID? in
            guard let parent = folder.parentFolderId, ids.contains(parent) else { return nil }
            return parent
        }
        var result: [FolderNode] = []

        func append(parent: DocumentID?, depth: Int) {
            for folder in (grouped[parent] ?? []).sorted(by: folderSort) {
                result.append(FolderNode(folder: folder, depth: depth))
                append(parent: folder.id, depth: depth + 1)
            }
        }

        append(parent: nil, depth: 0)
        return result
    }

    private func folderSort(_ lhs: Folder, _ rhs: Folder) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return lhs.sortOrder < rhs.sortOrder
    }
}

private struct FolderNode: Identifiable {
    let folder: Folder
    let depth: Int
    var id: DocumentID { folder.id }
}

#if os(macOS)
private enum MacFolderSort: String, CaseIterable, Identifiable {
    case manual
    case created
    case updated

    var id: Self { self }
    var title: String {
        switch self {
        case .manual: "Manual order"
        case .created: "Date created"
        case .updated: "Last updated"
        }
    }
}

private struct MacFolderRow: View {
    let node: FolderNode
    let expanded: Bool
    let hasChildren: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onAddChild: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TempoTheme.sage)
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .disabled(!hasChildren)
            .opacity(hasChildren ? 1 : 0.25)

            Circle()
                .fill(TimeColorToken.folder(node.folder.color))
                .frame(width: 10, height: 10)

            Text(node.folder.name)
                .font(.custom("Avenir Next", size: 14).weight(.medium))
                .foregroundStyle(TempoTheme.ink)
                .lineLimit(1)

            Spacer()

            if node.folder.archived {
                Text("ARCHIVED")
                    .font(.custom("Avenir Next", size: 9).weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(TempoTheme.sage)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(TempoTheme.muted, in: RoundedRectangle(cornerRadius: 6))
            }

            Menu {
                Button("Edit", systemImage: "pencil", action: onEdit)
                Button("New Subfolder", systemImage: "folder.badge.plus", action: onAddChild)
                Button(
                    node.folder.archived ? "Unarchive" : "Archive",
                    systemImage: node.folder.archived ? "arrow.uturn.backward" : "archivebox",
                    action: onArchive
                )
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TempoTheme.sage)
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .opacity(hovering ? 1 : 0)
        }
        .padding(.leading, CGFloat(node.depth) * 20 + 8)
        .padding(.trailing, 8)
        .frame(height: 40)
        .background(hovering ? TempoTheme.muted.opacity(0.55) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .opacity(node.folder.archived ? 0.66 : 1)
    }
}
#endif

private struct FolderRow: View {
    let node: FolderNode
    let labels: [TempoCore.Label]
    let onEdit: () -> Void
    let onAddChild: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if node.depth > 0 {
                Color.clear.frame(width: CGFloat(min(node.depth, 3)) * 16)
            }
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(node.folder.color.map(Color.init(hex:)) ?? TempoTheme.moss)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: node.folder.archived ? "archivebox.fill" : "folder.fill")
                        .foregroundStyle(.white.opacity(0.92))
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(node.folder.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TempoTheme.ink)
                if labels.isEmpty {
                    Text(node.folder.archived ? "Archived" : "No default labels")
                        .font(.caption)
                        .foregroundStyle(TempoTheme.sage)
                } else {
                    HStack(spacing: 5) {
                        ForEach(labels.prefix(2)) { label in
                            Text(label.name)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(TempoTheme.mutedInk)
                        }
                        if labels.count > 2 {
                            Text("+\(labels.count - 2)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(TempoTheme.sage)
                        }
                    }
                }
            }
            Spacer()
            Menu {
                Button("Edit", systemImage: "pencil", action: onEdit)
                Button("New Subfolder", systemImage: "folder.badge.plus", action: onAddChild)
                Button(
                    node.folder.archived ? "Unarchive" : "Archive",
                    systemImage: node.folder.archived ? "arrow.uturn.backward" : "archivebox",
                    action: onArchive
                )
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(TempoTheme.mutedInk)
                    .frame(width: 34, height: 34)
            }
        }
        .terraSurface(padding: 14)
        .opacity(node.folder.archived ? 0.66 : 1)
    }
}

private struct FolderEditorTarget: Identifiable {
    let id = UUID()
    var folder: Folder?
    var parentFolderId: DocumentID?

    init(folder: Folder? = nil, parentFolderId: DocumentID? = nil) {
        self.folder = folder
        self.parentFolderId = folder?.parentFolderId ?? parentFolderId
    }
}

private struct FolderEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: ConvexTimerStore
    let target: FolderEditorTarget

    @State private var name: String
    @State private var color: String
    @State private var parentFolderId: DocumentID?
    @State private var defaultLabelIds: Set<DocumentID>

    private let colors = ["#5a7d5a", "#c4704f", "#d8a25a", "#7d9184", "#466f8a", "#8b6f91"]

    init(store: ConvexTimerStore, target: FolderEditorTarget) {
        self.store = store
        self.target = target
        _name = State(initialValue: target.folder?.name ?? "")
        _color = State(initialValue: target.folder?.color ?? "#5a7d5a")
        _parentFolderId = State(initialValue: target.parentFolderId)
        _defaultLabelIds = State(initialValue: Set(target.folder?.defaultLabelIds ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder") {
                    TextField("Folder name", text: $name)
                    FolderPicker(
                        folders: store.activeFolders,
                        selection: $parentFolderId,
                        excludedFolderId: target.folder?.id
                    )
                }

                if target.folder == nil {
                    Section("Color") {
                        HStack(spacing: 16) {
                            ForEach(colors, id: \.self) { option in
                                Button {
                                    color = option
                                } label: {
                                    Circle()
                                        .fill(Color(hex: option))
                                        .frame(width: 30, height: 30)
                                        .overlay {
                                            if color == option {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    LabelSelectionList(labels: store.labels, selection: $defaultLabelIds)
                } header: {
                    Text("Default Labels")
                } footer: {
                    Text("These labels cascade to entries in this folder and its children.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(TempoTheme.canvas)
            .navigationTitle(target.folder == nil ? "New Folder" : "Edit Folder")
            .timeInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isMutating)
                }
            }
        }
    }

    private func save() {
        Task {
            let success: Bool
            if let folder = target.folder {
                success = await store.updateFolder(
                    folder,
                    name: name,
                    parentFolderId: parentFolderId,
                    defaultLabelIds: defaultLabelIds
                )
            } else {
                success = await store.createFolder(
                    name: name,
                    color: color,
                    parentFolderId: parentFolderId,
                    defaultLabelIds: defaultLabelIds
                )
            }
            if success { dismiss() }
        }
    }
}
