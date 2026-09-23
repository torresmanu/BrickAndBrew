import SwiftUI

struct ChangeCrewSheet: View {
    @Bindable var viewModel: MeViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCodeFocused: Bool
    @State private var confirmSwitch = false

    var body: some View {
        NavigationStack {
            ScrollView {
                form
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Change crew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: close)
                        .disabled(viewModel.isSwitchingCrew)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Switch", action: askToSwitch)
                        .disabled(viewModel.canSwitchCrew == false)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.background)
        .interactiveDismissDisabled(viewModel.isSwitchingCrew)
        .confirmationDialog(
            "Leave \(viewModel.inviteCode)?",
            isPresented: $confirmSwitch,
            titleVisibility: .visible
        ) {
            Button("Switch crew", action: switchCrew)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll join \(InviteCode.normalized(viewModel.draftCrewCode)). Training and pints leave \(viewModel.inviteCode) and count on the new crew's season.")
        }
        .onAppear {
            isCodeFocused = true
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("You're on \(viewModel.inviteCode). Brick & Brew keeps you on one crew, so switching takes you off this board.")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)

            Text("Ask a teammate for their code. A new code starts a crew on your current season, and your training and pints move with you.")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)

            TextField("Invite code", text: $viewModel.draftCrewCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isCodeFocused)
                .brandField()
                .disabled(viewModel.isSwitchingCrew)
                .onChange(of: viewModel.draftCrewCode, limitDraftCode)
                .onSubmit(askToSwitch)

            if let hint = draftHint {
                Text(hint)
                    .font(Typography.body)
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.isSwitchingCrew {
                LoadingView(message: "Moving you to the new crew…")
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var draftHint: String? {
        if let message = viewModel.crewEditMessage {
            return message
        }
        let code = InviteCode.normalized(viewModel.draftCrewCode)
        if code.isEmpty {
            return nil
        }
        if InviteCode.isValid(code) == false {
            return BrickError.invalidInviteCode.localizedDescription
        }
        if code == InviteCode.normalized(viewModel.inviteCode) {
            return BrickError.alreadyOnCrew.localizedDescription
        }
        return nil
    }

    private func limitDraftCode(_ oldValue: String, _ newValue: String) {
        let clipped = String(InviteCode.normalized(newValue).prefix(InviteCode.maxLength))
        if clipped != newValue {
            viewModel.draftCrewCode = clipped
        }
        if oldValue != newValue {
            viewModel.crewEditMessage = nil
        }
    }

    private func askToSwitch() {
        guard viewModel.canSwitchCrew else { return }
        confirmSwitch = true
    }

    private func switchCrew() {
        Task {
            let didSwitch = await viewModel.switchCrew()
            if didSwitch {
                dismiss()
            }
        }
    }

    private func close() {
        dismiss()
    }
}
