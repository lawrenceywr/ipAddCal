import SwiftUI

enum ThemeAccentMode: Equatable {
    case calculatorOrange

    var tint: Color { Color(red: 1.0, green: 0.584, blue: 0.0) }
}

enum ThemeGlassIntensity: Equatable {
    case elevated
}

enum ThemeSurfaceContrast: Equatable {
    case clearBoundaries
}

struct CalculatorSurfaceStyle: Equatable {
    let cornerRadius: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
    let highlightOpacity: Double
    let shadowOpacity: Double
}

struct CalculatorChromeStyle: Equatable {
    let sidebarFillOpacity: Double
    let detailFillOpacity: Double
    let toolbarLineOpacity: Double
    let sidebarFloatingCornerRadius: CGFloat
    let sidebarRowCornerRadius: CGFloat
    let titleItemBorderOpacity: Double
    let integratedSidebarWidth: CGFloat
    let integratedSidebarDividerOpacity: Double
}

struct CalculatorFieldChrome: Equatable {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
    let strokeWidth: CGFloat
    let invalidStrokeWidth: CGFloat
}

struct CalculatorSectionChrome: Equatable {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let rowSpacing: CGFloat
    let headerSpacing: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
}

struct CalculatorTheme: Equatable {
    let enforcesDarkAppearance: Bool
    let accentMode: ThemeAccentMode
    let glassIntensity: ThemeGlassIntensity
    let surfaceContrast: ThemeSurfaceContrast
    let windowBase: Color
    let chromeBase: Color
    let chromeElevated: Color
    let contentBase: Color
    let primaryLabel: Color
    let secondaryLabel: Color
    let divider: Color
    let stroke: Color
    let highlight: Color
    let shadow: Color
    let error: Color
    let workspaceSurface: CalculatorSurfaceStyle
    let formSurface: CalculatorSurfaceStyle
    let popoverSurface: CalculatorSurfaceStyle

    static let defaultDark = CalculatorTheme(
        enforcesDarkAppearance: true,
        accentMode: .calculatorOrange,
        glassIntensity: .elevated,
        surfaceContrast: .clearBoundaries,
        windowBase: Color(red: 0.115, green: 0.121, blue: 0.139),
        chromeBase: Color(red: 0.148, green: 0.156, blue: 0.178),
        chromeElevated: Color(red: 0.178, green: 0.186, blue: 0.212),
        contentBase: Color(red: 0.205, green: 0.214, blue: 0.244),
        primaryLabel: Color.white.opacity(0.94),
        secondaryLabel: Color.white.opacity(0.64),
        divider: Color.white.opacity(0.10),
        stroke: Color.white,
        highlight: Color.white,
        shadow: Color.black,
        error: Color(red: 0.93, green: 0.42, blue: 0.42),
        workspaceSurface: CalculatorSurfaceStyle(
            cornerRadius: 20,
            fillOpacity: 0.78,
            strokeOpacity: 0.18,
            highlightOpacity: 0.24,
            shadowOpacity: 0.22
        ),
        formSurface: CalculatorSurfaceStyle(
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

    static let defaultLight = CalculatorTheme(
        enforcesDarkAppearance: false,
        accentMode: .calculatorOrange,
        glassIntensity: .elevated,
        surfaceContrast: .clearBoundaries,
        windowBase: Color(red: 0.900, green: 0.910, blue: 0.930),
        chromeBase: Color(red: 0.860, green: 0.872, blue: 0.895),
        chromeElevated: Color(red: 0.956, green: 0.962, blue: 0.974),
        contentBase: Color(red: 0.976, green: 0.980, blue: 0.988),
        primaryLabel: Color(red: 0.110, green: 0.118, blue: 0.137),
        secondaryLabel: Color(red: 0.390, green: 0.405, blue: 0.445),
        divider: Color.black.opacity(0.09),
        stroke: Color.black,
        highlight: Color.white,
        shadow: Color.black,
        error: Color(red: 0.740, green: 0.140, blue: 0.120),
        workspaceSurface: CalculatorSurfaceStyle(
            cornerRadius: 20,
            fillOpacity: 0.92,
            strokeOpacity: 0.12,
            highlightOpacity: 0.55,
            shadowOpacity: 0.10
        ),
        formSurface: CalculatorSurfaceStyle(
            cornerRadius: 20,
            fillOpacity: 0.92,
            strokeOpacity: 0.12,
            highlightOpacity: 0.55,
            shadowOpacity: 0.10
        ),
        popoverSurface: CalculatorSurfaceStyle(
            cornerRadius: 18,
            fillOpacity: 0.98,
            strokeOpacity: 0.12,
            highlightOpacity: 0.60,
            shadowOpacity: 0.16
        )
    )
}

enum CalculatorAppearance: String, Equatable, CaseIterable, Identifiable {
    case dark
    case light

    static let storageKey = "calculatorAppearance"
    static let defaultValue: CalculatorAppearance = .dark

    var id: String { rawValue }

    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? Self.defaultValue
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }

    var theme: CalculatorTheme {
        switch self {
        case .dark: return .defaultDark
        case .light: return .defaultLight
        }
    }

    var toggled: CalculatorAppearance {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }

    var toggleIconSystemName: String {
        switch self {
        case .dark: return "sun.max.fill"
        case .light: return "moon.fill"
        }
    }

    var toggleAccessibilityLabel: String {
        switch self {
        case .dark: return "切换到浅色模式"
        case .light: return "切换到深色模式"
        }
    }
}

private struct CalculatorThemeKey: EnvironmentKey {
    static let defaultValue = CalculatorTheme.defaultDark
}

extension EnvironmentValues {
    var calculatorTheme: CalculatorTheme {
        get { self[CalculatorThemeKey.self] }
        set { self[CalculatorThemeKey.self] = newValue }
    }
}

extension View {
    func calculatorTheme(_ theme: CalculatorTheme) -> some View {
        environment(\.calculatorTheme, theme)
    }
}

extension CalculatorTheme {
    var chrome: CalculatorChromeStyle {
        CalculatorChromeStyle(
            sidebarFillOpacity: 0.96,
            detailFillOpacity: 0.94,
            toolbarLineOpacity: 0.06,
            sidebarFloatingCornerRadius: 0,
            sidebarRowCornerRadius: 10,
            titleItemBorderOpacity: 0,
            integratedSidebarWidth: 168,
            integratedSidebarDividerOpacity: 0.10
        )
    }

    var fieldChrome: CalculatorFieldChrome {
        CalculatorFieldChrome(
            cornerRadius: 12,
            horizontalPadding: 12,
            verticalPadding: 10,
            fillOpacity: 0.92,
            strokeOpacity: 0.14,
            strokeWidth: 1,
            invalidStrokeWidth: 1.3
        )
    }

    var resultSection: CalculatorSectionChrome {
        CalculatorSectionChrome(
            cornerRadius: 16,
            horizontalPadding: 14,
            verticalPadding: 12,
            rowSpacing: 12,
            headerSpacing: 8,
            fillOpacity: 0.76,
            strokeOpacity: 0.12
        )
    }
}
