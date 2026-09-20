import SwiftUI
import UIKit

/// Architectural B-monogram from Brand Labs Finalist B (Figma node 35:821).
/// Drawn on the 320-unit grid so padding and bowl radii stay faithful at every size.

/// Architectural B-monogram from Brand Labs Finalist B (Figma node 35:821).
/// Drawn on the 320-unit grid so padding and bowl radii stay faithful at every size.
struct BrandMonogram: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let scale = side / 320
        let originX = rect.midX - side / 2
        let originY = rect.midY - side / 2

        var path = Path()
        path.addPath(rightStadium(originX: originX, originY: originY, scale: scale, x: 0, y: 6, width: 240, height: 120))
        path.addRect(CGRect(
            x: originX + 0 * scale,
            y: originY + 142 * scale,
            width: 200 * scale,
            height: 16 * scale
        ))
        path.addPath(rightStadium(originX: originX, originY: originY, scale: scale, x: 0, y: 174, width: 280, height: 140))
        return path
    }

    /// Top and bottom bowls are stadiums: square left, full-radius right.
    private func rightStadium(
        originX: CGFloat,
        originY: CGFloat,
        scale: CGFloat,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> Path {
        let rect = CGRect(
            x: originX + x * scale,
            y: originY + y * scale,
            width: width * scale,
            height: height * scale
        )
        let radius = rect.height / 2
        var path = Path()
        path.addRoundedRect(
            in: rect,
            cornerRadii: RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: 0,
                bottomTrailing: radius,
                topTrailing: radius
            )
        )
        return path
    }
}

struct BrandMark: View {
    var body: some View {
        BrandMonogram()
            .aspectRatio(1, contentMode: .fit)
            .accessibilityLabel("Brick & Brew")
    }
}

/// Italic condensed wordmark plus the four-discipline lockup.
struct BrandWordmark: View {
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: Spacing.xs) {
            Text("BRICK & BREW™")
                .font(Typography.wordmark)
                .foregroundStyle(Palette.paper)
                .tracking(-1)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("RUN  /  RIDE  /  SWIM  /  BEER")
                .font(Typography.metadata)
                .foregroundStyle(Palette.paper)
                .tracking(2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Brick & Brew. Run, ride, swim, beer.")
    }
}

/// Beer mug emoji. Apple has no pint SF Symbol; mug.fill is a coffee cup.
struct PintSymbol: View {
    var body: some View {
        Text("🍺")
            .accessibilityHidden(true)
    }
}

extension PintSymbol {
    /// Tab bars flatten icons to template glyphs. Original rendering keeps the emoji in color.
    static let tabBarImage: UIImage = renderBeerEmoji(pointSize: 25)

    private static func renderBeerEmoji(pointSize: CGFloat) -> UIImage {
        let emoji = "🍺" as NSString
        let font = UIFont.systemFont(ofSize: pointSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = emoji.size(withAttributes: attributes)
        let side = ceil(max(textSize.width, textSize.height)) + 2
        let size = CGSize(width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let origin = CGPoint(
                x: (side - textSize.width) / 2,
                y: (side - textSize.height) / 2
            )
            emoji.draw(at: origin, withAttributes: attributes)
        }
        return image.withRenderingMode(.alwaysOriginal)
    }
}

extension StreakKind {
    @ViewBuilder
    var icon: some View {
        switch self {
        case .pint:
            PintSymbol()
        case .brick:
            Image(systemName: "figure.run")
        case .brickAndBrew:
            Image(systemName: "flag.checkered")
        }
    }
}
