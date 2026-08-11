import SwiftUI
import TempoCore

struct LabelsView: View {
    @Bindable var store: ConvexTimerStore
    @State private var editingLabel: TempoCore.Label?
    @State private var creatingLabel = false
    @State private var deletingLabel: TempoCore.Label?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pageHeader

                    if store.labels.isEmpty {
                        TerraEmptyState(
                            icon: "tag",
                            title: "No labels yet",
                            message: "Create a signal you can reuse across folders and entries."
                        )
                        .terraSurface()
                    } else {
                        #if os(macOS)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                            spacing: 12
                        ) {
                            ForEach(store.labels.sorted(by: labelSort)) { label in
                                MacLabelTile(
                                    label: label,
                                    onEdit: { editingLabel = label },
                                    onDelete: { deletingLabel = label }
                                )
                            }
                        }
                        .terraSurface(padding: 20)
                        #else
                        LazyVStack(spacing: 10) {
                            ForEach(store.labels.sorted(by: labelSort)) { label in
                                LabelRow(
                                    label: label,
                                    usageCount: usageCount(for: label),
                                    onEdit: { editingLabel = label },
                                    onDelete: { deletingLabel = label }
                                )
                            }
                        }
                        #endif
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
            .background(TempoTheme.canvas.ignoresSafeArea())
            .navigationTitle("Labels")
            .timeNavigationChrome()
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creatingLabel = true
                    } label: {
                        Label("New Label", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(TempoTheme.accent)
                }
                #endif
            }
            .sheet(isPresented: $creatingLabel) {
                LabelEditorSheet(store: store, label: nil)
            }
            .sheet(item: $editingLabel) { label in
                LabelEditorSheet(store: store, label: label)
            }
            .confirmationDialog(
                "Delete this label?",
                isPresented: Binding(
                    get: { deletingLabel != nil },
                    set: { if !$0 { deletingLabel = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Label", role: .destructive) {
                    guard let deletingLabel else { return }
                    Task { _ = await store.deleteLabel(deletingLabel) }
                    self.deletingLabel = nil
                }
            } message: {
                Text("It will also be removed from folders and entries.")
            }
        }
    }

    @ViewBuilder
    private var pageHeader: some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: 20) {
            TerraPageHeader(
                kicker: "Signal / labels",
                title: "Mark what matters.",
                subtitle: "Reusable labels that can be set as folder defaults or added directly to entries. Folder defaults cascade through the hierarchy."
            )
            Button {
                creatingLabel = true
            } label: {
                Label("New Label", systemImage: "plus")
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
        }
        #else
        TerraPageHeader(
            kicker: "Signal / labels",
            title: "Mark what matters.",
            subtitle: "Reusable labels can be added directly or inherited from a folder."
        )
        #endif
    }

    private func labelSort(_ lhs: TempoCore.Label, _ rhs: TempoCore.Label) -> Bool {
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private func usageCount(for label: TempoCore.Label) -> Int {
        let entryCount = store.completedEntries.count { $0.manualLabelIds.contains(label.id) }
        let folderCount = store.folders.count { $0.defaultLabelIds.contains(label.id) }
        return entryCount + folderCount
    }
}

#if os(macOS)
private struct MacLabelTile: View {
    let label: TempoCore.Label
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(TimeColorToken.label(label.color))
                .frame(width: 12, height: 12)
            Text(label.name)
                .font(.custom("Avenir Next", size: 14).weight(.medium))
                .foregroundStyle(TempoTheme.ink)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 2) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TempoTheme.sage)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Edit \(label.name)")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(TempoTheme.clay)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Delete \(label.name)")
            }
            .opacity(hovering ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(TempoTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(hovering ? TempoTheme.moss.opacity(0.4) : TempoTheme.line, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}
#endif

private struct LabelRow: View {
    let label: TempoCore.Label
    let usageCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Circle()
                .fill(TimeColorToken.label(label.color))
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.92))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(label.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TempoTheme.ink)
                Text(usageCount == 1 ? "Used once" : "Used \(usageCount) times")
                    .font(.caption)
                    .foregroundStyle(TempoTheme.sage)
            }
            Spacer()
            Menu {
                Button("Edit", systemImage: "pencil", action: onEdit)
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(TempoTheme.mutedInk)
                    .frame(width: 34, height: 34)
            }
        }
        .terraSurface(padding: 14)
    }
}

private struct LabelEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: ConvexTimerStore
    let label: TempoCore.Label?

    @State private var name: String
    @State private var color: String

    private let colors = ["#5a7d5a", "#c4704f", "#d8a25a", "#7d9184", "#466f8a", "#8b6f91", "#ad6572", "#4f8078"]

    init(store: ConvexTimerStore, label: TempoCore.Label?) {
        self.store = store
        self.label = label
        _name = State(initialValue: label?.name ?? "")
        _color = State(initialValue: label?.color ?? "#5a7d5a")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("Label name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 18) {
                        ForEach(colors, id: \.self) { option in
                            Button {
                                color = option
                            } label: {
                                Circle()
                                    .fill(Color(hex: option))
                                    .frame(width: 42, height: 42)
                                    .overlay {
                                        if color == option {
                                            Image(systemName: "checkmark")
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Preview") {
                    TerraBadge(text: name.isEmpty ? "Label" : name, color: Color(hex: color), icon: "tag.fill")
                }
            }
            .scrollContentBackground(.hidden)
            .background(TempoTheme.canvas)
            .navigationTitle(label == nil ? "New Label" : "Edit Label")
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
            if let label {
                success = await store.updateLabel(label, name: name, color: color)
            } else {
                success = await store.createLabel(name: name, color: color)
            }
            if success { dismiss() }
        }
    }
}
