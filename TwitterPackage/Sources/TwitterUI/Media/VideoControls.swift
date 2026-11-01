import SwiftUI

/// The old movie player's floating panel, brought down to the thumb: a smoked, rounded slab with play/pause, elapsed
/// time, a blue-filled scrubber, the time left, and sound on or off, in one row.
struct VideoControls: View {
    let playback: VideoPlayback
    @State private var scrubbedTime: Double?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        HStack(spacing: 10) {
            Button {
                playback.togglePlaying()
            } label: {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .regular))
                    .frame(width: 36, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel(playback.isPlaying ? "Pause" : "Play")

            let duration = playback.duration ?? 0
            let time = scrubbedTime ?? playback.currentTime
            Text(Self.format(time))
                .font(.caption.weight(.semibold).monospacedDigit())
                .accessibilityHidden(true)

            ClassicScrubber(
                value: Binding(
                    get: { min(time, max(duration, 0.01)) },
                    set: { scrubbedTime = $0 }
                ),
                range: 0...max(duration, 0.01)
            ) { isEditing in
                if !isEditing, let scrubbedTime {
                    playback.seek(to: scrubbedTime)
                    self.scrubbedTime = nil
                }
            }
            .disabled(duration == 0)
            .accessibilityLabel("Playback position")
            .accessibilityValue(Text("\(Self.format(time)) of \(Self.format(duration))"))

            Text("-" + Self.format(max(duration - time, 0)))
                .font(.caption.weight(.semibold).monospacedDigit())
                .accessibilityHidden(true)

            Button {
                playback.isMuted.toggle()
            } label: {
                Image(systemName: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 17))
                    .frame(width: 36, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel(playback.isMuted ? "Turn Sound On" : "Turn Sound Off")
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.6), radius: 0, y: -1)
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background {
            shape
                .fill(Color.black.opacity(0.62))
                .overlay {
                    // The panel's gloss: lighter across its upper half.
                    shape.fill(
                        LinearGradient(
                            colors: [.white.opacity(0.16), .white.opacity(0.04), .clear],
                            startPoint: .top, endPoint: .center))
                }
                .overlay { shape.stroke(.white.opacity(0.28), lineWidth: 1) }
                .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
        }
    }

    /// `1:05`, or `1:02:05` past an hour.
    static func format(_ seconds: Double) -> String {
        let total = seconds.isFinite ? max(Int(seconds.rounded(.down)), 0) : 0
        let hours = total / 3600
        let minutes = total / 60 % 60
        let rest = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest) : String(format: "%d:%02d", minutes, rest)
    }
}
