import SwiftUI

/// Explains the Total Index using the same constants the boards use.
struct ScoringGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    intro
                    weights
                    pint
                    boards
                    streaks
                    adults
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("How points work")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                }
            }
            .brandGlassSheetContent()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .brandGlassSheet()
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("THE INDEX IS TRAINING.")
                .font(Typography.displayM)
                .foregroundStyle(Palette.text)
                .minimumScaleFactor(0.7)
            Text("Swim, bike, and run score on their own. A pint is an optional log. One pint on a day you also train adds a flat bonus. More drinks do not raise the score, and skipping a pint does not lower it.")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var weights: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Training")
            ForEach(Self.weightRows, content: WeightRowView.init)
        }
    }

    private var pint: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Optional pint")
            Text(pintCopy)
                .font(Typography.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var boards: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Boards")
            Text("Index, Swim, Bike, and Run. There is no board for who drank the most. Sport boards rank distance. The Index is training plus the optional pint bonus.")
                .font(Typography.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var streaks: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Streaks")
            Text(streaksCopy)
                .font(Typography.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var adults: some View {
        Text(ScoringCopy.adultsNote)
            .font(Typography.metadata)
            .foregroundStyle(Palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var pintCopy: String {
        let bonus = Formatters.compactNumber(Scoring.pointsPerScoredPint)
        return "One pint on a day with a real swim, bike, or run adds \(bonus) points, once. A second pint that day is only a log. A rest day with a pint adds nothing. No pint, no penalty."
    }

    private var streaksCopy: String {
        "Brick is consecutive days with a scored swim, bike, or run that actually happened — not a 90-second GPS hiccup. Yesterday still counts; the day before does not. Streaks don't add Index points. \(StreakCopy.brickSyncLag)"
    }

    private func close() {
        dismiss()
    }
}

enum ScoringCopy {
    static let adultsNote = "For adults. Logging a pint is optional and is not a prompt to drink."
    static let logHint = "One pint on a day you also train can add points, once. More the same day does not. Skipping a pint does not lower your score."
}

private struct ScoringWeightRow: Identifiable {
    let id: String
    let title: String
    let weight: String
    let detail: String
}

private extension ScoringGuideView {
    static let weightRows: [ScoringWeightRow] = [
        ScoringWeightRow(
            id: "swim",
            title: "Swim",
            weight: "×\(Formatters.compactNumber(Scoring.swimPointsPerKilometer))",
            detail: "per km"
        ),
        ScoringWeightRow(
            id: "run",
            title: "Run",
            weight: "×\(Formatters.compactNumber(Scoring.runPointsPerKilometer))",
            detail: "per km"
        ),
        ScoringWeightRow(
            id: "ride",
            title: "Bike",
            weight: "×\(Formatters.compactNumber(Scoring.ridePointsPerKilometer))",
            detail: "per km"
        ),
        ScoringWeightRow(
            id: "pint",
            title: "Pint",
            weight: "+\(Formatters.compactNumber(Scoring.pointsPerScoredPint))",
            detail: "once a training day"
        ),
    ]
}

private struct WeightRowView: View {
    let row: ScoringWeightRow

    init(_ row: ScoringWeightRow) {
        self.row = row
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(row.title.uppercased())
                .font(Typography.label)
                .foregroundStyle(row.id == "pint" ? Palette.accent : Palette.text)
            Spacer(minLength: Spacing.sm)
            Text(row.weight)
                .font(Typography.displayM)
                .foregroundStyle(row.id == "pint" ? Palette.accent : Palette.text)
                .monospacedDigit()
            Text(row.detail.uppercased())
                .font(Typography.metadata)
                .foregroundStyle(Palette.secondaryText)
                .tracking(1.2)
        }
        .overlay(alignment: .bottom) {
            Hairline()
                .padding(.top, Spacing.sm)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.title), \(row.weight) \(row.detail)")
    }
}
