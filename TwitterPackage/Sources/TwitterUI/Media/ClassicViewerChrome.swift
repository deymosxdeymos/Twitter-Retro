import SwiftUI

/// iPhone OS's black translucent bar (`UIBarStyleBlackTranslucent`), as the Photos app and Tweetie's image viewer drew
/// it over full-screen media: smoked glass with a faint light along its top edge.
struct ClassicBlackBar<Leading: View, Title: View, Trailing: View>: View {
    @ViewBuilder var leading: Leading
    @ViewBuilder var title: Title
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            title
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 0, y: -1)

            HStack {
                leading
                Spacer(minLength: 8)
                trailing
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 44)
        .background {
            ClassicBlackBarBackground().ignoresSafeArea(edges: .top)
        }
    }
}

/// The black bar's material, for the bar and the strip at the bottom of the viewer.
struct ClassicBlackBarBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(white: 0.16).opacity(0.82), Color(white: 0).opacity(0.72)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Color.white.opacity(0.14).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Color.black.opacity(0.7).frame(height: 1)
        }
    }
}

/// A bordered bar button on the black bar: a smoked, glossy lozenge with white text, brighter while pressed.
struct ClassicBlackBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        configuration.label
            .font(.subheadline.weight(.bold))
            .labelStyle(.iconOnly)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.7), radius: 0, y: -1)
            .padding(.horizontal, 10)
            .frame(minWidth: 44, minHeight: 30)
            .background {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color(white: 0.42), Color(white: 0.26)], startPoint: .top, endPoint: .bottom)
                    LinearGradient(
                        colors: [Color(white: 0.14), Color(white: 0.2)], startPoint: .top, endPoint: .bottom)
                }
                .brightness(configuration.isPressed ? 0.12 : 0)
                .clipShape(shape)
                .overlay { shape.stroke(.black.opacity(0.85), lineWidth: 1) }
                .overlay {
                    shape.inset(by: 1).stroke(.white.opacity(0.18), lineWidth: 0.5)
                }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
    }
}

/// The old player's scrubber: a dark groove filled blue up to the playhead, with a glossy white knob. VoiceOver gets a
/// standard slider in its place.
struct ClassicScrubber: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void

    @State private var isDragging = false
    private let knob: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let span = max(range.upperBound - range.lowerBound, .ulpOfOne)
            let fraction = min(max((value - range.lowerBound) / span, 0), 1)
            let x = knob / 2 + (width - knob) * fraction
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.05), Color(white: 0.3)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay { Capsule().stroke(.black.opacity(0.8), lineWidth: 0.5) }
                    .frame(height: 8)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.66, blue: 0.98), Color(red: 0.1, green: 0.38, blue: 0.86)
                            ],
                            startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: max(x, 8), height: 8)

                Circle()
                    .fill(LinearGradient(colors: [.white, Color(white: 0.8)], startPoint: .top, endPoint: .bottom))
                    .overlay { Circle().stroke(.black.opacity(0.45), lineWidth: 0.5) }
                    .shadow(color: .black.opacity(0.5), radius: 1.5, y: 1)
                    .frame(width: knob, height: knob)
                    .scaleEffect(isDragging ? 1.15 : 1)
                    .offset(x: x - knob / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        let fraction = min(max((drag.location.x - knob / 2) / max(width - knob, 1), 0), 1)
                        value = range.lowerBound + span * fraction
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 44)
        .accessibilityRepresentation {
            Slider(value: $value, in: range, onEditingChanged: onEditingChanged)
        }
    }
}
