import SwiftUI

/// Receipt sheet for one teammate's board score: sources, uncovered training, and grind tax.
struct ScoreBreakdownView: View {
    let entry: LeaderboardEntry
    let board: LeaderboardBoard
    let isCurrentUser: Bool
    let avatars: AvatarCache

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    hero
                    if breakdown.isEmpty {
                        empty
                    } else {
                        receipt
                        footnote
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                }
            }
            .brandGlassSheetContent()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .brandGlassSheet()
    }

    private var breakdown: ScoreBreakdown {
        entry.scoreBreakdown(for: board)
    }

    private var navigationTitle: String {
        board == .overall ? "Index breakdown" : "\(board.title) breakdown"
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                AvatarView(
                    userId: entry.userId,
                    displayName: entry.displayName,
                    size: 44,
                    cache: avatars
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(heroName.uppercased())
                        .font(Typography.label)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                    Text(heroMeta)
                        .font(Typography.metadata)
                        .foregroundStyle(Palette.secondaryText)
                        .tracking(1.2)
                }
            }
            MetricView(
                value: Formatters.pointsValue(breakdown.total),
                unit: "PTS",
                valueFont: Typography.displayL,
                valueColor: isCurrentUser ? Palette.accent : Palette.text
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroAccessibility)
    }

    private var empty: some View {
        EmptyStateView(
            title: "Nothing on the board",
            message: breakdown.emptyMessage,
            systemImage: "chart.bar"
        )
    }

    private var receipt: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "How this score is built")
            ForEach(breakdown.lines, content: BreakdownLineView.init)
            Hairline()
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(board.title.uppercased())
                    .font(Typography.label)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.text)
                Spacer(minLength: Spacing.sm)
                Text(Formatters.signedPointsValue(breakdown.total))
                    .font(Typography.displayM)
                    .foregroundStyle(isCurrentUser ? Palette.accent : Palette.text)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(board.title), \(Formatters.points(breakdown.total))")
        }
    }

    private var footnote: some View {
        Text(breakdown.footnote)
            .font(Typography.body)
            .foregroundStyle(Palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(breakdown.footnote)
    }

    private var heroName: String {
        isCurrentUser ? "You" : entry.displayName
    }

    private var heroMeta: String {
        "\(board.title.uppercased())  ·  THIS SEASON"
    }

    private var heroAccessibility: String {
        "\(heroName). \(board.title). \(Formatters.points(breakdown.total)). This season."
    }

    private func close() {
        dismiss()
    }
}

private struct BreakdownLineView: View {
    let line: ScoreBreakdown.Line

    init(_ line: ScoreBreakdown.Line) {
        self.line = line
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.title.uppercased())
                    .font(Typography.label)
                    .foregroundStyle(lineColor)
                Text(line.detail.uppercased())
                    .font(Typography.metadata)
                    .foregroundStyle(Palette.secondaryText)
                    .tracking(1.2)
            }
            Spacer(minLength: Spacing.sm)
            Text(Formatters.signedPointsValue(line.points))
                .font(Typography.displayM)
                .foregroundStyle(lineColor)
                .monospacedDigit()
        }
        .overlay(alignment: .bottom) {
            Hairline()
                .padding(.top, Spacing.sm)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(line.title), \(line.detail), \(Formatters.points(line.points))")
    }

    private var lineColor: Color {
        switch line.kind {
        case .beers: Palette.accent
        case .uncovered, .tax: Palette.danger
        case .training: Palette.text
        }
    }
}
