import Foundation

public struct NativeEnvironment: Equatable, Sendable {
    public enum ConfigurationError: Error, Equatable, LocalizedError {
        case missingConvexURL
        case invalidConvexURL(String)

        public var errorDescription: String? {
            switch self {
            case .missingConvexURL:
                "CONVEX_URL is missing. Set it in the runtime environment or Apple build environment."
            case .invalidConvexURL(let value):
                "CONVEX_URL must be an HTTPS URL on convex.cloud; received \(value)."
            }
        }
    }

    public let convexURL: URL

    public init(convexURLString: String) throws {
        let value = convexURLString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            throw ConfigurationError.missingConvexURL
        }

        guard
            let url = URL(string: value),
            url.scheme == "https",
            url.host?.hasSuffix(".convex.cloud") == true
        else {
            throw ConfigurationError.invalidConvexURL(value)
        }

        convexURL = url
    }

    public static func configured(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) throws -> NativeEnvironment {
        let runtimeValue = normalized(environment["CONVEX_URL"])
        let embeddedValue = normalized(infoDictionary["ConvexURL"] as? String)

        guard let value = runtimeValue ?? embeddedValue else {
            throw ConfigurationError.missingConvexURL
        }

        return try NativeEnvironment(convexURLString: value)
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else { return nil }
        return trimmed
    }
}
