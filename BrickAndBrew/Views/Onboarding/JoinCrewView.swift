import SwiftUI

struct JoinCrewView: View {
    @Environment(AppSession.self) private var session
    @State private var code = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            Text("Join the crew")
                .font(.largeTitle.bold())
                .foregroundStyle(Palette.cream)
            Text("Ask a teammate for the invite code. If you're first, pick one and share it.")
                .font(.body)
                .foregroundStyle(Palette.muted)
            TextField("Invite code", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.join)
                .padding(Spacing.md)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(Palette.cream)
                .onSubmit(join)

            if session.isBusy {
                LoadingView(message: "Finding the crew…")
                    .frame(maxHeight: 140)
            } else {
                Button("Join or create", action: join)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(InviteCode.isValid(InviteCode.normalized(code)) == false)
                    .opacity(InviteCode.isValid(InviteCode.normalized(code)) ? 1 : 0.5)
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
