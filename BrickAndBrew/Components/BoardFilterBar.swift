import SwiftUI

/// Underline tabs for the crew boards. Selected state is signal orange, not a pill.
struct BoardFilterBar: View {
    let boards: [LeaderboardBoard]
    let selected: LeaderboardBoard
    let action: (LeaderboardBoard) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.lg) {
                ForEach(boards) { board in
                    BoardFilterButton(
                        title: board.title,
                        isSelected: selected == board,
                        action: { action(board) }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct BoardFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Text(title.uppercased())
                    .font(Typography.metadata)
                    .tracking(1.6)
                    .foregroundStyle(isSelected ? Palette.accent : Palette.secondaryText)
                Rectangle()
                    .fill(isSelected ? Palette.accent : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
