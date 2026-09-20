import SwiftUI

struct RankRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let board: LeaderboardBoard
    let isCurrentUser: Bool
    let avatars: AvatarCache
    let onSelect: (LeaderboardEntry) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Button(action: select) {
                Text(Formatters.rank(rank))
                    .font(Typography.displayM)
                    .foregroundStyle(rankColor)
                    .frame(width: 56, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)

            AvatarView(
                userId: entry.userId,
                displayName: entry.displayName,
                size: 40,
                cache: avatars
            )

            Button(action: select) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Spacing.xs) {
                            Text(entry.displayName.uppercased())
                                .font(Typography.label)
                                .fontWeight(.semibold)
                                .foregroundStyle(Palette.text)
                                .lineLimit(1)
                            StreakBadgeView(
                                kind: board.streakKind,
                                streak: entry.streaks.streak(for: board),
                                symbolName: board.sport?.systemImage
                            )
                            .layoutPriority(1)
                        }
                        Text(entry.detail(for: board).uppercased())
                            .font(Typography.metadata)
                            .foregroundStyle(Palette.secondaryText)
                            .tracking(1.2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    MetricView(
                        value: Formatters.pointsValue(entry.points(for: board)),
                        unit: "PTS",
                        valueFont: Typography.title,
                        unitFont: Typography.metadata,
                        valueColor: isCurrentUser ? Palette.accent : Palette.text,
                        unitColor: Palette.secondaryText,
                        alignment: .trailing
                    )
                    .layoutPriority(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityHint("Shows how this score is calculated")
            .accessibilityAddTraits(.isButton)
        }
        .padding(.vertical, Spacing.sm)
        .overlay(alignment: .bottom) {
            Hairline()
        }
    }

    private func select() {
        onSelect(entry)
    }

    private var rankColor: Color {
        isCurrentUser ? Palette.accent : Palette.text
    }

    private var accessibilityText: String {
        let badge = entry.streaks.streak(for: board)
        if badge.current > 0 {
            return "Rank \(rank), \(entry.displayName), \(entry.detail(for: board)), \(board.streakKind.title) streak \(Formatters.streakDays(badge.current))"
        }
        return "Rank \(rank), \(entry.displayName), \(entry.detail(for: board))"
    }
}
