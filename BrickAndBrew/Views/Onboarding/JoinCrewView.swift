import SwiftUI

struct JoinCrewView: View {
    @Environment(AppSession.self) private var session
    @State private var code = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            Text("JOIN\nTHE CREW")
                .font(Typography.displayL)
                .foregroundStyle(Palette.text)
                .minimumScaleFactor(0.7)
            Text("Ask a teammate for the invite code. If you're first, pick one and share it.")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
            TextField("Invite code", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.join)
                .brandField()
                .onSubmit(join)

            if session.isBusy {
                LoadingView(message: "Finding the crew…")
                    .frame(maxHeight: 140)
            } else {
                Button("Join or create", action: join)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(InviteCode.isValid(InviteCode.normalized(code)) == false)
                    .opacity(InviteCode.isValid(InviteCode.normalized(code)) ? 1 : 0.4)
            }
            Spacer()
        }
        .padding(Spacing.lg)
    }

    private func join() {
        Task {
            await session.joinCrew(inviteCode: code)
        }
    }
}
