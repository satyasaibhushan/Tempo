import SwiftUI
import TempoCore

struct MacAppRootView: View {
    @State private var session = AppSession()
    @State private var destination = MacDestination.now

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ProgressView("Connecting to Tempo…")
                    .tint(TempoTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TempoTheme.canvas)
            case .signedOut:
                MacLoginView(session: session)
            case .signedIn:
                if let store = session.timerStore {
                    authenticatedApp(store: store)
                } else {
                    ProgressView("Loading your timers…")
                }
            }
        }
        .task {
            await session.restoreIfNeeded()
        }
        .onOpenURL { url in
            if url.scheme == "fun.bhushan.tempo", url.host == "now" {
                destination = .now
            }
        }
    }

    private func authenticatedApp(store: ConvexTimerStore) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                brand(store: store)

                VStack(spacing: 3) {
                    ForEach(MacDestination.allCases) { item in
                        MacSidebarRow(item: item, selected: destination == item) {
                            destination = item
                        }
                    }
                }
                .padding(.top, 24)

                Spacer(minLength: 24)
                accountFooter(store: store)
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 22)
            .background(TempoTheme.canvas)
            .frame(width: 218)

            destinationView(destination, store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 26)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: 1_240, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TempoTheme.canvas)
        .font(.custom("Avenir Next", size: 14))
        .tint(TempoTheme.accent)
        .toolbar(.hidden, for: .windowToolbar)
        .alert("Something went wrong", isPresented: errorBinding(for: store)) {
            Button("OK") { store.clearError() }
        } message: {
            Text(store.errorMessage ?? "Please try again.")
        }
    }

    private func brand(store: ConvexTimerStore) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(TempoTheme.primaryForeground)
                .frame(width: 34, height: 34)
                .background(TempoTheme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Tempo")
                .font(.custom("Avenir Next", size: 17).weight(.bold))
                .tracking(-0.15)
                .foregroundStyle(TempoTheme.ink)

            Spacer(minLength: 8)
            MacTimerStatus(timers: store.timers)
        }
    }

    private func accountFooter(store: ConvexTimerStore) -> some View {
        HStack(spacing: 10) {
            AsyncImage(url: store.profile?.avatarUrl.flatMap(URL.init(string:))) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Text(userInitial(store: store))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TempoTheme.clay)
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())

            Text("\(store.profile?.name ?? "Tempo user") · personal")
                .font(.caption)
                .foregroundStyle(TempoTheme.sage)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button {
                Task { await session.logout() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TempoTheme.sage)
                    .frame(width: 28, height: 28)
                    .background(Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Log out")
        }
    }

    private func userInitial(store: ConvexTimerStore) -> String {
        String((store.profile?.name ?? store.profile?.email ?? "T").prefix(1)).uppercased()
    }

    @ViewBuilder
    private func destinationView(_ destination: MacDestination, store: ConvexTimerStore) -> some View {
        switch destination {
        case .now:
            TimerDashboardView(store: store)
        case .log:
            EntriesView(store: store)
        case .folders:
            FoldersView(store: store)
        case .labels:
            LabelsView(store: store)
        case .setup:
            SettingsView(store: store, onLogout: { Task { await session.logout() } })
        }
    }

    private func errorBinding(for store: ConvexTimerStore) -> Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )
    }
}

private enum MacDestination: String, CaseIterable, Identifiable {
    case now
    case log
    case folders
    case labels
    case setup

    var id: Self { self }

    var title: String {
        switch self {
        case .now: "Now"
        case .log: "Log"
        case .folders: "Folders"
        case .labels: "Labels"
        case .setup: "Setup"
        }
    }

    var icon: String {
        switch self {
        case .now: "gauge.with.dots.needle.50percent"
        case .log: "book.closed"
        case .folders: "folder"
        case .labels: "tag"
        case .setup: "gearshape"
        }
    }
}

private struct MacSidebarRow: View {
    let item: MacDestination
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: selected ? .semibold : .regular))
                    .frame(width: 18)
                Text(item.title)
                    .font(.custom("Avenir Next", size: 14.5).weight(.medium))
                Spacer()
            }
            .foregroundStyle(selected ? TempoTheme.primaryForeground : (hovering ? TempoTheme.ink : TempoTheme.mutedInk))
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(
                selected ? TempoTheme.ink : (hovering ? TempoTheme.secondary : Color.clear),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct MacTimerStatus: View {
    let timers: [TimeEntry]

    private var runningCount: Int { timers.count { $0.status == .running } }
    private var pausedCount: Int { timers.count { $0.status == .paused } }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusDot)
                .frame(width: 7, height: 7)
            Text(statusText)
                .lineLimit(1)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(runningCount > 0 ? TempoTheme.amberInk : TempoTheme.sage)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            runningCount > 0 ? TempoTheme.gold.opacity(0.25) : TempoTheme.muted,
            in: Capsule()
        )
    }

    private var statusText: String {
        if runningCount > 0 { return "\(runningCount) live" }
        if pausedCount > 0 { return "\(pausedCount) held" }
        return "Idle"
    }

    private var statusDot: Color {
        if runningCount > 0 { return TempoTheme.gold }
        if pausedCount > 0 { return TempoTheme.sage }
        return TempoTheme.input
    }
}

private struct MacLoginView: View {
    let session: AppSession

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(TempoTheme.clayInk)
                        .frame(width: 40, height: 40)
                        .background(TempoTheme.clay, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Tempo")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(TempoTheme.ink)
                        Text("PERSONAL TIMEKEEPER")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(TempoTheme.sage)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Circle().fill(TempoTheme.moss).frame(width: 6, height: 6)
                    Text("SYSTEM READY")
                }
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(TempoTheme.sage)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .overlay(alignment: .bottom) { Rectangle().fill(TempoTheme.line).frame(height: 1) }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer()
                    Text("TRACK THE WORK / KEEP THE EVIDENCE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(TempoTheme.sage)
                    Text("Time,\nmade visible.")
                        .font(.system(size: 62, weight: .medium, design: .serif))
                        .tracking(-1.4)
                        .foregroundStyle(TempoTheme.ink)
                    Text("A focused personal clock for honest sessions, clean history, and enough structure to find the pattern later.")
                        .font(.body)
                        .foregroundStyle(TempoTheme.sage)
                        .frame(maxWidth: 440, alignment: .leading)
                        .lineSpacing(5)
                    Spacer()
                }
                .padding(54)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Label("ACCESS PANEL", systemImage: "dot.radiowaves.left.and.right")
                        Spacer()
                        Text("AUTH / 01")
                    }
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(TempoTheme.sage)
                    .padding(.bottom, 18)
                    .overlay(alignment: .bottom) { Rectangle().fill(TempoTheme.line).frame(height: 1) }

                    Text("Pick up where you left off.")
                        .font(.system(size: 44, weight: .medium, design: .serif))
                        .foregroundStyle(TempoTheme.ink)
                        .padding(.top, 40)

                    Text("Log in or create an account to keep your timers and history synced across web, iPhone, and Mac.")
                        .font(.body)
                        .foregroundStyle(TempoTheme.sage)
                        .lineSpacing(4)
                        .padding(.top, 18)

                    if let errorMessage = session.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(TempoTheme.destructive)
                            .padding(.top, 12)
                    }

                    Button {
                        Task { await session.login() }
                    } label: {
                        HStack {
                            Text("Continue to Tempo")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryCapsuleButtonStyle())
                    .padding(.top, 36)

                    Spacer()

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(TempoTheme.moss)
                        Text("Auth0 identity, Convex-backed data, and concurrent timers on one shared clock. Built for personal use.")
                            .font(.caption2)
                            .foregroundStyle(TempoTheme.sage)
                            .lineSpacing(4)
                    }
                    .padding(.top, 20)
                    .overlay(alignment: .top) { Rectangle().fill(TempoTheme.line).frame(height: 1) }
                }
                .padding(36)
                .frame(width: 420)
                .frame(maxHeight: .infinity, alignment: .leading)
                .overlay(alignment: .leading) { Rectangle().fill(TempoTheme.line).frame(width: 1) }
            }
        }
        .background(TempoTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(TempoTheme.line, lineWidth: 1) }
        .padding(28)
        .background(TempoTheme.canvas)
    }
}
