import SwiftUI
import UIKit

/// Full-screen photo viewer. Tap the background or Close to dismiss.
struct PhotoPreviewView: View {
    let image: UIImage
    let accessibilityLabel: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Palette.background
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(Spacing.md)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits(.isImage)

            Button("Close", action: close)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.cream)
                .padding(Spacing.md)
                .accessibilityLabel("Close photo")
        }
    }

    private func close() {
        dismiss()
    }
}
