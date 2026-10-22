import SwiftUI
import UIKit

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
        .onChange(of: session.team?.id, reloadAfterCrewChange)
    }

    private func reloadAfterCrewChange(_ previous: String?, _ current: String?) {
        guard previous != current, current != nil else { return }
        Task {
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
    @Environment(AppSession.self) private var session
    @Bindable var viewModel: LogBeerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                composer
                recent
            }
            .padding(Spacing.md)
        }
        .refreshable(action: refresh)
        .alert(
            "Heads up",
            isPresented: bannerBinding,
            actions: {
                if viewModel.showsOpenSettings {
                    Button("Open Settings", action: openSettings)
                }
                Button("OK", action: dismissBanner)
            },
            message: {
                Text(viewModel.bannerMessage ?? "")
            }
        )
        .fullScreenCover(isPresented: cameraBinding) {
            CameraPicker(
                onCapture: viewModel.applyCapturedPhoto,
                onCancel: viewModel.cancelCamera
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: cheerBinding) {
            CelebrationView(
                kicker: "THE PUB RULE",
                title: "BEER\nEARNED.",
                value: "+\(Formatters.pointsValue(Scoring.beerPoints(count: viewModel.lastLoggedCount)))",
                unit: "PTS",
                detail: viewModel.cheerMessage,
                dismiss: viewModel.dismissCheer
            )
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("BEER")
                .font(Typography.displayM)
                .foregroundStyle(Palette.text)

            if viewModel.showsPintNudge {
                Text(StreakCopy.atRiskNudge(kind: .pint))
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(StreakCopy.atRiskNudge(kind: .pint))
            }

            HStack(alignment: .bottom, spacing: Spacing.lg) {
                Button(action: viewModel.decrementCount) {
                    Image(systemName: "minus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Palette.secondaryText)
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                                .stroke(Palette.hairline, lineWidth: 1)
                        }
                }
                .accessibilityLabel("Fewer beers")

                MetricView(
                    value: Formatters.rank(viewModel.count),
                    unit: Formatters.beerUnit(viewModel.count),
                    valueFont: Typography.displayXL,
                    valueColor: Palette.accent
                )
                .frame(maxWidth: .infinity)

                Button(action: viewModel.incrementCount) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                                .stroke(Palette.accent, lineWidth: 1)
                        }
                }
                .accessibilityLabel("More beers")
            }
            .accessibilityElement(children: .contain)

            TextField("Optional note (IPA, finish-line pint…)", text: $viewModel.note)
                .brandField()

            photoComposer

            if viewModel.isSaving {
                LoadingView(message: "Pouring it onto the board…")
                    .frame(height: 80)
            } else {
                Button("Add beer", action: log)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var photoComposer: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let preview = viewModel.pendingPhotoImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .padding(.horizontal, -Spacing.md)
                    .accessibilityLabel("Pint photo ready to log")
                Button("Remove photo", role: .destructive, action: viewModel.removePendingPhoto)
                    .disabled(viewModel.isSaving)
            } else {
                Button("Take photo", action: takePhoto)
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.isSaving)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var recent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Your beers")

            switch viewModel.state {
            case .loading:
                LoadingView(message: "Loading your beers…")
                    .frame(minHeight: 180)
            case .empty:
                EmptyStateView(
                    title: "No beers yet",
                    message: "When you log a pint, it shows up here and on the crew board.",
                    icon: PintSymbol()
                )
                .frame(minHeight: 220)
            case .failed(let message):
                ErrorStateView(message: message, retry: retry)
                    .frame(minHeight: 220)
            case .loaded(let beers):
                ForEach(beers) { beer in
                    BeerRowView(
                        beer: beer,
                        photos: session.beerPhotos,
                        hasPhoto: viewModel.photoBeerIds.contains(beer.id)
                    )
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
                    viewModel.showsOpenSettings = false
                }
            }
        )
    }

    private var cameraBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isCameraPresented },
            set: { isPresented in
                if isPresented == false {
                    viewModel.cancelCamera()
                }
            }
        )
    }

    private var cheerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.cheerMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    viewModel.dismissCheer()
                }
            }
        )
    }

    private func dismissBanner() {
        viewModel.bannerMessage = nil
        viewModel.showsOpenSettings = false
    }

    private func openSettings() {
        viewModel.showsOpenSettings = false
        viewModel.bannerMessage = nil
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func takePhoto() {
        Task {
            await viewModel.requestCamera()
        }
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
    let photos: BeerPhotoCache
    let hasPhoto: Bool
    @State private var isPreviewPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                MetricView(
                    value: Formatters.rank(beer.count),
                    unit: Formatters.beerUnit(beer.count),
                    valueFont: Typography.displayM,
                    valueColor: Palette.text
                )
                Spacer()
                Text(Formatters.relative(beer.loggedAt).uppercased())
                    .font(Typography.metadata)
                    .foregroundStyle(Palette.secondaryText)
                    .tracking(1.2)
            }
            Text("+\(Formatters.pointsValue(Scoring.beerPoints(count: beer.count))) PTS")
                .font(Typography.metadata)
                .foregroundStyle(Palette.accent)
                .tracking(1.4)
            if let note = beer.note, note.isEmpty == false {
                Text(note)
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
            }
            if hasPhoto, let image = currentImage {
                Button(action: showPreview) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, -Spacing.md)
                .accessibilityLabel("Pint photo")
                .accessibilityHint("Shows a larger photo")
                .fullScreenCover(isPresented: $isPreviewPresented) {
                    PhotoPreviewView(image: image, accessibilityLabel: "Pint photo")
                }
            }
            Hairline()
                .padding(.top, Spacing.xs)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var currentImage: UIImage? {
        _ = photos.generation
        return photos.image(for: beer.id)
    }

    private func showPreview() {
        Haptics.light()
        isPreviewPresented = true
    }
}
