import SwiftUI

/// Explains the Total Index using the same constants the boards use.
struct ScoringGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    intro
                    weightsCard
                    coverageCard
                    taxCard
                    boardsCard
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("How points work")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.background)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("The Index is the pub rule.")
                .font(Typography.heading2)
                .foregroundStyle(Palette.cream)
            Text("Beers score hard. Each pint covers a slice of training. Stack swim, bike, and run past your beers and the grind tax lands.")
                .font(Typography.body)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var weightsCard: some View {
        GuideCard(title: "Weights", systemImage: "scalemass") {
            VStack(spacing: Spacing.sm) {
                ForEach(Self.weightRows, content: WeightRowView.init)
            }
        }
    }

    private var coverageCard: some View {
        GuideCard(title: "Pints cover bricks", systemImage: "mug.fill") {
            Text(coverageCopy)
                .font(Typography.body)
                .foregroundStyle(Palette.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var taxCard: some View {
        GuideCard(title: "Grind tax", systemImage: "exclamationmark.triangle.fill") {
            Text(taxCopy)
                .font(Typography.body)
                .foregroundStyle(Palette.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var boardsCard: some View {
        GuideCard(title: "Other boards", systemImage: "list.bullet") {
            Text("Swim, Bike, Run, and Beers still rank raw volume. The grind tax only hits the Index.")
                .font(Typography.body)
                .foregroundStyle(Palette.cream)
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

private struct GuideCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: systemImage)
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.muted)
                .symbolRenderingMode(.hierarchical)
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
    }
}

private struct WeightRowView: View {
    let row: ScoringWeightRow

    init(_ row: ScoringWeightRow) {
        self.row = row
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(row.title)
                .font(Typography.body)
                .foregroundStyle(Palette.cream)
            Spacer(minLength: Spacing.sm)
            Text(row.weight)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.amber)
            Text(row.detail)
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.title), \(row.weight) \(row.detail)")
    }
}
