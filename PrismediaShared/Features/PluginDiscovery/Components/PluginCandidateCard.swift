import SwiftUI

#if os(iOS) || os(macOS)
    struct PluginCandidateCard: View {
        let candidate: AdministrativeEntitySearchCandidate
        let isBestMatch: Bool
        let isActive: Bool
        let isDisabled: Bool
        let onActivate: () -> Void
        let onPreview: (() -> Void)?

        var body: some View {
            HStack(spacing: PrismediaSpacing.small) {
                Button(action: onActivate) {
                    HStack(alignment: .center, spacing: PrismediaSpacing.medium) {
                        EntityThumbnailArtworkFrame(aspectRatio: 2.0 / 3.0) {
                            RemotePosterImage(
                                path: candidate.posterURL,
                                fallbackSeed: candidate.title,
                                systemImage: "photo"
                            )
                        }
                        .frame(width: 58)
                        .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous))

                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            if isBestMatch {
                                Label("Best Match", systemImage: "sparkles")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PrismediaColor.accent)
                            }

                            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                                Text(candidate.title)
                                    .font(.headline)
                                    .foregroundStyle(PrismediaColor.textPrimary)
                                    .multilineTextAlignment(.leading)
                                if let year = candidate.year {
                                    Text(year.formatted(.number.grouping(.never)))
                                        .font(.subheadline)
                                        .foregroundStyle(PrismediaColor.textSecondary)
                                }
                            }

                            if let matchReason = candidate.matchReason, !matchReason.isEmpty {
                                Text(matchReason)
                                    .font(.subheadline)
                                    .foregroundStyle(PrismediaColor.textSecondary)
                            }

                            if let overview = candidate.overview, !overview.isEmpty {
                                Text(overview)
                                    .font(.caption)
                                    .foregroundStyle(PrismediaColor.textMuted)
                                    .lineLimit(2)
                            }

                            HStack(spacing: PrismediaSpacing.medium) {
                                if let source = candidate.source, !source.isEmpty {
                                    Label(source, systemImage: "puzzlepiece.extension")
                                }
                                if let confidence = candidate.confidence {
                                    Label(confidenceLabel(confidence), systemImage: "scope")
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(PrismediaColor.textMuted)
                        }

                        Spacer(minLength: 8)

                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(PrismediaColor.accent)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PrismediaColor.textMuted)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(PrismediaSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint("Select this candidate for review.")
                .accessibilityAddTraits(isActive ? .isSelected : [])

                if let onPreview, candidate.posterURL != nil {
                    PrismediaButton(
                        "Preview artwork for \(candidate.title)",
                        systemImage: "photo.badge.magnifyingglass",
                        form: .compactIcon,
                        surface: .embedded,
                        action: onPreview
                    )
                    .disabled(isDisabled)
                }
            }
            .padding(PrismediaSpacing.extraSmall)
            .background(
                isActive ? PrismediaColor.controlFill : PrismediaColor.elevatedContentBackground,
                in: RoundedRectangle(cornerRadius: PrismediaRadius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: PrismediaRadius.card, style: .continuous)
                    .stroke(
                        isActive ? PrismediaColor.accent : PrismediaColor.borderSubtle,
                        lineWidth: PrismediaLayout.hairline
                    )
            }
        }

        private var accessibilityLabel: String {
            var parts = [candidate.title]
            if isBestMatch { parts.append("Best match") }
            if let year = candidate.year { parts.append(year.formatted(.number.grouping(.never))) }
            if let source = candidate.source, !source.isEmpty { parts.append("Provider \(source)") }
            if let matchReason = candidate.matchReason, !matchReason.isEmpty { parts.append(matchReason) }
            return parts.joined(separator: ", ")
        }

        private func confidenceLabel(_ confidence: Decimal) -> String {
            let value = NSDecimalNumber(decimal: confidence).doubleValue
            return value.formatted(.percent.precision(.fractionLength(0)))
        }
    }

    #if DEBUG
        #Preview("Plugin Candidate Card") {
            PreviewShell {
                PluginCandidateCard(
                    candidate: PluginSearchPreviewFixtures.candidates[0],
                    isBestMatch: true,
                    isActive: true,
                    isDisabled: false,
                    onActivate: {},
                    onPreview: {}
                )
                .padding()
            }
        }
    #endif
#endif
