import SwiftUI
import TempoCore

struct TerraPageHeader: View {
    let kicker: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(kicker.uppercased())
                .font(.custom("Avenir Next", size: 11).weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(TempoTheme.sage)
            Text(title)
                .font(.custom("Avenir Next", size: 24).weight(.bold))
                .tracking(-0.45)
                .foregroundStyle(TempoTheme.ink)
            Text(subtitle)
                .font(.custom("Avenir Next", size: 13.5))
                .foregroundStyle(TempoTheme.sage)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TerraSurfaceModifier: ViewModifier {
    var padding: CGFloat = 18

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .padding(padding)
            .background(TempoTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: TempoTheme.ink.opacity(0.06), radius: 1, y: 1)
        #else
        content
            .padding(padding)
            .background(TempoTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(TempoTheme.line.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: TempoTheme.ink.opacity(0.06), radius: 2, y: 1)
        #endif
    }
}

extension View {
    func terraSurface(padding: CGFloat = 18) -> some View {
        modifier(TerraSurfaceModifier(padding: padding))
    }

    @ViewBuilder
    func timeNavigationChrome() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TempoTheme.canvas, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func timeInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func timeSentenceInput() -> some View {
        #if os(iOS)
        self
            .textInputAutocapitalization(.sentences)
            .submitLabel(.go)
        #else
        self
        #endif
    }

    @ViewBuilder
    func timeEntrySearchable(text: Binding<String>, prompt: String) -> some View {
        #if os(iOS)
        self.searchable(text: text, prompt: prompt)
        #else
        self
        #endif
    }
}

struct TerraSearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TempoTheme.sage)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(TempoTheme.ink)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TempoTheme.sage)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(TempoTheme.muted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TempoTheme.line.opacity(0.5), lineWidth: 1)
        }
    }
}

struct TerraBadge: View {
    let text: String
    var color = TempoTheme.gold
    var icon: String?

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .lineLimit(1)
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(TempoTheme.ink)
        .background(color.opacity(0.88), in: Capsule())
    }
}

struct TerraEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
            Text(title)
                .font(.headline)
                .foregroundStyle(TempoTheme.ink)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(TempoTheme.mutedInk)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }
}

struct FolderPicker: View {
    let folders: [Folder]
    @Binding var selection: DocumentID?
    var excludedFolderId: DocumentID?

    var body: some View {
        Picker("Folder", selection: $selection) {
            Label("Inbox", systemImage: "tray").tag(DocumentID?.none)
            ForEach(folders.filter { $0.id != excludedFolderId }) { folder in
                Text(folder.name).tag(DocumentID?.some(folder.id))
            }
        }
    }
}

struct LabelSelectionList: View {
    let labels: [TempoCore.Label]
    @Binding var selection: Set<DocumentID>

    var body: some View {
        if labels.isEmpty {
            Text("No labels yet")
                .foregroundStyle(TempoTheme.mutedInk)
        } else {
            ForEach(labels) { label in
                Button {
                    if selection.contains(label.id) {
                        selection.remove(label.id)
                    } else {
                        selection.insert(label.id)
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(TimeColorToken.label(label.color))
                            .frame(width: 10, height: 10)
                        Text(label.name)
                            .foregroundStyle(TempoTheme.ink)
                        Spacer()
                        if selection.contains(label.id) {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(TempoTheme.moss)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

enum TimeText {
    static func duration(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = seconds % 3_600 / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    static func compactDuration(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = seconds % 3_600 / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(max(seconds, 0))s"
    }
}

extension Date {
    init(milliseconds: Int64) {
        self.init(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000)
    }

    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1_000).rounded(.down))
    }
}

enum TimeColorToken {
    private static let folderColors: [String: String] = [
        "amber": "#E6A23C",
        "coral": "#F97360",
        "emerald": "#34D399",
        "sky": "#38BDF8",
        "violet": "#A78BFA",
        "lime": "#A3E635",
    ]

    private static let labelColors: [String: String] = [
        "gold": "#F5BF58",
        "rose": "#FB7185",
        "mint": "#6EE7B7",
        "ocean": "#60A5FA",
        "orchid": "#C084FC",
        "moss": "#84CC16",
    ]

    static func folder(_ value: String?) -> Color {
        Color(hex: resolved(value, in: folderColors, fallback: "#E6A23C"))
    }

    static func label(_ value: String) -> Color {
        Color(hex: resolved(value, in: labelColors, fallback: "#F5BF58"))
    }

    private static func resolved(
        _ value: String?,
        in tokens: [String: String],
        fallback: String
    ) -> String {
        guard let value, !value.isEmpty else { return fallback }
        return tokens[value] ?? value
    }
}
