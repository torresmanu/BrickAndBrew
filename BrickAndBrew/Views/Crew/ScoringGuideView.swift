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
                    coverage
                    tax
                    boards
                    streaks
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
            Text("THE GOAL IS SIMPLE:\nFITTEST GUY AT THE BAR,\nSTRONGEST DRINKER AT THE GYM.")
                .font(Typography.displayM)
                .foregroundStyle(Palette.text)
                .minimumScaleFactor(0.7)
            Text("That's the Index, the pub rule. Beers score hard. Each pint covers a slice of training. Stack swim, bike, and run past your beers and the grind tax lands. Tap anyone on the board to see their receipt.")
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var weights: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Weights")
            ForEach(Self.weightRows, content: WeightRowView.init)
        }
    }

    private var coverage: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Pints cover bricks")
            Text(coverageCopy)
                .font(Typography.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tax: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Grind tax")
            Text(taxCopy)
                .font(Typography.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var boards: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Other boards")
            Text("Swim, Bike, Run, and Beers still rank raw volume. The grind tax only hits the Index.")
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

    private var coverageCopy: String {
        let covered = Formatters.compactNumber(Scoring.trainingPointsCoveredPerBeer)
        let swimKm = Formatters.compactNumber(Scoring.trainingPointsCoveredPerBeer / Scoring.swimPointsPerKilometer)
        let runKm = Formatters.compactNumber(Scoring.trainingPointsCoveredPerBeer / Scoring.runPointsPerKilometer)
        let rideKm = Formatters.compactNumber(Scoring.trainingPointsCoveredPerBeer / Scoring.ridePointsPerKilometer)
        return "Each beer covers \(covered) training points at full value — \(swimKm) km swim, \(runKm) km run, or \(rideKm) km bike."
    }

    private var taxCopy: String {
        "Training past that coverage is removed from the Index, then taxed another \(Scoring.uncoveredTrainingPenaltyPercent)%. Skip the pint and the number can go negative."
    }

    private var streaksCopy: String {
        "Pint is consecutive days with a logged beer. Brick is a scored swim, bike, or run that actually happened — not a 90-second GPS hiccup. Brick & Brew is both on the same calendar day. Yesterday still counts; the day before does not. Streaks don't score Index points. They just look good at the bar. \(StreakCopy.brickSyncLag)"
    }

    private func close() {
        dismiss()
    }
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
            id: "beer",
            title: "Beer",
            weight: "×\(Formatters.compactNumber(Scoring.pointsPerBeer))",
            detail: "each"
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
                .foregroundStyle(row.id == "beer" ? Palette.accent : Palette.text)
            Spacer(minLength: Spacing.sm)
            Text(row.weight)
                .font(Typography.displayM)
                .foregroundStyle(row.id == "beer" ? Palette.accent : Palette.text)
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
