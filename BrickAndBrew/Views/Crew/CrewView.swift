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

    var body: some View {
        VStack(spacing: 0) {
            BoardFilterBar(
                boards: LeaderboardBoard.allCases,
                selected: viewModel.board,
                action: viewModel.selectBoard
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

            content
        }
        .refreshable(action: refresh)
    }

    @ViewBuilder
    private var content: some View {
        List {
            if case .loaded = viewModel.state, let standing = currentStanding {
                Section {
                    CrewStandingHeader(
                        name: session.profile?.displayName ?? standing.entry.displayName,
                        rank: standing.rank,
                        entry: standing.entry,
                        board: viewModel.board
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

            Section {
                pintSection
            } header: {
                SectionHeader(title: "Crew pints")
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: Spacing.lg, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSeparator(.hidden)
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
                    avatars: session.avatars
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

    private var currentStanding: (rank: Int, entry: LeaderboardEntry)? {
        guard let userId = viewModel.currentUserId,
              let index = viewModel.ranked.firstIndex(where: { $0.userId == userId }) else {
            return nil
        }
        return (index + 1, viewModel.ranked[index])
    }

    private var listInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md)
    }

    private var headerInsets: EdgeInsets {
        EdgeInsets(top: Spacing.sm, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md)
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

/// Home standing: greeting, rank as graphic, points as the primary metric.
private struct CrewStandingHeader: View {
    let name: String
    let rank: Int
    let entry: LeaderboardEntry
    let board: LeaderboardBoard

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(GreetingCopy.headline(name: name))
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.8)
            Text(Formatters.rank(rank))
                .font(Typography.displayXL)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            MetricView(
                value: Formatters.pointsValue(entry.points(for: board)),
                unit: "PTS",
                valueFont: Typography.displayL,
                valueColor: Palette.text
            )
            Text(metaLine)
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.4)
                .fixedSize(horizontal: false, vertical: true)
            Hairline()
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
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
