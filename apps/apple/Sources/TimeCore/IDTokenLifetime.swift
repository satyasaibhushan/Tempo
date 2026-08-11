import Foundation

public enum IDTokenLifetime {
    public static func isUsable(
        _ token: String,
        at now: Date = Date(),
        minimumTTL: TimeInterval = 60
    ) -> Bool {
        guard let expiration = expirationDate(in: token) else { return false }
        return expiration.timeIntervalSince(now) > minimumTTL
    }

    private static func expirationDate(in token: String) -> Date? {
        let components = token.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 3 else { return nil }

        var payload = String(components[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - payload.count % 4) % 4
        payload.append(String(repeating: "=", count: padding))

        guard
            let data = Data(base64Encoded: payload),
            let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let expiration = claims["exp"] as? NSNumber
        else {
            return nil
        }

        return Date(timeIntervalSince1970: expiration.doubleValue)
    }
}
