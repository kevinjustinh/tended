import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary
    static let sageGreen   = Color(hex: "#7A9E7E")  // Primary actions, CTAs
    static let warmTan     = Color(hex: "#C8A97E")  // Accents, highlights
    static let deepForest  = Color(hex: "#3D5A40")  // Headers, strong text

    // Background
    static let creamWhite  = Color(hex: "#FAF6F0")  // Main background
    static let softLinen   = Color(hex: "#F0EAE0")  // Card backgrounds
    static let warmSand    = Color(hex: "#E8DDD0")  // Dividers, subtle fills

    // Semantic
    static let alertAmber     = Color(hex: "#D4873A")  // Warnings, overdue tasks
    static let successMoss    = Color(hex: "#5E8B5E")  // Completed states
    static let textPrimary    = Color(hex: "#2C2416")  // Body text
    static let textSecondary  = Color(hex: "#7A6A52")  // Secondary labels

    // Category card fills
    static let feedingCard   = Color(hex: "#E8C9A0")
    static let medCard       = Color(hex: "#E8C4B8")
    static let exerciseCard  = Color(hex: "#B8CEB8")
    static let vetCard       = Color(hex: "#C8C0D4")
    static let waterCard     = Color(hex: "#B8CDD8")
    static let groomingCard  = Color(hex: "#D4C8B8")
    static let cleaningCard  = Color(hex: "#B8D4D0")
    static let treatsCard    = Color(hex: "#E8C0D4")
    static let bathroomCard  = Color(hex: "#C4D8B8")
    static let playCard      = Color(hex: "#E8D8A8")
    static let customCard    = Color(hex: "#D8D0C8")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Typography

extension Font {
    /// Large display/hero titles — SF Pro Rounded bold
    static func displayTitle(size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Section headers — SF Pro Rounded semibold
    static func sectionHeader(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Card titles and prominent labels
    static func cardTitle(size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Standard body text — SF Pro
    static func bodyText(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// Secondary/caption text
    static func caption(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// Monospaced for times and counts
    static func monoText(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - Spacing

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius

enum CornerRadius {
    static let small:  CGFloat = 8
    static let medium: CGFloat = 12
    static let large:  CGFloat = 18
    static let card:   CGFloat = 20
}

// MARK: - Haptics

enum HapticStyle {
    case taskComplete
    case overdueAlert
    case delete
    case navigation

    func trigger() {
        switch self {
        case .taskComplete:
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare()
            g.impactOccurred()
        case .overdueAlert:
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            g.impactOccurred()
        case .delete:
            let g = UIImpactFeedbackGenerator(style: .rigid)
            g.prepare()
            g.impactOccurred()
        case .navigation:
            let g = UISelectionFeedbackGenerator()
            g.prepare()
            g.selectionChanged()
        }
    }
}

// MARK: - Motion

extension Animation {
    /// Standard spring for task completion checkmarks and card pops
    static let springPop = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Gentler spring for card transitions
    static let springCard = Animation.spring(response: 0.4, dampingFraction: 0.75)

    /// Crossfade for tab switches
    static let tabSwitch = Animation.easeInOut(duration: 0.2)
}

// MARK: - View Modifiers

struct CardBackground: ViewModifier {
    var color: Color = .softLinen

    func body(content: Content) -> some View {
        content
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .shadow(color: Color.textPrimary.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(color: Color = .softLinen) -> some View {
        modifier(CardBackground(color: color))
    }
}
