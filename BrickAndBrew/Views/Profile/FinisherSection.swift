import SwiftUI

/// Me-tab entry for the latest inferred triathlon and older medals.
struct FinisherSection: View {
    @Bindable var viewModel: MeViewModel
    let onShare: (TriathlonFinish) -> Void

    var body: some View {
        Section {
            content
        } header: {
            Text(FinisherCopy.sectionTitle)
        } footer: {
            footer
        }
    }

    @ViewBuilder
    private var content: some View {
        if case .loaded(let finishes) = viewModel.finisherState, finishes.isEmpty == false {
            loadedContent(finishes)
        } else if viewModel.isStravaConnected == false {
            EmptyStateView(
                title: FinisherCopy.connectTitle,
                message: FinisherCopy.connectMessage,
                systemImage: "medal"
            )
            .frame(maxWidth: .infinity, minHeight: 160)
            .listRowInsets(rowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        } else {
            switch viewModel.finisherState {
            case .loading:
                LoadingView(message: FinisherCopy.loadingMessage)
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            case .empty:
                EmptyStateView(
                    title: FinisherCopy.emptyTitle,
                    message: FinisherCopy.emptyMessage,
                    systemImage: "medal"
                )
                .frame(maxWidth: .infinity, minHeight: 180)
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            case .failed(let message):
                ErrorStateView(message: message, retry: retry)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .listRowInsets(rowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            case .loaded:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func loadedContent(_ finishes: [TriathlonFinish]) -> some View {
        if let latest = finishes.first {
            FinisherTeaserRow(finish: latest, onShare: share)
                .listRowInsets(rowInsets)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            ForEach(Array(finishes.dropFirst())) { finish in
                PreviousFinishRow(finish: finish, onShare: share)
                    .listRowBackground(Palette.surface)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch viewModel.finisherState {
        case .loaded:
            Text(FinisherCopy.loadedFooter)
                .foregroundStyle(Palette.secondaryText)
        case .empty:
            Text(FinisherCopy.rulesFooter)
                .foregroundStyle(Palette.secondaryText)
        case .loading, .failed:
            if viewModel.isStravaConnected == false {
                Text(FinisherCopy.rulesFooter)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: Spacing.md, bottom: 6, trailing: Spacing.md)
    }

    private func retry() {
        Task {
            await viewModel.retryStreaks()
        }
    }

    private func share(_ finish: TriathlonFinish) {
        Haptics.light()
        onShare(finish)
    }
}

private struct FinisherTeaserRow: View {
    let finish: TriathlonFinish
    let onShare: (TriathlonFinish) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.md) {
                FinisherMedalView()
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(FinisherCopy.raceSubtitle)
                        .font(Typography.title)
                        .foregroundStyle(Palette.text)
                    Text(FinisherCopy.teaserLine(finish))
                        .font(Typography.metadata)
                        .foregroundStyle(Palette.secondaryText)
                        .tracking(1.2)
                    Text(FinisherCopy.athleteLine(finish))
                        .font(Typography.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(FinisherCopy.shareTitle, action: share)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Hairline()
        }
        .accessibilityElement(children: .combine)
    }

    private func share() {
        onShare(finish)
    }
}

private struct PreviousFinishRow: View {
    let finish: TriathlonFinish
    let onShare: (TriathlonFinish) -> Void

    var body: some View {
        Button(action: share) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(Formatters.raceDate(finish.startDate))
                    .font(Typography.body)
                    .foregroundStyle(Palette.text)
                Text(Formatters.raceTime(finish.elapsedSeconds))
                    .font(Typography.metadata)
                    .foregroundStyle(Palette.secondaryText)
                    .tracking(1.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel("\(Formatters.raceDate(finish.startDate)), \(Formatters.raceTime(finish.elapsedSeconds))")
        .accessibilityHint("Opens the finisher card")
    }

    private func share() {
        onShare(finish)
    }
}
