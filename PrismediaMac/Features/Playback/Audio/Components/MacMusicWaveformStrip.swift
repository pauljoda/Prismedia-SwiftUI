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

                    ZStack {
                        waveformCanvas(
                            viewportSize: geometry.size,
                            stripWidth: stripWidth
                        )
                        edgeFades
                        playhead
                    }
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

        private func waveformCanvas(
            viewportSize: CGSize,
            stripWidth: CGFloat
        ) -> some View {
            Canvas { context, size in
                guard waveform.pairCount > 0, stripWidth > 0 else { return }
                let centerY = size.height / 2
                let sampleWidth = stripWidth / CGFloat(waveform.pairCount)
                let maximumAmplitude = waveform.maximumAmplitude
                let activeX = CGFloat(displayedPosition / safeDuration) * stripWidth
                let offset = (viewportSize.width / 2) - activeX
                let visibleStart = max(0, Int(floor(-offset / sampleWidth)) - 1)
                let visibleEnd = min(
                    waveform.pairCount - 1,
                    Int(ceil((viewportSize.width - offset) / sampleWidth)) + 1
                )
                guard visibleStart <= visibleEnd else { return }

                for index in visibleStart...visibleEnd {
                    let minimum = waveform.samples[index * 2] / maximumAmplitude
                    let maximum = waveform.samples[(index * 2) + 1] / maximumAmplitude
                    let barTop = centerY - CGFloat(maximum) * centerY * 0.88
                    let barBottom = centerY - CGFloat(minimum) * centerY * 0.88
                    let intensity = (abs(minimum) + abs(maximum)) / 2
                    let color =
                        intensity > 0.35
                        ? secondaryAccent.opacity(0.52)
                        : accent.opacity(0.24)
                    let rect = CGRect(
                        x: offset + (CGFloat(index) * sampleWidth),
                        y: barTop,
                        width: max(1, sampleWidth - 0.5),
                        height: max(1, barBottom - barTop)
                    )
                    context.fill(Path(rect), with: .color(color))
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
