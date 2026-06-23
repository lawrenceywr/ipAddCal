import SwiftUI

enum ThemeAccentMode: Equatable {
    case macOSBlue

    var tint: Color { .blue }
}

enum ThemeGlassIntensity: Equatable {
    case elevated
}

enum ThemeSurfaceContrast: Equatable {
    case clearBoundaries
}

struct CalculatorSurfaceStyle: Equatable {
    var cornerRadius: CGFloat
    var fillOpacity: Double
    var strokeOpacity: Double
    var highlightOpacity: Double
    var shadowOpacity: Double
}

struct CalculatorTheme: Equatable {
    var enforcesDarkAppearance: Bool
    var accentMode: ThemeAccentMode
    var glassIntensity: ThemeGlassIntensity
    var surfaceContrast: ThemeSurfaceContrast
    var windowBase = Color(red: 0.115, green: 0.121, blue: 0.139)
    var chromeBase = Color(red: 0.148, green: 0.156, blue: 0.178)
    var chromeElevated = Color(red: 0.178, green: 0.186, blue: 0.212)
    var contentBase = Color(red: 0.205, green: 0.214, blue: 0.244)
    var divider = Color.white.opacity(0.10)
    var secondaryLabel = Color.white.opacity(0.64)
    var error = Color(red: 0.93, green: 0.42, blue: 0.42)
    var workspaceSurface: CalculatorSurfaceStyle
    var popoverSurface: CalculatorSurfaceStyle

    static let defaultDark = CalculatorTheme(
        enforcesDarkAppearance: true,
        accentMode: .macOSBlue,
        glassIntensity: .elevated,
        surfaceContrast: .clearBoundaries,
        workspaceSurface: CalculatorSurfaceStyle(
            cornerRadius: 20,
            fillOpacity: 0.78,
            strokeOpacity: 0.18,
            highlightOpacity: 0.24,
            shadowOpacity: 0.22
        ),
        popoverSurface: CalculatorSurfaceStyle(
            cornerRadius: 18,
            fillOpacity: 0.86,
            strokeOpacity: 0.16,
            highlightOpacity: 0.28,
            shadowOpacity: 0.24
        )
    )
}
