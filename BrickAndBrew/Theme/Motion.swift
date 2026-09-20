import SwiftUI

/// Sporting motion: fast, physical, and skipped entirely when Reduce Motion is on.
enum Motion {
    static let fast: Double = 0.12
    static let base: Double = 0.2
    static let slow: Double = 0.32

    static var sport: Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: base)
    }

    static func sport(duration: Double) -> Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: duration)
    }
}

extension View {
    /// Apply a decisive scale-in unless the user asked for reduced motion.
    func brandAppear(isReducedMotion: Bool, trigger: Bool) -> some View {
        modifier(BrandAppearModifier(isReducedMotion: isReducedMotion, trigger: trigger))
    }
}

private struct BrandAppearModifier: ViewModifier {
    let isReducedMotion: Bool
    let trigger: Bool

    func body(content: Content) -> some View {
        if isReducedMotion {
            content
        } else {
            content
                .scaleEffect(trigger ? 1 : 0.92)
                .opacity(trigger ? 1 : 0)
                .animation(Motion.sport, value: trigger)
        }
    }
}
