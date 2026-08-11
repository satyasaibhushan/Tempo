import Auth0
import ConvexMobile
import Foundation
import Observation
import TempoCore

@MainActor
@Observable
final class AppSession {
    enum Phase: Equatable {
        case loading
        case signedOut
        case signedIn
    }

    private(set) var phase: Phase = .loading
    private(set) var timerStore: ConvexTimerStore?
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let client: ConvexClientWithAuth<Credentials>?
    @ObservationIgnored
    private var didRestore = false

    init() {
        do {
            let environment = try NativeEnvironment.configured()
            client = ConvexClientWithAuth<Credentials>(
                deploymentUrl: environment.convexURL.absoluteString,
                authProvider: TempoAuthProvider()
            )
        } catch {
            client = nil
            errorMessage = "Tempo configuration error: \(error.localizedDescription)"
            phase = .signedOut
        }
    }

    func restoreIfNeeded() async {
        guard !didRestore else { return }
        didRestore = true
        guard let client else {
            phase = .signedOut
            return
        }

        switch await client.loginFromCache() {
        case .success:
            await activateAuthenticatedSession()
        case .failure:
            phase = .signedOut
        }
    }

    func login() async {
        guard let client else {
            phase = .signedOut
            return
        }

        phase = .loading
        errorMessage = nil

        switch await client.login() {
        case .success:
            await activateAuthenticatedSession()
        case .failure(let error):
            errorMessage = error.localizedDescription
            phase = .signedOut
        }
    }

    func logout() async {
        timerStore = nil
        errorMessage = nil
        phase = .signedOut
        await client?.logout()
    }

    private func activateAuthenticatedSession() async {
        guard let client else {
            phase = .signedOut
            return
        }

        do {
            let timezone = TimeZone.current.identifier
            let _: DocumentID = try await client.mutation(
                ConvexAPI.Users.ensureCurrent,
                with: ["timezone": timezone]
            )
            timerStore = ConvexTimerStore(client: client)
            phase = .signedIn
        } catch {
            errorMessage = error.localizedDescription
            phase = .signedOut
        }
    }
}
