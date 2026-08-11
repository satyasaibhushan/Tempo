import SwiftUI

enum TempoTheme {
    static let canvas = Color(hex: "#edefe8")
    static let surface = Color(hex: "#f7f8f2")
    static let popover = Color(hex: "#fdfdf9")
    static let timerSurface = Color(hex: "#22372b")
    static let timerSurfaceSoft = Color(hex: "#2e4638")
    static let accent = Color(hex: "#22372b")
    static let ink = Color(hex: "#22372b")
    static let primaryForeground = Color(hex: "#f2f4ec")
    static let mutedInk = Color(hex: "#57705f")
    static let softGreen = Color(hex: "#a9c3a3")
    static let moss = Color(hex: "#5a7d5a")
    static let sage = Color(hex: "#7d9184")
    static let clay = Color(hex: "#c4704f")
    static let gold = Color(hex: "#d8a25a")
    static let amberInk = Color(hex: "#7d5a24")
    static let clayInk = Color(hex: "#2b160e")
    static let line = Color(hex: "#dee2d3")
    static let input = Color(hex: "#d3d8c6")
    static let muted = Color(hex: "#e6e9dd")
    static let secondary = Color(hex: "#e2e5da")
    static let destructive = Color(hex: "#a8432c")
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let rgb = UInt64(value, radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xff) / 255,
            green: Double((rgb >> 8) & 0xff) / 255,
            blue: Double(rgb & 0xff) / 255,
            opacity: 1
        )
    }
}
