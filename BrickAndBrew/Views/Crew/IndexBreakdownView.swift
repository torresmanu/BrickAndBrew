import SwiftUI

/// Per-person Index math. Opened from an Index leaderboard row.
struct IndexBreakdownView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let avatars: AvatarCache

    @Environment(\.dismiss) private var dismiss

    private var breakdown: IndexBreakdown {
        IndexBreakdown(entry: entry, isCurrentUser: isCurrentUser)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    if breakdown.hasVolume {
                        explanationCard
                        mathCard
                        if let taxNote = breakdown.taxNote {
                            taxCard(taxNote)
                        }
                    } else {
                        emptyCard
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Index breakdown")
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

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            AvatarView(
                userId: entry.userId,
                displayName: entry.displayName,
                size: 56,
                allowsPreview: false,
                cache: avatars
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(Typography.heading2)
                    .foregroundStyle(Palette.cream)
                    .lineLimit(1)
                Text("Rank \(rank) · \(Formatters.points(breakdown.total))")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrentUser ? Palette.surfaceElevated : Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.object, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.object, style: .continuous)
                .stroke(isCurrentUser ? Palette.amber.opacity(0.45) : Color.clear, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayName), rank \(rank), \(Formatters.points(breakdown.total))")
    }

    private var explanationCard: some View {
        BreakdownCard(title: breakdown.headline, systemImage: "sum") {
            Text(breakdown.explanation)
                .font(Typography.body)
                .foregroundStyle(Palette.cream)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(breakdown.explanation)
        }
    }

    private var mathCard: some View {
        BreakdownCard(title: "The math", systemImage: "list.bullet") {
            VStack(spacing: Spacing.sm) {
                ForEach(breakdown.lines, content: BreakdownLineRow.init)
                Divider()
                    .background(Palette.hairline)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text("Index")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.cream)
                    Spacer(minLength: Spacing.sm)
                    Text(Formatters.points(breakdown.total))
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Palette.amber)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Index \(Formatters.points(breakdown.total))")
            }
        }
    }

    private var emptyCard: some View {
        BreakdownCard(title: "No points yet", systemImage: "trophy") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(breakdown.explanation)
                    .font(Typography.body)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Log a beer or sync Strava to put something on the Index.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func taxCard(_ note: String) -> some View {
        BreakdownCard(title: "Grind tax", systemImage: "exclamationmark.triangle.fill") {
            Text(note)
                .font(Typography.body)
                .foregroundStyle(Palette.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func close() {
        dismiss()
    }
}

private struct BreakdownCard<Content: View>: View {
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

private struct BreakdownLineRow: View {
    let line: IndexBreakdown.Line

    init(_ line: IndexBreakdown.Line) {
        self.line = line
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            icon
                .frame(width: 22)
                .foregroundStyle(line.isPenalty ? Palette.danger : Palette.cream)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(line.title)
                    .font(Typography.body)
                    .foregroundStyle(Palette.cream)
                Text(line.source)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(Formatters.signedPoints(line.points))
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(line.isPenalty ? Palette.danger : Palette.amber)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(line.title), \(line.source), \(Formatters.signedPoints(line.points))")
    }

    @ViewBuilder
    private var icon: some View {
        switch line.kind {
        case .beers:
            PintSymbol()
        case .swim:
            Image(systemName: SportKind.swim.systemImage)
        case .ride:
            Image(systemName: SportKind.ride.systemImage)
        case .run:
            Image(systemName: SportKind.run.systemImage)
        case .uncovered:
            Image(systemName: "minus.circle")
        case .grindTax:
            Image(systemName: "exclamationmark.triangle.fill")
        }
    }
}
