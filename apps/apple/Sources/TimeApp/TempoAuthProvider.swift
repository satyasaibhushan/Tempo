import Auth0
import ConvexMobile
import Foundation
#if os(macOS)
import AppKit
#endif

final class TempoAuthProvider: AuthProvider {
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    func login(onIdToken _: @escaping @Sendable (String?) -> Void) async throws -> Credentials {
        var webAuth = Auth0.webAuth()
            .scope("openid profile email offline_access")
            .parameters(["prompt": "select_account"])
#if os(macOS)
        webAuth = webAuth.provider(MacDefaultBrowserWebAuth.makeProvider())
#else
        webAuth = webAuth
            .useEphemeralSession()
#endif
        let credentials = try await webAuth.start()
        guard credentialsManager.store(credentials: credentials) else {
            throw CredentialsManagerError.storeFailed
        }
        return credentials
    }

    func loginFromCache(onIdToken: @escaping @Sendable (String?) -> Void) async throws -> Credentials {
        do {
            let credentials = try await credentialsManager.credentials()
            onIdToken(credentials.idToken)
            return credentials
        } catch {
            onIdToken(nil)
            throw error
        }
    }

    func extractIdToken(from authResult: Credentials) -> String {
        authResult.idToken
    }

    func logout() async throws {
        _ = credentialsManager.clear()
    }
}

#if os(macOS)
private enum MacDefaultBrowserWebAuth {
    static func makeProvider() -> WebAuthProvider {
        { authorizeURL, callback in
            DefaultBrowserUserAgent(authorizeURL: authorizeURL, callback: callback)
        }
    }
}

private final class DefaultBrowserUserAgent: WebAuthUserAgent {
    private let authorizeURL: URL
    private let callback: WebAuthProviderCallback
    private var isFinished = false

    init(authorizeURL: URL, callback: @escaping WebAuthProviderCallback) {
        self.authorizeURL = authorizeURL
        self.callback = callback
    }

    func start() {
        guard NSWorkspace.shared.open(authorizeURL) else {
            finish(with: .failure(.unknown))
            return
        }
    }

    func finish(with result: WebAuthResult<Void>) {
        guard !isFinished else { return }
        isFinished = true
        callback(result)
    }
}

#endif
