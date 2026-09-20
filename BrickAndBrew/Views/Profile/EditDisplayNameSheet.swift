import SwiftUI

struct EditDisplayNameSheet: View {
    @Bindable var viewModel: MeViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("This name shows on the leaderboard. Keep it recognizable.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)

                TextField("Display name", text: $viewModel.draftName)
                    .textContentType(.nickname)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .brandField()
                    .disabled(viewModel.isSavingName)
                    .onChange(of: viewModel.draftName, limitDraftName)
                    .onSubmit(save)

                Text("\(DisplayName.normalized(viewModel.draftName).count)/\(DisplayName.maxLength)")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.secondaryText)

                if let message = viewModel.nameEditMessage {
                    Text(message)
                        .font(Typography.body)
                        .foregroundStyle(Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.isSavingName {
                    LoadingView(message: "Saving your name…")
                        .frame(maxHeight: 120)
                }

                Spacer()
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Edit name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: close)
                        .disabled(viewModel.isSavingName)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(viewModel.canSaveName == false)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.background)
        .interactiveDismissDisabled(viewModel.isSavingName)
        .onAppear {
            isNameFocused = true
        }
    }

    private func limitDraftName(_ oldValue: String, _ newValue: String) {
        if newValue.count > DisplayName.maxLength {
            viewModel.draftName = String(newValue.prefix(DisplayName.maxLength))
        }
    }

    private func save() {
        guard viewModel.canSaveName else { return }
        Task {
            let didSave = await viewModel.saveDisplayName()
            if didSave {
                dismiss()
            }
        }
    }

    private func close() {
        dismiss()
    }
}
