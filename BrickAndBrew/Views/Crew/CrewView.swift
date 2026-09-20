import SwiftUI

struct CrewView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: CrewViewModel?
    @State private var isScoringGuidePresented = false

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("How points are calculated", systemImage: "info.circle", action: showScoringGuide)
                }
            }
            .sheet(isPresented: $isScoringGuidePresented) {
                ScoringGuideView()
            }
        }
        .onAppear(perform: ensureViewModel)
        .task(id: viewModel != nil) {
            await viewModel?.load(forceSync: true)
        }
        .onChange(of: session.profile?.displayName) { _, name in
            guard let name, let userId = session.profile?.id else { return }
            viewModel?.applyDisplayName(name, userId: userId)
        }
    }

    private func showScoringGuide() {
        Haptics.light()
        isScoringGuidePresented = true
    }

    private func ensureViewModel() {
        if viewModel == nil {
            viewModel = CrewViewModel(session: session)
        }
    }
}

private struct CrewLoadedView: View {
    @Environment(AppSession.self) private var session
    @Bindable var viewModel: CrewViewModel
    @State private var breakdownSelection: IndexBreakdownSelection?

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
        .sheet(item: $breakdownSelection, content: breakdownSheet)
    }

    private func breakdownSheet(_ selection: IndexBreakdownSelection) -> IndexBreakdownView {
        IndexBreakdownView(
            rank: selection.rank,
            entry: selection.entry,
            isCurrentUser: selection.entry.userId == viewModel.currentUserId,
            avatars: session.avatars
        )
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
        List {
            Section {
                boardSection
            }
            Section("Crew pints") {
                pintSection
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var boardSection: some View {
        switch viewModel.state {
        case .loading:
            LoadingView(message: "Crunching swim, bike, run, and beers…")
                .frame(minHeight: 180)
                .listRowInsets(listInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        case .empty:
            EmptyStateView(
                title: "The board is empty",
                message: "Log a beer or sync Strava to put someone on the board.",
                systemImage: "trophy",
                actionTitle: "Refresh",
                action: retry
            )
            .frame(minHeight: 220)
            .listRowInsets(listInsets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        case .failed(let message):
            ErrorStateView(message: message, retry: retry)
                .frame(minHeight: 220)
                .listRowInsets(listInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        case .loaded:
            ForEach(Array(viewModel.ranked.enumerated()), id: \.element.id) { index, entry in
                RankRowView(
                    rank: index + 1,
                    entry: entry,
                    board: viewModel.board,
                    isCurrentUser: entry.userId == viewModel.currentUserId,
                    avatars: session.avatars,
                    breakdownSelection: $breakdownSelection
                )
                .listRowInsets(listInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    @ViewBuilder
    private var pintSection: some View {
        switch viewModel.pintFeed {
        case .loading:
            LoadingView(message: "Loading crew pints…")
                .frame(minHeight: 140)
                .listRowInsets(listInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        case .empty:
            EmptyStateView(
                title: "No pint photos yet",
                message: "Snap a pint from Log and it shows up here.",
                icon: PintSymbol()
            )
            .frame(minHeight: 180)
            .listRowInsets(listInsets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        case .failed(let message):
            ErrorStateView(message: message, retry: retryPintFeed)
                .frame(minHeight: 180)
                .listRowInsets(listInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        case .loaded(let photos):
            ForEach(photos) { photo in
                CrewPintRowView(
                    photo: photo,
                    displayName: viewModel.displayName(for: photo.userId),
                    avatars: session.avatars,
                    photos: session.beerPhotos
                )
                .listRowInsets(listInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    private var listInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: Spacing.md, bottom: 6, trailing: Spacing.md)
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }

    private func retryPintFeed() {
        Task {
            await viewModel.retryPintFeed()
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
                .font(Typography.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .foregroundStyle(isSelected ? Palette.background : Palette.cream)
                .background(isSelected ? Palette.amber : Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
