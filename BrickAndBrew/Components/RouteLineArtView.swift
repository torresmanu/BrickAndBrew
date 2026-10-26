import SwiftUI

/// Clean line-art of a Strava route, or a mounted fallback when the file has no GPS.
struct RouteLineArtView: View {
    var encoded: String?
    var sport: SportKind

    var body: some View {
        let fallback = PolylineCodec.usesFallback(encoded)
        ZStack {
            Canvas { context, size in
                let inset = CGRect(origin: .zero, size: size).insetBy(dx: 5, dy: 5)
                let geo = PolylineCodec.decode(encoded ?? "")
                let drawn = PolylineCodec.points(fitting: geo, in: inset)
                if drawn.count >= 2 {
                    drawRoute(context: context, points: drawn)
                } else {
                    drawFallback(context: context, in: inset, sport: sport)
                }
            }
            if fallback {
                Image(systemName: sport.systemImage)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Palette.paper.opacity(0.42))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
    }

    private func drawRoute(context: GraphicsContext, points: [CGPoint]) {
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(
            path,
            with: .color(Palette.paper.opacity(0.92)),
            style: StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round)
        )
    }

    /// Pool lanes, trainer rings, or a track oval — still a physical object on the mount.
    private func drawFallback(context: GraphicsContext, in rect: CGRect, sport: SportKind) {
        let ink = GraphicsContext.Shading.color(Palette.paper.opacity(0.5))
        let hair = StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
        switch sport {
        case .swim:
            let lanes = 5
            for index in 0..<lanes {
                let y = rect.minY + rect.height * CGFloat(index) / CGFloat(lanes - 1)
                var lane = Path()
                lane.move(to: CGPoint(x: rect.minX + 4, y: y))
                lane.addLine(to: CGPoint(x: rect.maxX - 4, y: y))
                context.stroke(lane, with: ink, style: hair)
            }
            var ends = Path()
            ends.move(to: CGPoint(x: rect.minX + 4, y: rect.minY))
            ends.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY))
            ends.move(to: CGPoint(x: rect.maxX - 4, y: rect.minY))
            ends.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY))
            context.stroke(ends, with: ink, style: hair)
        case .ride:
            for inset in [0.0, 0.22, 0.44] {
                let ring = rect.insetBy(dx: rect.width * inset, dy: rect.height * inset)
                context.stroke(
                    Path(roundedRect: ring, cornerRadius: min(ring.width, ring.height) * 0.45),
                    with: ink,
                    style: hair
                )
            }
        case .run, .other:
            context.stroke(
                Path(ellipseIn: rect.insetBy(dx: 3, dy: 6)),
                with: ink,
                style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
            )
        }
    }
}
