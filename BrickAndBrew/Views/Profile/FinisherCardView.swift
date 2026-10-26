import SwiftUI

/// Shareable medal card as a 3D gallery shadow box. ImageRenderer-safe: no SceneKit, no blur.
struct FinisherCardView: View {
    let finish: TriathlonFinish
    var format: FinisherCardFormat = .square

    var body: some View {
        ZStack {
            wall
            VStack(spacing: 0) {
                hangingCable
                shadowBox
            }
            .padding(.horizontal, format.isStory ? 28 : 22)
            .padding(.top, format.isStory ? 48 : 30)
            .padding(.bottom, format.isStory ? 44 : 32)
        }
        .frame(width: format.designSize.width, height: format.designSize.height)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var wall: some View {
        LinearGradient(
            colors: [Palette.galleryWall, Palette.galleryWallDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Single drop wire, as in a hanging gallery frame.
    private var hangingCable: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.22), Color(white: 0.38), Color(white: 0.18)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 1.4, height: format.isStory ? 28 : 18)
    }

    /// Fake box thickness on the right and bottom, then a slight perspective tilt.
    private var shadowBox: some View {
        ZStack(alignment: .bottomTrailing) {
            frameThickness
            boxFace
                .padding(.trailing, 8)
                .padding(.bottom, 11)
        }
        .rotation3DEffect(
            .degrees(5.2),
            axis: (x: 0.18, y: 1, z: 0.05),
            anchor: .center,
            perspective: 0.52
        )
        .shadow(color: Color.black.opacity(0.42), radius: 14, x: 8, y: 16)
    }

    private var frameThickness: some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [Color(white: 0.16), Palette.frameEdge],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 8)
            }
            .padding(.top, 12)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [Color(white: 0.14), Palette.frameEdge],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 11)
            }
            .padding(.leading, 8)
        }
    }

    private var boxFace: some View {
        ZStack {
            Palette.frameMetal
            // Outer lip catch-light, then a darker inner rebate.
            Rectangle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.04), Color.black.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .padding(1.5)
            Rectangle()
                .stroke(Color.black.opacity(0.55), lineWidth: 1)
                .padding(5)
            ZStack {
                Palette.mountBoard
                mountRibs
                mountContent
                wellShadow
                glass
            }
            .padding(format.isStory ? 12 : 10)
        }
    }

    /// Vertical grain on the mount, like a dark striped display board.
    private var mountRibs: some View {
        HStack(spacing: 5) {
            ForEach(0..<18, id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.018))
                    .frame(width: 1)
            }
        }
        .allowsHitTesting(false)
    }

    private var mountContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(FinisherCopy.raceKicker)
                .font(Typography.metadata)
                .foregroundStyle(Palette.paper.opacity(0.72))
                .tracking(2.0)
            Spacer(minLength: format.isStory ? 16 : 6)
            headerRow
            Spacer(minLength: format.isStory ? 18 : 8)
            routeRow
            Spacer(minLength: format.isStory ? 14 : 6)
            footerRow
        }
        .padding(format.isStory ? 16 : 11)
    }

    private var headerRow: some View {
        Group {
            if format.isStory {
                VStack(alignment: .leading, spacing: 14) {
                    titleBlock
                    FinisherMedalView()
                        .frame(width: medalSide, height: medalSide)
                        .rotationEffect(.degrees(-5.5))
                        .shadow(color: Color.black.opacity(0.58), radius: 7, x: 3, y: 6)
                        .frame(maxWidth: .infinity)
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    titleBlock
                    FinisherMedalView()
                        .frame(width: medalSide, height: medalSide)
                        .rotationEffect(.degrees(-5.5))
                        .shadow(color: Color.black.opacity(0.58), radius: 7, x: 3, y: 6)
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(FinisherCopy.raceTitle)
                .font(Typography.condensed(size: format.isStory ? 42 : 26, italic: true, relativeTo: .largeTitle))
                .foregroundStyle(Palette.paper)
                .tracking(-0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(FinisherCopy.raceSubtitle)
                .font(Typography.condensed(size: format.isStory ? 42 : 26, italic: true, relativeTo: .largeTitle))
                .foregroundStyle(Palette.paper)
                .tracking(-0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(FinisherCopy.athleteLine(finish))
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.4)
                .padding(.top, 6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var routeRow: some View {
        HStack(alignment: .top, spacing: 7) {
            FinisherRoutePlate(activity: finish.swim, tilt: -2.2, tall: format.isStory)
            FinisherRoutePlate(activity: finish.ride, tilt: 1.4, tall: format.isStory)
            FinisherRoutePlate(activity: finish.run, tilt: -0.9, tall: format.isStory)
        }
    }

    private var footerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(FinisherCopy.totalLabel)
                .font(Typography.metadata)
                .foregroundStyle(Palette.accent)
                .tracking(1.8)
            Text(Formatters.raceTime(finish.elapsedSeconds))
                .font(Typography.condensed(size: format.isStory ? 28 : 18, italic: false, relativeTo: .title))
                .foregroundStyle(Palette.paper)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 8)
            Text(Formatters.raceDate(finish.startDate))
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// Recessed well: darken the inner edges so the mount sits behind the frame lip.
    private var wellShadow: some View {
        ZStack {
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.black.opacity(0.46), Color.clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 18)
                Spacer(minLength: 0)
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 20)
            }
            HStack(spacing: 0) {
                LinearGradient(colors: [Color.black.opacity(0.3), Color.clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 14)
                Spacer(minLength: 0)
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.34)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 16)
            }
        }
        .allowsHitTesting(false)
    }

    /// Glass sheet: a soft sheen plus a window-like reflection streak.
    private var glass: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color.white.opacity(0.12), Color.clear, Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Rectangle()
                .fill(Color.white.opacity(0.09))
                .frame(width: format.designSize.width * 0.16)
                .rotationEffect(.degrees(-22))
                .offset(x: format.isStory ? 40 : 24, y: -34)
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: format.designSize.width * 0.07)
                .rotationEffect(.degrees(-22))
                .offset(x: format.isStory ? 92 : 64, y: -40)
        }
        .allowsHitTesting(false)
    }

    private var medalSide: CGFloat {
        format.isStory ? 112 : 76
    }

    private var accessibilityText: String {
        let legs = TriathlonDetector.raceOrder.map { sport in
            let activity = finish.activity(for: sport)
            return "\(sport.title) \(Formatters.raceDistance(meters: activity.distanceMeters, sport: sport)) in \(Formatters.raceTime(activity.movingTimeSeconds))"
        }
        return [
            FinisherCopy.raceKicker,
            FinisherCopy.raceTitle,
            FinisherCopy.raceSubtitle,
            FinisherCopy.athleteLine(finish),
            legs.joined(separator: ". "),
            "\(FinisherCopy.totalLabel) \(Formatters.raceTime(finish.elapsedSeconds))",
            Formatters.raceDate(finish.startDate)
        ].joined(separator: ". ")
    }
}

/// One mounted print: route line-art (or indoor fallback) plus discipline stats.
private struct FinisherRoutePlate: View {
    let activity: Activity
    var tilt: Double
    var tall: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RouteLineArtView(encoded: activity.summaryPolyline, sport: activity.sport)
                .frame(maxWidth: .infinity)
                .frame(height: tall ? 76 : 46)
            Text(activity.sport.title.uppercased())
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.3)
            Text(statsLine)
                .font(Typography.plexMono(size: 8, weight: .medium, relativeTo: .caption2))
                .foregroundStyle(Palette.paper.opacity(0.86))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Palette.paper.opacity(0.055))
        .overlay {
            Rectangle()
                .stroke(Palette.paper.opacity(0.18), lineWidth: 0.8)
        }
        .shadow(color: Color.black.opacity(0.5), radius: 3.5, x: 1.5, y: 3.5)
        .rotationEffect(.degrees(tilt))
    }

    private var statsLine: String {
        let distance = Formatters.raceDistance(meters: activity.distanceMeters, sport: activity.sport)
        let time = Formatters.raceTime(activity.movingTimeSeconds)
        return "\(distance)  \(time)".uppercased()
    }
}

#Preview("Feed card") {
    FinisherCardView(finish: .preview, format: .square)
}

#Preview("Story card") {
    FinisherCardView(finish: .preview, format: .story)
}

#Preview("Indoor fallback") {
    FinisherCardView(finish: .previewWithoutGPS, format: .square)
}

#Preview("Pool swim fallback") {
    FinisherCardView(finish: .previewPoolSwim, format: .square)
}
