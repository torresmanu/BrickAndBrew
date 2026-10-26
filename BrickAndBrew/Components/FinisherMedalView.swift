import SwiftUI

/// Gold disc inspired by a framed race medal: concentric ribs, a dark monogram, no photo.
struct FinisherMedalView: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(Palette.medalGoldShadow.opacity(0.55))
                    .offset(y: side * 0.035)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Palette.medalGoldHighlight,
                                Palette.medalGold,
                                Palette.medalGoldShadow
                            ],
                            center: .topLeading,
                            startRadius: side * 0.05,
                            endRadius: side * 0.72
                        )
                    )

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Palette.medalGoldHighlight,
                                Palette.medalGold,
                                Palette.medalGoldShadow
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(3, side * 0.035)
                    )

                FinisherMedalRibs()
                    .opacity(0.22)
                    .clipShape(Circle())
                    .padding(side * 0.06)

                Circle()
                    .stroke(Palette.medalGoldHighlight.opacity(0.65), lineWidth: max(1, side * 0.012))
                    .padding(side * 0.11)

                BrandMonogram()
                    .fill(Palette.ink.opacity(0.58))
                    .padding(side * 0.22)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Brushed-metal rings. Kept as strokes so ImageRenderer can snapshot them.
private struct FinisherMedalRibs: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2
            let step = max(3, maxRadius * 0.045)
            var radius = maxRadius * 0.2
            while radius < maxRadius * 0.94 {
                var path = Path()
                path.addEllipse(
                    in: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                )
                context.stroke(path, with: .color(Color.white.opacity(0.4)), lineWidth: 1)
                radius += step
            }
        }
    }
}
