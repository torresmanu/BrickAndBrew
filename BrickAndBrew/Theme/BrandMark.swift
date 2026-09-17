import SwiftUI

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
