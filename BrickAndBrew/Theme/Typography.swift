import SwiftUI

/// Type from Finalist B: IBM Plex Sans Bold wordmark, Regular body. Tracking is tight on titles.
enum Typography {
    static let wordmark = plex(size: 32, weight: .bold, relativeTo: .largeTitle)
    static let heading1 = plex(size: 32, weight: .bold, relativeTo: .largeTitle)
    static let heading2 = plex(size: 24, weight: .bold, relativeTo: .title2)
    static let body = plex(size: 16, weight: .regular, relativeTo: .body)
    static let caption = plex(size: 12, weight: .regular, relativeTo: .caption)

    static func plex(size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) -> Font {
        Font.custom(fontName(for: weight), size: size, relativeTo: textStyle)
    }

    private static func fontName(for weight: Font.Weight) -> String {
        if weight == .bold || weight == .semibold || weight == .heavy {
            return "IBMPlexSans-Bold"
        }
        if weight == .medium {
            return "IBMPlexSans-Medm"
        }
        return "IBMPlexSans"
    }
}
