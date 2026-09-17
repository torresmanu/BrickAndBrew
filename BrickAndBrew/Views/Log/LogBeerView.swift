import SwiftUI

struct LogBeerView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: LogBeerViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    LogBeerLoadedView(viewModel: viewModel)
                } else {
                    LoadingView(message: "Opening your tab…")
                }
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Log")
        }
        .onAppear(perform: ensureViewModel)
        .task(id: viewModel != nil) {
            await viewModel?.load()
        }
    }

    private func ensureViewModel() {
        if viewModel == nil {
            viewModel = LogBeerViewModel(session: session)
        }
    }
}

private struct LogBeerLoadedView: View {
    @Bindable var viewModel: LogBeerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                composer
                recent
            }
            .padding(Spacing.md)
        }
        .refreshable(action: refresh)
        .alert(
            "Couldn't log that beer",
            isPresented: bannerBinding,
            actions: {
                Button("OK", action: dismissBanner)
            },
            message: {
                Text(viewModel.bannerMessage ?? "")
            }
        )
    }

    private var composer: some View {
        VStack(spacing: Spacing.md) {
            Text("Add beers")
                .font(.title2.bold())
                .foregroundStyle(Palette.cream)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.lg) {
                Button(action: viewModel.decrementCount) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Palette.muted)
                }
                .accessibilityLabel("Fewer beers")

                Text("\(viewModel.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.amber)
                    .frame(minWidth: 64)
                    .accessibilityLabel("\(viewModel.count) beers")

                Button(action: viewModel.incrementCount) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Palette.amber)
                }
                .accessibilityLabel("More beers")
            }

            TextField("Optional note (IPA, finish-line pint…)", text: $viewModel.note)
                .padding(Spacing.md)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(Palette.cream)

            if viewModel.isSaving {
                LoadingView(message: "Pouring it onto the board…")
                    .frame(height: 80)
            } else {
                Button("Log beers", action: log)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(Spacing.md)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var recent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Your beers")
                .font(.headline)
                .foregroundStyle(Palette.cream)

            switch viewModel.state {
            case .loading:
                LoadingView(message: "Loading your beers…")
                    .frame(minHeight: 180)
            case .empty:
                EmptyStateView(
                    title: "No beers yet",
                    message: "When you log a pint, it shows up here and on the crew board.",
                    systemImage: "mug"
                )
                .frame(minHeight: 220)
            case .failed(let message):
                ErrorStateView(message: message, retry: retry)
                    .frame(minHeight: 220)
            case .loaded(let beers):
                ForEach(beers) { beer in
                    BeerRowView(beer: beer)
                }
            }
        }
    }

    private var bannerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.bannerMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    viewModel.bannerMessage = nil
                }
            }
        )
    }

    private func dismissBanner() {
        viewModel.bannerMessage = nil
    }

    private func log() {
        Task {
            await viewModel.logBeers()
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }

    private func refresh() async {
        await viewModel.load()
    }
}

private struct BeerRowView: View {
    let beer: Beer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Formatters.beerCount(beer.count))
                    .font(.headline)
                    .foregroundStyle(Palette.cream)
                Spacer()
                Text(Formatters.relative(beer.loggedAt))
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
            }
            if let note = beer.note, note.isEmpty == false {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            }
        }
        .padding(Spacing.md)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
