import SwiftUI
import TempoCore

struct SettingsView: View {
    @Bindable var store: ConvexTimerStore
    let onLogout: () -> Void
    @State private var editingProfile = false
    @State private var editingPreferences = false
    @State private var name = ""
    @State private var email = ""
    @State private var timezone = ""
    @State private var weekStart = WeekStart.monday
    @State private var timeFormat = TimeFormat.twentyFourHour
    @State private var showingDeleteAccount = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    #if os(macOS)
                    TerraPageHeader(
                        kicker: "System / setup",
                        title: "Tune the instrument.",
                        subtitle: "Personal settings that shape how the app displays time and organizes your day."
                    )

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        alignment: .leading,
                        spacing: 20
                    ) {
                        macProfileCard
                        macPreferencesCard
                    }

                    macAccountCard
                    legalCard
                    deleteAccountCard
                    widgetCard
                    #else
                    TerraPageHeader(
                        kicker: "Account / setup",
                        title: "Keep Tempo yours.",
                        subtitle: setupSubtitle
                    )

                    profileCard
                    syncCard
                    widgetCard
                    legalCard
                    deleteAccountCard

                    Button(role: .destructive, action: onLogout) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(TempoTheme.destructive)
                    #endif
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
            .background(TempoTheme.canvas.ignoresSafeArea())
            .navigationTitle("Setup")
            .timeNavigationChrome()
            .onAppear(perform: syncDrafts)
            .onChange(of: store.profile) { _, _ in
                if !editingProfile && !editingPreferences { syncDrafts() }
            }
            .confirmationDialog(
                "Permanently delete your account?",
                isPresented: $showingDeleteAccount,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        if await store.deleteAccount() {
                            onLogout()
                        }
                    }
                }
                Button("Keep Account", role: .cancel) {}
            } message: {
                Text("This removes your Tempo profile, timers, entries, folders, labels, and sign-in identity. Nothing can be recovered afterward.")
            }
        }
    }

    #if os(macOS)
    private var macProfileCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsCardHeader(
                title: "Profile",
                subtitle: "Your display name and email.",
                editing: editingProfile,
                action: { editingProfile = true }
            )

            if editingProfile {
                TerraLabeledTextField(label: "Name", text: $name)
                TerraLabeledTextField(label: "Email", text: $email)
                settingsActions(
                    cancel: {
                        syncDrafts()
                        editingProfile = false
                    },
                    save: {
                        Task {
                            if await store.updateProfile(name: name, email: email) {
                                editingProfile = false
                            }
                        }
                    }
                )
            } else {
                TerraReadout(label: "Name", value: store.profile?.name ?? "Not set")
                TerraReadout(label: "Email", value: store.profile?.email ?? "Not set")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .terraSurface(padding: 22)
    }

    private var macPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsCardHeader(
                title: "Preferences",
                subtitle: "Timezone, time format, and week start.",
                editing: editingPreferences,
                action: { editingPreferences = true }
            )

            if editingPreferences {
                TerraLabeledTextField(label: "Timezone", text: $timezone)
                TerraChoiceField(
                    label: "Time Format",
                    options: [
                        ("24h", TimeFormat.twentyFourHour),
                        ("12h", TimeFormat.twelveHour),
                    ],
                    selection: $timeFormat
                )
                TerraChoiceField(
                    label: "Week Start",
                    options: [
                        ("Monday", WeekStart.monday),
                        ("Sunday", WeekStart.sunday),
                    ],
                    selection: $weekStart
                )
                settingsActions(
                    cancel: {
                        syncDrafts()
                        editingPreferences = false
                    },
                    save: {
                        Task {
                            if await store.updatePreferences(
                                timezone: timezone,
                                timeFormat: timeFormat,
                                weekStart: weekStart
                            ) {
                                editingPreferences = false
                            }
                        }
                    }
                )
            } else {
                TerraReadout(label: "Timezone", value: store.profile?.timezone ?? TimeZone.current.identifier)
                TerraReadout(label: "Time Format", value: store.profile?.timeFormat.rawValue ?? "24h")
                TerraReadout(label: "Week Start", value: (store.profile?.weekStart.rawValue ?? "monday").capitalized)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .terraSurface(padding: 22)
    }

    private var macAccountCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Account")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(TempoTheme.ink)
                Text("Auth provider and session management.")
                    .font(.subheadline)
                    .foregroundStyle(TempoTheme.sage)
            }

            HStack {
                TerraReadout(label: "Provider", value: "Auth0 (Apple + Google + Email)")
                Button("Log out", action: onLogout)
                    .buttonStyle(TerraOutlineButtonStyle())
            }
        }
        .terraSurface(padding: 22)
    }

    private func settingsCardHeader(
        title: String,
        subtitle: String,
        editing: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(TempoTheme.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(TempoTheme.sage)
            }
            Spacer()
            if !editing {
                Button(action: action) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TempoTheme.sage)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func settingsActions(cancel: @escaping () -> Void, save: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Button(action: cancel) {
                Label("Cancel", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TerraOutlineButtonStyle())
            .disabled(store.isMutating)

            Button(action: save) {
                Label("Save", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
            .disabled(store.isMutating)
        }
    }
    #endif

    private func syncDrafts() {
        name = store.profile?.name ?? ""
        email = store.profile?.email ?? ""
        timezone = store.profile?.timezone ?? TimeZone.current.identifier
        weekStart = store.profile?.weekStart ?? .monday
        timeFormat = store.profile?.timeFormat ?? .twentyFourHour
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            AsyncImage(url: store.profile?.avatarUrl.flatMap(URL.init(string:))) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Text(initial)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TempoTheme.clay)
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(store.profile?.name ?? "Tempo user")
                    .font(.headline)
                    .foregroundStyle(TempoTheme.ink)
                Text(store.profile?.email ?? "Signed in with Auth0")
                    .font(.caption)
                    .foregroundStyle(TempoTheme.sage)
                    .lineLimit(1)
            }
            Spacer()
        }
        .terraSurface()
    }

    private var initial: String {
        String((store.profile?.name ?? store.profile?.email ?? "T").prefix(1)).uppercased()
    }

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Convex sync", systemImage: "checkmark.icloud.fill")
                    .font(.headline)
                    .foregroundStyle(TempoTheme.ink)
                Spacer()
                Text("LIVE")
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundStyle(TempoTheme.moss)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(TempoTheme.muted, in: Capsule())
            }

            HStack {
                Metric(value: "\(store.timers.count)", label: "Active")
                Divider().frame(height: 34)
                Metric(value: "\(store.completedEntries.count)", label: "Entries")
                Divider().frame(height: 34)
                Metric(value: "\(store.activeFolders.count)", label: "Folders")
                Divider().frame(height: 34)
                Metric(value: "\(store.labels.count)", label: "Labels")
            }
        }
        .terraSurface()
    }

    private var widgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(widgetTitle, systemImage: "rectangle.3.group.fill")
                .font(.headline)
                .foregroundStyle(TempoTheme.ink)
            Text(widgetDescription)
                .font(.subheadline)
                .foregroundStyle(TempoTheme.mutedInk)
            Text(widgetInstruction)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TempoTheme.moss)
        }
        .terraSurface()
    }

    private var legalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Privacy and support", systemImage: "hand.raised.fill")
                .font(.headline)
                .foregroundStyle(TempoTheme.ink)

            Text("Read how Tempo handles your data or contact Sai Bhushan directly for help.")
                .font(.subheadline)
                .foregroundStyle(TempoTheme.mutedInk)

            HStack(spacing: 10) {
                Link(destination: URL(string: "https://tempo.bhushan.fun/privacy")!) {
                    Label("Privacy", systemImage: "arrow.up.right")
                }
                .buttonStyle(.bordered)

                Link(destination: URL(string: "https://tempo.bhushan.fun/support")!) {
                    Label("Support", systemImage: "arrow.up.right")
                }
                .buttonStyle(.bordered)
            }
            .tint(TempoTheme.moss)
        }
        .terraSurface()
    }

    private var deleteAccountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Delete account", systemImage: "trash.fill")
                .font(.headline)
                .foregroundStyle(TempoTheme.destructive)

            Text("Permanently remove your sign-in identity and every timer, entry, folder, and label stored by Tempo.")
                .font(.subheadline)
                .foregroundStyle(TempoTheme.mutedInk)

            Button(role: .destructive) {
                showingDeleteAccount = true
            } label: {
                Text("Delete My Account")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(TempoTheme.destructive)
            .disabled(store.isMutating)
        }
        .terraSurface()
    }

    private var setupSubtitle: String {
        #if os(macOS)
        "Your account, synchronization status, and widget setup in one quiet place."
        #else
        "Your account, synchronization status, and widget setup in one quiet place."
        #endif
    }

    private var widgetTitle: String {
        #if os(macOS)
        "Desktop widgets"
        #else
        "Home Screen widgets"
        #endif
    }

    private var widgetDescription: String {
        #if os(macOS)
        "Add the compact current-timer widget or a configurable day, week, or month summary to your desktop."
        #else
        "Add the compact widget for the current timer, or the wide summary widget for a filtered day, week, or month."
        #endif
    }

    private var widgetInstruction: String {
        #if os(macOS)
        "Control-click the desktop → Edit Widgets → Tempo"
        #else
        "Long-press the Home Screen → Edit → Add Widget → Tempo"
        #endif
    }
}

private struct Metric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(TempoTheme.ink)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TempoTheme.sage)
        }
        .frame(maxWidth: .infinity)
    }
}

#if os(macOS)
private struct TerraReadout: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(TempoTheme.sage)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(TempoTheme.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TempoTheme.muted.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TempoTheme.line, lineWidth: 1)
        }
    }
}

private struct TerraLabeledTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(TempoTheme.sage)
            TextField(label, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(TempoTheme.ink)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(TempoTheme.muted.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TempoTheme.line, lineWidth: 1)
                }
        }
    }
}

private struct TerraChoiceField<Value: Hashable>: View {
    let label: String
    let options: [(String, Value)]
    @Binding var selection: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(TempoTheme.sage)
            HStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Button {
                        selection = option.1
                    } label: {
                        Text(option.0)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selection == option.1 ? TempoTheme.moss : TempoTheme.mutedInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                selection == option.1 ? TempoTheme.moss.opacity(0.1) : TempoTheme.surface,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        selection == option.1 ? TempoTheme.moss.opacity(0.3) : TempoTheme.line,
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct TerraOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(TempoTheme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                configuration.isPressed ? TempoTheme.secondary : TempoTheme.surface,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(TempoTheme.line, lineWidth: 1)
            }
    }
}
#endif
