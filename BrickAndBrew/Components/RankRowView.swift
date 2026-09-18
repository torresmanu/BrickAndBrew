import SwiftUI

struct RankRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let board: LeaderboardBoard
    let isCurrentUser: Bool
    let avatars: AvatarCache

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(rank <= 3 ? Palette.amber : Palette.muted)
                .frame(width: 28, alignment: .center)
                .accessibilityHidden(true)

            AvatarView(
                userId: entry.userId,
                displayName: entry.displayName,
                size: 40,
                cache: avatars
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(entry.displayName)
                        .font(.headline)
                        .foregroundStyle(Palette.cream)
                        .lineLimit(1)
                    StreakBadgeView(
                        kind: board.streakKind,
                        streak: entry.streaks.streak(for: board)
                    )
                    .layoutPriority(1)
                }
                Text(entry.detail(for: board))
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)

            Text(Formatters.points(entry.points(for: board)))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.amber)
                .layoutPriority(1)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .background(isCurrentUser ? Palette.surfaceElevated : Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.object, style: .continuous)
                .stroke(isCurrentUser ? Palette.amber.opacity(0.45) : Color.clear, lineWidth: 1)
        }
    }

    private var accessibilityText: String {
        let badge = entry.streaks.streak(for: board)
        if badge.current > 0 {
            return "Rank \(rank), \(entry.displayName), \(entry.detail(for: board)), \(board.streakKind.title) streak \(Formatters.streakDays(badge.current))"
        }
        return "Rank \(rank), \(entry.displayName), \(entry.detail(for: board))"
    }
}
