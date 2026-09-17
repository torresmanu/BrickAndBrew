import SwiftUI

struct RankRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let board: LeaderboardBoard
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(rank <= 3 ? Palette.amber : Palette.muted)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.headline)
                    .foregroundStyle(Palette.cream)
                Text(entry.detail(for: board))
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
            }

            Spacer()

            Text(Formatters.points(entry.points(for: board)))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.amber)
        }
        .padding(Spacing.md)
        .background(isCurrentUser ? Palette.surfaceElevated : Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isCurrentUser ? Palette.amber.opacity(0.45) : Color.clear, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        "Rank \(rank), \(entry.displayName), \(entry.detail(for: board))"
    }
}
