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
            VStack(spacing: Spacing.lg) {
                if let cheer = viewModel.cheerMessage {
                    cheerCard(cheer)
                }
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
    }

    private var composer: some View {
        VStack(spacing: Spacing.md) {
            Text("Add beers")
                .font(.title2.bold())
                .foregroundStyle(Palette.cream)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.showsPintNudge {
                Text(StreakCopy.atRiskNudge(kind: .pint))
                    .font(Typography.body)
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(StreakCopy.atRiskNudge(kind: .pint))
            }

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

            photoComposer

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

    private var photoComposer: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let preview = viewModel.pendingPhotoImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
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

    private func cheerCard(_ message: String) -> some View {
        Button(action: viewModel.dismissCheer) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                PintSymbol()
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.cream)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Palette.cream)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .background(Palette.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.object, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(message)
        .accessibilityHint("Dismisses the cheer")
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
            if hasPhoto, let image = currentImage {
                Button(action: showPreview) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pint photo")
                .accessibilityHint("Shows a larger photo")
                .fullScreenCover(isPresented: $isPreviewPresented) {
                    PhotoPreviewView(image: image, accessibilityLabel: "Pint photo")
                }
            }
        }
        .padding(Spacing.md)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
