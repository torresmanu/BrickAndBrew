import SwiftUI

struct CrewView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: CrewViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    CrewLoadedView(viewModel: viewModel)
                } else {
                    LoadingView(message: "Loading the crew board…")
                }
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Crew")
            .toolbarBackground(Palette.background, for: .navigationBar)
        }
        .onAppear(perform: ensureViewModel)
        .task(id: viewModel != nil) {
            await viewModel?.load(forceSync: true)
        }
    }

    private func ensureViewModel() {
        if viewModel == nil {
            viewModel = CrewViewModel(session: session)
        }
    }
}

private struct CrewLoadedView: View {
    @Bindable var viewModel: CrewViewModel

    var body: some View {
        VStack(spacing: Spacing.md) {
            boardPicker
            if let staleMessage = viewModel.staleMessage {
                Text(staleMessage)
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
            }
            content
        }
        .padding(.top, Spacing.sm)
        .refreshable(action: refresh)
    }

    private var boardPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(LeaderboardBoard.allCases) { board in
                    BoardChip(
                        title: board.title,
                        isSelected: viewModel.board == board,
                        action: { viewModel.selectBoard(board) }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingView(message: "Crunching swim, bike, run, and beers…")
        case .empty:
            EmptyStateView(
                title: "The board is empty",
                message: "Log a beer or sync Strava to put someone on the board.",
                systemImage: "trophy",
                actionTitle: "Refresh",
                action: retry
            )
        case .failed(let message):
            ErrorStateView(message: message, retry: retry)
        case .loaded:
            List {
                ForEach(Array(viewModel.ranked.enumerated()), id: \.element.id) { index, entry in
                    RankRowView(
                        rank: index + 1,
                        entry: entry,
                        board: viewModel.board,
                        isCurrentUser: entry.userId == viewModel.currentUserId
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: Spacing.md, bottom: 6, trailing: Spacing.md))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }

    private func refresh() async {
        await viewModel.load(forceSync: true)
    }
}

private struct BoardChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .foregroundStyle(isSelected ? Palette.background : Palette.cream)
                .background(isSelected ? Palette.amber : Palette.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
