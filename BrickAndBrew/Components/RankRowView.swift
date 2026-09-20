import SwiftUI

struct RankRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let board: LeaderboardBoard
    let isCurrentUser: Bool
    let avatars: AvatarCache
    @Binding var breakdownSelection: IndexBreakdownSelection?

    /// Index rows open the point breakdown. Sport boards stay volume-only.
    private var showsBreakdown: Bool {
        board == .overall
    }

    var body: some View {
        if showsBreakdown {
            Button(action: selectRow) {
                rowContent
            }
            .buttonStyle(RankRowButtonStyle())
            .contentShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityHint("Shows how this Index is calculated")
            .accessibilityAddTraits(.isButton)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
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
                // Nested buttons fight the row tap, so Index rows skip the photo preview.
                allowsPreview: showsBreakdown == false,
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

            if showsBreakdown {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.muted)
                    .accessibilityHidden(true)
            }
        }
        .padding(Spacing.md)
        .background(isCurrentUser ? Palette.surfaceElevated : Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.object, style: .continuous)
                .stroke(isCurrentUser ? Palette.amber.opacity(0.45) : Color.clear, lineWidth: 1)
        }
    }

    private func selectRow() {
        Haptics.light()
        breakdownSelection = IndexBreakdownSelection(entry: entry, rank: rank)
    }

    private var accessibilityText: String {
        let badge = entry.streaks.streak(for: board)
        if badge.current > 0 {
            return "Rank \(rank), \(entry.displayName), \(entry.detail(for: board)), \(board.streakKind.title) streak \(Formatters.streakDays(badge.current))"
        }
        return "Rank \(rank), \(entry.displayName), \(entry.detail(for: board))"
    }
}

private struct RankRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
