import SwiftUI

#if os(iOS) || os(macOS)
    struct PluginCandidateCard: View {
        let candidate: AdministrativeEntitySearchCandidate
        let entityKind: String
        let isBestMatch: Bool
        let isActive: Bool
        let isDisabled: Bool
        var detail: String?
        let onActivate: () -> Void
        let onPreview: (() -> Void)?

        var body: some View {
            HStack(spacing: PrismediaSpacing.small) {
                Button(action: onActivate) {
                    HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                        EntityThumbnailArtworkFrame(aspectRatio: artworkAspectRatio) {
                            RemotePosterImage(
                                path: ProviderImagePreviewPolicy.previewURL(for: candidate.posterURL),
                                fallbackSeed: candidate.title,
                                systemImage: "photo"
                            )
                        }
                        .frame(width: 64)
                        .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous))

                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
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
                                if isBestMatch {
                                    Label("Best", systemImage: "star.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(PrismediaColor.accent)
                                        .labelStyle(.titleAndIcon)
                                        .fixedSize()
                                        .layoutPriority(1)
                                }
                            }

                            if let overview = candidate.overview, !overview.isEmpty {
                                Text(overview)
                                    .font(.caption)
                                    .foregroundStyle(PrismediaColor.textMuted)
                                    .lineLimit(4)
                            } else {
                                Text("No provider description available.")
                                    .font(.caption.italic())
                                    .foregroundStyle(PrismediaColor.textMuted)
                            }

                            HStack(spacing: PrismediaSpacing.medium) {
                                if let detail, !detail.isEmpty {
                                    Text(detail)
                                }
                                if let matchReason = candidate.matchReason, !matchReason.isEmpty {
                                    Label(matchReason, systemImage: "puzzlepiece.extension")
                                } else if let source = candidate.source, !source.isEmpty {
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
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PrismediaColor.textMuted)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint("Select this candidate for review.")
                .accessibilityValue(isActive ? "Opening review" : "")
                .accessibilityAddTraits(isActive ? .isSelected : [])

                if let onPreview, candidate.posterURL != nil {
                    Button(
                        "Preview artwork for \(candidate.title)",
                        systemImage: "photo.badge.magnifyingglass",
                        action: onPreview
                    )
                    .labelStyle(.iconOnly)
                    .disabled(isDisabled)
                }
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

        private var artworkAspectRatio: CGFloat {
            switch entityKind.lowercased() {
            case "studio":
                16.0 / 9.0
            case "person", "book-author", "music-artist":
                4.0 / 5.0
            default:
                2.0 / 3.0
            }
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
                    entityKind: "movie",
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
