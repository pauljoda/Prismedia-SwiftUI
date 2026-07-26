#if os(macOS)
    import SwiftUI

    struct MacMusicWaveformStrip: View {
        @State private var dragStartPosition: Double?
        @State private var previewPosition: Double?

        let waveform: MusicWaveform
        let position: Double
        let duration: Double
        let accent: Color
        let secondaryAccent: Color
        let onSeek: (Double) -> Void

        var body: some View {
            HStack(spacing: 0) {
                jumpButton(direction: -1, systemImage: "chevron.left")

                GeometryReader { geometry in
                    let stripWidth = MacMusicWaveformLayout.stripWidth(
                        pairCount: waveform.pairCount,
                        duration: duration,
                        viewportWidth: geometry.size.width
                    )

                    ZStack(alignment: .leading) {
                        MacMusicWaveformTrack(
                            waveform: waveform,
                            stripWidth: stripWidth,
                            accent: accent,
                            secondaryAccent: secondaryAccent
                        )
                        .frame(height: geometry.size.height)
                        .offset(
                            x: (geometry.size.width / 2)
                                - (CGFloat(displayedPosition / safeDuration) * stripWidth)
                        )
                        edgeFades
                        playhead
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .leading
                    )
                    .contentShape(.rect)
                    .gesture(scrubGesture(stripWidth: stripWidth))
                    .clipped()
                }

                jumpButton(direction: 1, systemImage: "chevron.right")
            }
            .frame(height: 52)
            .background(PrismediaColor.background.opacity(0.82))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(accent.opacity(0.18))
                    .frame(height: PrismediaLayout.hairline)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Playback waveform")
            .accessibilityValue(
                "\(MusicPresentation.clockTime(displayedPosition)) of \(MusicPresentation.clockTime(duration))"
            )
            .accessibilityAdjustableAction { direction in
                let increment = max(5, duration / 40)
                switch direction {
                case .increment:
                    seek(to: displayedPosition + increment)
                case .decrement:
                    seek(to: displayedPosition - increment)
                @unknown default:
                    break
                }
            }
        }

        private var edgeFades: some View {
            HStack {
                LinearGradient(
                    colors: [PrismediaColor.background, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 48)
                Spacer()
                LinearGradient(
                    colors: [.clear, PrismediaColor.background],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 48)
            }
            .allowsHitTesting(false)
        }

        private var playhead: some View {
            Rectangle()
                .fill(accent)
                .frame(width: 2)
                .shadow(color: accent.opacity(0.72), radius: 4)
                .overlay(alignment: .top) {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(accent)
                        .rotationEffect(.degrees(180))
                        .offset(y: -1)
                }
                .overlay(alignment: .bottom) {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(accent)
                        .offset(y: 1)
                }
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
        }

        private func jumpButton(direction: Int, systemImage: String) -> some View {
            Button(direction < 0 ? "Scrub Back" : "Scrub Forward", systemImage: systemImage) {
                let step = max(0.5, safeDuration / 48)
                seek(to: displayedPosition + (Double(direction) * step))
            }
            .labelStyle(.iconOnly)
            .font(.caption.bold())
            .foregroundStyle(PrismediaColor.textMuted)
            .frame(width: 32, height: 52)
            .contentShape(.rect)
        }

        private func scrubGesture(stripWidth: CGFloat) -> some Gesture {
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    let start = dragStartPosition ?? displayedPosition
                    if dragStartPosition == nil { dragStartPosition = start }
                    let next = MacMusicWaveformLayout.time(
                        from: start,
                        translation: value.translation.width,
                        stripWidth: stripWidth,
                        duration: safeDuration
                    )
                    previewPosition = next
                    onSeek(next)
                }
                .onEnded { _ in
                    if let previewPosition { onSeek(previewPosition) }
                    dragStartPosition = nil
                    self.previewPosition = nil
                }
        }

        private var safeDuration: Double { max(duration, 0.001) }

        private var displayedPosition: Double {
            min(max(previewPosition ?? position, 0), safeDuration)
        }

        private func seek(to value: Double) {
            onSeek(min(max(value, 0), safeDuration))
        }
    }

    #if DEBUG
        #Preview("Mac Music Waveform Strip") {
            MacMusicWaveformStrip(
                waveform: MusicWaveformPreviewLoader.waveform,
                position: 42,
                duration: 240,
                accent: PrismediaColor.materialSpectrumGreen,
                secondaryAccent: PrismediaColor.materialSpectrumCyan,
                onSeek: { _ in }
            )
            .frame(width: 520)
        }
    #endif
#endif
