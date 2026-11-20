// Generated from shared/design-tokens.json.
import SwiftUI
enum MHDesign {
    static let canvas = Color(hex: 0xFCFCFE)
    static let surface = Color(hex: 0xFFFFFF)
    static let ink = Color(hex: 0x292735)
    static let secondary = Color(hex: 0x74647F)
    static let accent = Color(hex: 0x8055CE)
    static let accentSoft = Color(hex: 0xECE4F8)
    static let border = Color(hex: 0xE7E1ED)
    static let orb = Color(hex: 0xD8CEEE)
    static let pageInset: CGFloat = 20
    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 12
    static let tileSize: CGFloat = 52
    static let orbSize: CGFloat = 82
    static let peopleRadius: CGFloat = 75
    static let tabHeight: CGFloat = 59
    static let sidebarWidth: CGFloat = 208
    static let headingSize: CGFloat = 22
    static let bodySize: CGFloat = 14
    static let captionSize: CGFloat = 11
    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(weight == .semibold || weight == .bold ? "Inter-SemiBold" : weight == .medium ? "Inter-Medium" : "Inter-Regular", size: size, relativeTo: .body)
    }
}
extension Color { init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255, opacity: 1) } }
