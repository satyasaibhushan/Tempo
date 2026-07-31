import AppKit
import Auth0
import SwiftUI

@main
struct TempoMacApp: App {
    @NSApplicationDelegateAdaptor(TempoAppDelegate.self) private var appDelegate

    init() {
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
    }

    var body: some Scene {
        Window("Tempo", id: "main") {
            MacAppRootView()
                .frame(minWidth: 920, minHeight: 640)
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1_180, height: 780)
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }
    }
}

private final class TempoAppDelegate: NSObject, NSApplicationDelegate {
    func application(_: NSApplication, open urls: [URL]) {
        urls.forEach { WebAuthentication.resume(with: $0) }
    }
}
