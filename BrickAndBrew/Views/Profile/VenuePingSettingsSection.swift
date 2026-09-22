import SwiftUI

struct PintReminderSettingsSection: View {
    @Bindable var viewModel: MeViewModel

    var body: some View {
        Section {
            Toggle("Pint reminder", isOn: reminderBinding)
                .tint(Palette.accent)
                .foregroundStyle(Palette.text)
        } header: {
            Text("Reminders")
        } footer: {
            Text(StreakCopy.pintReminderFooter)
                .foregroundStyle(Palette.secondaryText)
        }
        .listRowBackground(Palette.surface)
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPintReminderEnabled },
            set: { enabled in
                Task {
                    await viewModel.setPintReminderEnabled(enabled)
                }
            }
        )
    }
}

/// Nearby pint toggle, home/work pins, and permission pauses. Lives outside MeView for size.
struct VenuePingSettingsSection: View {
    @Bindable var viewModel: MeViewModel

    var body: some View {
        Section {
            Toggle(VenuePingCopy.toggleTitle, isOn: venuePingBinding)
                .tint(Palette.accent)
                .foregroundStyle(Palette.text)
                .disabled(viewModel.isRequestingVenuePing)

            if viewModel.isRequestingVenuePing {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .tint(Palette.accent)
                    Text(VenuePingCopy.enabling)
                        .foregroundStyle(Palette.secondaryText)
                }
            }

            if let status = viewModel.venuePingStatusMessage {
                Text(status)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SavedPlaceRow(viewModel: viewModel, kind: .home)
            SavedPlaceRow(viewModel: viewModel, kind: .work)
        } header: {
            Text("Nearby pint")
        } footer: {
            Text(VenuePingCopy.footer)
                .foregroundStyle(Palette.secondaryText)
        }
        .listRowBackground(Palette.surface)
    }

    private var venuePingBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isVenuePingEnabled },
            set: { enabled in
                Task {
                    await viewModel.setVenuePingEnabled(enabled)
                }
            }
        )
    }
}

private struct SavedPlaceRow: View {
    @Bindable var viewModel: MeViewModel
    let kind: VenuePlaceKind

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .foregroundStyle(Palette.text)

            statusView

            HStack(spacing: Spacing.md) {
                Button(setTitle, action: save)
                if hasPlace {
                    Button(VenuePingCopy.clear, role: .destructive, action: clear)
                }
            }
        }
        .disabled(isSaving)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityName)
    }

    @ViewBuilder
    private var statusView: some View {
        if isSaving {
            HStack(spacing: Spacing.xs) {
                ProgressView()
                    .tint(Palette.accent)
                Text(VenuePingCopy.findingSpot)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
        } else if let error {
            Text(error)
                .font(Typography.caption)
                .foregroundStyle(Palette.danger)
                .fixedSize(horizontal: false, vertical: true)
        } else if let label {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)
        } else {
            Text(VenuePingCopy.emptyPlace)
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var title: String {
        kind == .home ? VenuePingCopy.homeTitle : VenuePingCopy.workTitle
    }

    private var setTitle: String {
        kind == .home ? VenuePingCopy.setHome : VenuePingCopy.setWork
    }

    private var accessibilityName: String {
        kind == .home ? VenuePingCopy.homeAccessibility : VenuePingCopy.workAccessibility
    }

    private var isSaving: Bool {
        kind == .home ? viewModel.isSavingHome : viewModel.isSavingWork
    }

    private var error: String? {
        kind == .home ? viewModel.homeError : viewModel.workError
    }

    private var label: String? {
        kind == .home ? viewModel.homeLabel : viewModel.workLabel
    }

    private var hasPlace: Bool {
        label != nil
    }

    private func save() {
        Task {
            await viewModel.savePlace(kind)
        }
    }

    private func clear() {
        viewModel.clearPlace(kind)
    }
}
