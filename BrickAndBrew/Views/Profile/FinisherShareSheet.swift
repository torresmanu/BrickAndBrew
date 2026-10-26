import SwiftUI
import UIKit

/// Preview, Instagram size picker, share sheet, and save-to-Photos for one finish.
struct FinisherShareSheet: View {
    let finish: TriathlonFinish
    @Environment(\.dismiss) private var dismiss
    @State private var format: FinisherCardFormat = .square
    @State private var renderedImage: UIImage?
    @State private var isRendering = true
    @State private var isSaving = false
    @State private var isSharing = false
    @State private var message: String?
    @State private var isError = false
    @State private var showsOpenSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    preview
                    formatPicker
                    actions
                    status
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Finisher card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                }
            }
            .brandGlassSheetContent()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .brandGlassSheet()
        .task(id: format) {
            await renderCard()
        }
        .sheet(isPresented: $isSharing, content: shareSheet)
        .alert(
            "Heads up",
            isPresented: settingsAlertBinding,
            actions: {
                Button("Open Settings", action: openSettings)
                Button("OK", role: .cancel, action: dismissMessage)
            },
            message: {
                Text(message ?? "")
            }
        )
    }

    private var preview: some View {
        Group {
            if isRendering && renderedImage == nil {
                LoadingView(message: FinisherCopy.renderingMessage)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 240)
            } else if let renderedImage {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                            .stroke(Palette.hairline, lineWidth: 1)
                    }
                    .accessibilityLabel("Finisher card preview")
            } else {
                ErrorStateView(
                    message: BrickError.finisherRenderFailed.localizedDescription ?? FinisherCopy.renderingMessage,
                    retry: retryRender
                )
            }
        }
    }

    private var formatPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Button(FinisherCardFormat.square.title, action: selectSquare)
                    .buttonStyle(FormatChipStyle(isSelected: format == .square))
                    .accessibilityAddTraits(format == .square ? .isSelected : [])
                Button(FinisherCardFormat.story.title, action: selectStory)
                    .buttonStyle(FormatChipStyle(isSelected: format == .story))
                    .accessibilityAddTraits(format == .story ? .isSelected : [])
            }
            Text(FinisherCopy.formatHint(format))
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            Button(FinisherCopy.shareTitle, action: share)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(renderedImage == nil || isRendering || isSaving)
            Button(FinisherCopy.saveTitle, action: saveToPhotos)
                .buttonStyle(SecondaryButtonStyle())
                .disabled(renderedImage == nil || isRendering || isSaving)
            if isSaving {
                LoadingView(message: FinisherCopy.savingMessage)
                    .frame(maxHeight: 80)
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        if let message, showsOpenSettings == false {
            Text(message)
                .font(Typography.body)
                .foregroundStyle(isError ? Palette.danger : Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func shareSheet() -> some View {
        if let renderedImage {
            ActivityShareSheet(items: [renderedImage])
        }
    }

    private var settingsAlertBinding: Binding<Bool> {
        Binding(
            get: { showsOpenSettings },
            set: { presented in
                if presented == false {
                    showsOpenSettings = false
                }
            }
        )
    }

    private func selectSquare() {
        selectFormat(.square)
    }

    private func selectStory() {
        selectFormat(.story)
    }

    private func selectFormat(_ value: FinisherCardFormat) {
        guard format != value else { return }
        format = value
        renderedImage = nil
        isRendering = true
        message = nil
        isError = false
    }

    private func retryRender() {
        isRendering = true
        renderedImage = nil
        message = nil
        isError = false
        Task {
            await renderCard()
        }
    }

    private func renderCard() async {
        isRendering = true
        isError = false
        do {
            let image = try FinisherImageExport.render(finish: finish, format: format)
            renderedImage = image
            isRendering = false
        } catch {
            renderedImage = nil
            isRendering = false
            isError = true
            message = (error as? LocalizedError)?.errorDescription
                ?? BrickError.finisherRenderFailed.localizedDescription
        }
    }

    private func share() {
        guard renderedImage != nil else { return }
        Haptics.light()
        isSharing = true
    }

    private func saveToPhotos() {
        guard let renderedImage, isSaving == false else { return }
        isSaving = true
        message = nil
        isError = false
        Task {
            defer { isSaving = false }
            do {
                try await FinisherImageExport.saveToPhotos(renderedImage)
                Haptics.success()
                message = FinisherCopy.savedMessage
                isError = false
            } catch let error as BrickError where error == .photosDenied {
                isError = true
                message = error.localizedDescription
                showsOpenSettings = true
            } catch {
                isError = true
                message = (error as? LocalizedError)?.errorDescription
                    ?? "We couldn't save the card. Check Photos access and try again."
            }
        }
    }

    private func openSettings() {
        showsOpenSettings = false
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func dismissMessage() {
        showsOpenSettings = false
    }

    private func close() {
        dismiss()
    }
}

private struct FormatChipStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.plexSans(size: 14, weight: .semibold, relativeTo: .body))
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(isSelected ? Palette.ink : Palette.text)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(chipFill(isPressed: configuration.isPressed))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .stroke(isSelected ? Color.clear : Palette.hairlineStrong, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }

    private func chipFill(isPressed: Bool) -> Color {
        if isSelected {
            return isPressed ? Palette.accentPressed : Palette.accent
        }
        return Palette.surfaceElevated.opacity(isPressed ? 0.7 : 1)
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
