import SwiftUI

/// Underline tabs for the crew boards. Selected state is signal orange, not a pill.
struct BoardFilterBar: View {
    let boards: [LeaderboardBoard]
    let selected: LeaderboardBoard
    let action: (LeaderboardBoard) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.lg) {
                    ForEach(boards) { board in
                        BoardFilterButton(
                            title: board.title,
                            isSelected: selected == board,
                            action: { action(board) }
                        )
                        .id(board.id)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .animation(Motion.sport, value: selected)
            }
            .onAppear {
                proxy.scrollTo(selected.id, anchor: .center)
            }
            .onChange(of: selected) { _, board in
                withAnimation(Motion.sport) {
                    proxy.scrollTo(board.id, anchor: .center)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("Swipe the board left or right to switch sports")
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
