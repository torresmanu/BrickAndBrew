import SwiftUI

/// Colors from Brand Labs Finalist B only (Figma `35:809`). 100% monochrome.
enum Palette {
    static let black = Color.black
    static let white = Color.white
    /// Negative-state ground used for the app-icon stage and kit silhouettes.
    static let ground = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
    /// Light specimen field behind the mark on paper.
    static let paper = Color(red: 245 / 255, green: 245 / 255, blue: 247 / 255)
    static let placeholder = Color(red: 229 / 255, green: 229 / 255, blue: 229 / 255)
    /// Caption / meta on light (`#777`) and dark (`#888`).
    static let meta = Color(red: 136 / 255, green: 136 / 255, blue: 136 / 255)
    static let hairline = Color.white.opacity(0.12)

    static let background = ground
    static let surface = black
    static let surfaceElevated = Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)
    /// Primary copy on negative ground.
    static let cream = white
    static let muted = meta
    /// Selected controls invert: white fill, ground type.
    static let amber = white
    static let copper = placeholder
    /// Errors stay system red so they are not mistaken for brand color.
    static let danger = Color(red: 1, green: 59 / 255, blue: 48 / 255)
    static let success = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let stravaOrange = Color(red: 0.99, green: 0.30, blue: 0.01)
}
