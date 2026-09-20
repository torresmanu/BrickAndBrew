import SwiftUI

/// Brick & Brew color tokens. Names are semantic; hex values match the web identity.
///
/// Product polarity is ink-native: dark backgrounds, warm paper type, signal orange
/// used only for primary actions, the current user, points, and Level 3 moments.
enum Palette {
    // MARK: Primitives — never paint a view with these directly when a semantic exists.

    static let ink = Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255)
    static let inkDeep = Color.black
    static let inkElevated = Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255)
    static let inkMute = Color(red: 140 / 255, green: 136 / 255, blue: 130 / 255)
    static let paper = Color(red: 242 / 255, green: 239 / 255, blue: 231 / 255)
    static let paperSoft = Color(red: 247 / 255, green: 245 / 255, blue: 239 / 255)
    static let signal = Color(red: 255 / 255, green: 75 / 255, blue: 36 / 255)
    static let signalPressed = Color(red: 224 / 255, green: 58 / 255, blue: 22 / 255)

    // MARK: Semantic — what screens and components should read.

    static let background = ink
    static let surface = inkDeep
    static let surfaceElevated = inkElevated
    static let text = paper
    static let secondaryText = inkMute
    static let accent = signal
    static let accentPressed = signalPressed
    static let hairline = paper.opacity(0.14)
    static let hairlineStrong = paper.opacity(0.28)

    /// Errors stay system red so they are never mistaken for brand orange.
    static let danger = Color(red: 1, green: 59 / 255, blue: 48 / 255)
    static let success = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let stravaOrange = Color(red: 252 / 255, green: 76 / 255, blue: 2 / 255)

    // MARK: Compatibility aliases — existing call sites keep compiling during the restyle.

    static let black = inkDeep
    static let white = paper
    static let ground = background
    static let cream = text
    static let muted = secondaryText
    static let amber = accent
    static let copper = inkMute
    static let placeholder = Color(red: 229 / 255, green: 229 / 255, blue: 229 / 255)
}
