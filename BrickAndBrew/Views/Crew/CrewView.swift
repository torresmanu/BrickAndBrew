import SwiftUI

struct CrewView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: CrewViewModel?
    @State private var isScoringGuidePresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CrewNavigationHeader(action: showScoringGuide)
                Group {
                    if let viewModel {
                        CrewLoadedView(viewModel: viewModel)
                    } else {
                        LoadingView(message: "Loading the crew board…")
                    }
                }
            }
            .background(Palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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

/// Large italic Crew title on the left, scoring info on the right — one row.
private struct CrewNavigationHeader: View {
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Text("Crew")
                .font(Typography.navigationLarge)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.sm)
            ScoringGuideButton(action: action)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xxs)
        .background(Palette.background)
    }
}

/// Icon-only scoring guide control. Uses system liquid glass on iOS 26, matching toolbar buttons.
private struct ScoringGuideButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            iconButton
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
        } else {
            iconButton
        }
    }

    private var iconButton: some View {
        Button("How points are calculated", systemImage: "info.circle", action: action)
            .labelStyle(.iconOnly)
    }
}

private struct CrewLoadedView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: CrewViewModel
    @State private var selectedBreakdown: ScoreBreakdownSelection?

    var body: some View {
        VStack(spacing: 0) {
            BoardFilterBar(
                boards: LeaderboardBoard.allCases,
                selected: viewModel.board,
                action: selectBoardFromFilter
            )
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)

            if let staleMessage = viewModel.staleMessage {
                Text(staleMessage.uppercased())
                    .font(Typography.metadata)
                    .foregroundStyle(Palette.secondaryText)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xs)
            }

            // Horizontal pages for Index / Swim / Bike / Run / Beers. The filter bar stays pinned.
            TabView(selection: $viewModel.board) {
                ForEach(LeaderboardBoard.allCases) { board in
                    CrewBoardPage(
                        board: board,
                        viewModel: viewModel,
                        onSelectEntry: { entry in showBreakdown(entry, board: board) },
                        onRetry: retry,
                        onRetryPintFeed: retryPintFeed,
                        onRefresh: refresh
                    )
                    .tag(board)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Palette.background)
            .onChange(of: viewModel.board) { oldBoard, newBoard in
                guard oldBoard != newBoard else { return }
                Haptics.light()
            }
        }
        .sheet(item: $selectedBreakdown) { selection in
            ScoreBreakdownView(
                entry: selection.entry,
                board: selection.board,
                isCurrentUser: selection.entry.userId == viewModel.currentUserId,
                avatars: session.avatars
            )
        }
    }

    private func selectBoardFromFilter(_ board: LeaderboardBoard) {
        guard viewModel.board != board else { return }
        if reduceMotion {
            viewModel.selectBoard(board)
        } else {
            withAnimation(Motion.sport) {
                viewModel.selectBoard(board)
            }
        }
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

    private func showBreakdown(_ entry: LeaderboardEntry, board: LeaderboardBoard) {
        Haptics.light()
        selectedBreakdown = ScoreBreakdownSelection(entry: entry, board: board)
    }
}

/// One crew board page. Ranked independently so a swipe can show the next sport before it settles.
private struct CrewBoardPage: View {
    @Environment(AppSession.self) private var session
    let board: LeaderboardBoard
    let viewModel: CrewViewModel
    let onSelectEntry: (LeaderboardEntry) -> Void
    let onRetry: () -> Void
    let onRetryPintFeed: () -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List {
            if case .loaded = viewModel.state, let standing = currentStanding {
                Section {
                    CrewStandingHeader(
                        name: session.profile?.displayName ?? standing.entry.displayName,
                        rank: standing.rank,
                        entry: standing.entry,
                        board: board,
                        action: showCurrentStandingBreakdown
                    )
                    .listRowInsets(headerInsets)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }

            Section {
                boardSection
            } header: {
                SectionHeader(title: "Club leaderboard")
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: Spacing.md, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
            }

            if board.showsCrewPints {
                Section {
                    pintSection
                } header: {
                    SectionHeader(title: "Crew pints")
                        .textCase(nil)
                        .listRowInsets(EdgeInsets(top: Spacing.lg, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSeparator(.hidden)
        .refreshable {
            await onRefresh()
        }
        .accessibilityHint("Swipe left or right to switch boards")
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
                action: onRetry
            )
            .frame(minHeight: 220)
            .listRowInsets(listInsets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        case .failed(let message):
            ErrorStateView(message: message, retry: onRetry)
                .frame(minHeight: 220)
                .listRowInsets(listInsets)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        case .loaded:
            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, entry in
                RankRowView(
                    rank: index + 1,
                    entry: entry,
                    board: board,
                    isCurrentUser: entry.userId == viewModel.currentUserId,
                    avatars: session.avatars,
                    onSelect: onSelectEntry
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
            ErrorStateView(message: message, retry: onRetryPintFeed)
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

    private var ranked: [LeaderboardEntry] {
        viewModel.ranked(for: board)
    }

    private var currentStanding: (rank: Int, entry: LeaderboardEntry)? {
        guard let userId = viewModel.currentUserId,
              let index = ranked.firstIndex(where: { $0.userId == userId }) else {
            return nil
        }
        return (index + 1, ranked[index])
    }

    private var listInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md)
    }

    private var headerInsets: EdgeInsets {
        EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md)
    }

    private func showCurrentStandingBreakdown() {
        guard let standing = currentStanding else { return }
        onSelectEntry(standing.entry)
    }
}

private struct ScoreBreakdownSelection: Identifiable, Hashable {
    let entry: LeaderboardEntry
    let board: LeaderboardBoard

    var id: String {
        "\(entry.userId)-\(board.rawValue)"
    }
}

/// Home standing: greeting, rank as graphic, points as the primary metric.
private struct CrewStandingHeader: View {
    let name: String
    let rank: Int
    let entry: LeaderboardEntry
    let board: LeaderboardBoard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            headerContent
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Shows how this score is calculated")
        .accessibilityAddTraits(.isButton)
    }

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(GreetingCopy.headline(name: name))
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.8)
            // Rank and score share a baseline so the header reads as one scoreboard row.
            HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                Text(Formatters.rank(rank))
                    .font(Typography.displayXL)
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: Spacing.sm)
                MetricView(
                    value: Formatters.pointsValue(entry.points(for: board)),
                    unit: "PTS",
                    valueFont: Typography.displayL,
                    valueColor: Palette.text,
                    alignment: .trailing
                )
            }
            Text(metaLine)
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.4)
                .fixedSize(horizontal: false, vertical: true)
            Hairline()
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var metaLine: String {
        let boardTitle = board.title.uppercased()
        switch board {
        case .overall:
            return "\(boardTitle)  ·  \(volumeLine)  ·  THIS SEASON"
        case .swim, .run, .ride:
            return "\(boardTitle)  ·  THIS SEASON"
        case .beers:
            return "\(boardTitle)  ·  \(Formatters.beerCount(entry.beerCount).uppercased())  ·  THIS SEASON"
        }
    }

    private var volumeLine: String {
        var parts: [String] = []
        if entry.swimMeters > 0 {
            parts.append("\(Formatters.distanceValue(meters: entry.swimMeters)) KM SWIM")
        }
        if entry.rideMeters > 0 {
            parts.append("\(Formatters.distanceValue(meters: entry.rideMeters)) KM BIKE")
        }
        if entry.runMeters > 0 {
            parts.append("\(Formatters.distanceValue(meters: entry.runMeters)) KM RUN")
        }
        if entry.beerCount > 0 {
            parts.append(Formatters.beerCount(entry.beerCount).uppercased())
        }
        return parts.isEmpty ? "NO VOLUME YET" : parts.joined(separator: "  ·  ")
    }

    private var accessibilityText: String {
        "\(GreetingCopy.headline(name: name)). Rank \(rank). \(Formatters.points(entry.points(for: board))). \(metaLine)"
    }
}
