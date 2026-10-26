import SwiftUI

/// Shareable medal card. Laid out at `format.designSize` so ImageRenderer can snapshot it.
struct FinisherCardView: View {
    let finish: TriathlonFinish
    var format: FinisherCardFormat = .square

    var body: some View {
        ZStack {
            background
            insetFrame
            content
        }
        .frame(width: format.designSize.width, height: format.designSize.height)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var background: some View {
        LinearGradient(
            colors: [Palette.inkElevated, Palette.ink, Palette.inkDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Rectangle()
                .fill(Palette.paper.opacity(0.04))
                .frame(width: format.designSize.width * 0.42)
                .rotationEffect(.degrees(-18))
                .offset(x: format.designSize.width * 0.18, y: -40)
        }
    }

    private var insetFrame: some View {
        Rectangle()
            .stroke(Palette.paper.opacity(0.2), lineWidth: 1)
            .padding(format.isStory ? 22 : 14)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: format.isStory ? 28 : 6)
            medal
            Spacer(minLength: format.isStory ? 28 : 6)
            titleBlock
            Spacer(minLength: format.isStory ? 22 : 6)
            legs
            Spacer(minLength: format.isStory ? 18 : 6)
            totalRow
            if format.isStory {
                Spacer(minLength: 16)
                footer
            }
        }
        .padding(.horizontal, format.isStory ? 28 : 20)
        .padding(.vertical, format.isStory ? 36 : 16)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(FinisherCopy.raceKicker)
                .font(Typography.metadata)
                .foregroundStyle(Palette.paper)
                .tracking(2.2)
            Spacer(minLength: 8)
            Text(format.isStory ? "RUN / RIDE / SWIM" : Formatters.raceDate(finish.startDate))
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var medal: some View {
        FinisherMedalView()
            .frame(width: medalSide, height: medalSide)
            .frame(maxWidth: .infinity)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(FinisherCopy.raceTitle)
                .font(Typography.condensed(size: format.isStory ? 44 : 28, italic: true, relativeTo: .largeTitle))
                .foregroundStyle(Palette.paper)
                .tracking(-0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(FinisherCopy.raceSubtitle)
                .font(Typography.condensed(size: format.isStory ? 44 : 28, italic: true, relativeTo: .largeTitle))
                .foregroundStyle(Palette.paper)
                .tracking(-0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(FinisherCopy.athleteLine(finish))
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.6)
                .padding(.top, format.isStory ? 8 : 4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legs: some View {
        VStack(spacing: format.isStory ? 6 : 4) {
            ForEach(TriathlonDetector.raceOrder, id: \.self) { sport in
                legRow(sport)
            }
        }
    }

    private func legRow(_ sport: SportKind) -> some View {
        let activity = finish.activity(for: sport)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(sport.title.uppercased())
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.6)
                .frame(width: 52, alignment: .leading)
            Text(Formatters.raceDistance(meters: activity.distanceMeters, sport: sport).uppercased())
                .font(Typography.plexMono(size: 12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(Palette.paper)
            Spacer(minLength: 8)
            Text(Formatters.raceTime(activity.movingTimeSeconds))
                .font(Typography.plexMono(size: 12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(Palette.paper)
                .monospacedDigit()
        }
    }

    private var totalRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(FinisherCopy.totalLabel)
                .font(Typography.metadata)
                .foregroundStyle(Palette.accent)
                .tracking(2)
            Spacer(minLength: 8)
            Text(Formatters.raceTime(finish.elapsedSeconds))
                .font(Typography.condensed(size: format.isStory ? 40 : 24, italic: false, relativeTo: .title))
                .foregroundStyle(Palette.paper)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var footer: some View {
        Text(Formatters.raceDate(finish.startDate))
            .font(Typography.metadata)
            .foregroundStyle(Palette.secondaryText)
            .tracking(1.8)
    }

    private var medalSide: CGFloat {
        format.isStory ? 196 : 108
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

#Preview("Feed card") {
    FinisherCardView(finish: .preview, format: .square)
}

#Preview("Story card") {
    FinisherCardView(finish: .preview, format: .story)
}
