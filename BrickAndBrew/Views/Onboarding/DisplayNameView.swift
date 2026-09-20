import SwiftUI

struct DisplayNameView: View {
    @Environment(AppSession.self) private var session
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            Text("WHAT SHOULD\nTHE CREW\nCALL YOU?")
                .font(Typography.displayM)
                .foregroundStyle(Palette.text)
                .minimumScaleFactor(0.7)
            Text("This name shows on the leaderboard. Keep it recognizable.")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
            TextField("Display name", text: $name)
                .textContentType(.nickname)
                .submitLabel(.done)
                .brandField()
                .onSubmit(save)

            if session.isBusy {
                LoadingView(message: "Saving your name…")
                    .frame(maxHeight: 140)
            } else {
                Button("Continue", action: save)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
            }
            Spacer()
        }
        .padding(Spacing.lg)
        .onAppear(perform: prefill)
    }

    private func prefill() {
        if name.isEmpty {
            name = session.suggestedName
        }
    }

    private func save() {
        Task {
            await session.saveDisplayName(name)
        }
    }
}
