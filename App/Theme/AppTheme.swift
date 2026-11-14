import SwiftUI

enum AppTheme {
    static let backgroundPrimary = Color(red: 0.039, green: 0.043, blue: 0.055)   // #0A0B0E OLED Obsidian
    static let backgroundElevated = Color(red: 0.075, green: 0.086, blue: 0.110)  // #13161C
    static let surfaceCard = Color(red: 0.106, green: 0.122, blue: 0.157)         // #1B1F28
    static let surfaceInput = Color(red: 0.137, green: 0.157, blue: 0.204)        // #232834
    static let borderSubtle = Color.white.opacity(0.08)

    static let accentPrimary = Color(red: 0.34, green: 0.78, blue: 0.96)          // Cool Cyan
    static let accentSecondary = Color(red: 0.56, green: 0.49, blue: 0.98)        // Soft Indigo

    static let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let textSecondary = Color(red: 0.62, green: 0.66, blue: 0.74)

    static let statusGreen = Color(red: 0.24, green: 0.84, blue: 0.56)
    static let statusAmber = Color(red: 0.96, green: 0.71, blue: 0.26)
    static let statusRed = Color(red: 0.96, green: 0.36, blue: 0.42)
}
