import SwiftUI
import UIKit

/// Type tokens. Display is Barlow Condensed (heavy, italic for brand). Body is IBM Plex Sans.
/// Metadata and metrics use IBM Plex Mono so numbers stay technical next to emotional display type.
enum Typography {
    static let displayXL = condensed(size: 72, italic: true, relativeTo: .largeTitle)
    static let displayL = condensed(size: 48, italic: true, relativeTo: .largeTitle)
    static let displayM = condensed(size: 36, italic: true, relativeTo: .title)
    /// Large italic screen title. A step up from the 32pt UIKit navigation large title.
    static let navigationLarge = condensed(size: 36, italic: true, relativeTo: .largeTitle)
    static let title = condensed(size: 28, italic: false, relativeTo: .title2)
    static let wordmark = condensed(size: 40, italic: true, relativeTo: .largeTitle)
    static let heading1 = title
    static let heading2 = condensed(size: 22, italic: false, relativeTo: .title3)
    static let body = plexSans(size: 16, weight: .regular, relativeTo: .body)
    static let label = plexSans(size: 13, weight: .medium, relativeTo: .subheadline)
    static let caption = plexSans(size: 12, weight: .regular, relativeTo: .caption)
    static let metadata = plexMono(size: 11, weight: .regular, relativeTo: .caption2)
    static let metric = condensed(size: 64, italic: false, relativeTo: .largeTitle)
    static let metricUnit = condensed(size: 16, italic: false, relativeTo: .caption)

    static func condensed(size: CGFloat, italic: Bool, relativeTo textStyle: Font.TextStyle) -> Font {
        Font.custom(italic ? "BarlowCondensed-ExtraBoldItalic" : "BarlowCondensed-ExtraBold", size: size, relativeTo: textStyle)
    }

    static func plexSans(size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) -> Font {
        Font.custom(sansName(for: weight), size: size, relativeTo: textStyle)
    }

    static func plexMono(size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) -> Font {
        Font.custom(monoName(for: weight), size: size, relativeTo: textStyle)
    }

    /// UIKit chrome (nav / tab) needs the PostScript name, not a SwiftUI Font.
    static func uiDisplay(size: CGFloat, italic: Bool = false) -> UIFont {
        let name = italic ? "BarlowCondensed-ExtraBoldItalic" : "BarlowCondensed-ExtraBold"
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .heavy)
    }

    static func uiBody(size: CGFloat, weight: Font.Weight = .regular) -> UIFont {
        UIFont(name: sansName(for: weight), size: size) ?? .systemFont(ofSize: size)
    }

    private static func sansName(for weight: Font.Weight) -> String {
        if weight == .bold || weight == .semibold || weight == .heavy {
            return "IBMPlexSans-Bold"
        }
        if weight == .medium {
            return "IBMPlexSans-Medm"
        }
        return "IBMPlexSans"
    }

    private static func monoName(for weight: Font.Weight) -> String {
        if weight == .bold || weight == .semibold || weight == .heavy {
            return "IBMPlexMono-Bold"
        }
        if weight == .medium {
            return "IBMPlexMono-Medm"
        }
        return "IBMPlexMono-Regular"
    }
}
