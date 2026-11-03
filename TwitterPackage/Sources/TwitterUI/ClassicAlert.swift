import SwiftUI

/// One button in a ``View/classicAlert(_:message:isPresented:buttons:)``.
package struct ClassicAlertButton: Identifiable {
    package enum Role {
        case cancel
        case destructive
    }

    package let id: String
    let title: String
    let role: Role?
    let perform: () -> Void

    package init(_ title: String, role: Role? = nil, perform: @escaping () -> Void = {}) {
        self.id = title
        self.title = title
        self.role = role
        self.perform = perform
    }
}

extension View {
    /// iPhone OS's `UIAlertView`: a smoked-blue glass panel ringed in white pops up over the dimmed page, with its
    /// glossy buttons side by side (Cancel on the left) or stacked when there are more than two. The chosen action
    /// runs after the alert is gone. With no buttons, it offers OK.
    package func classicAlert(
        _ title: String, message: String? = nil, isPresented: Binding<Bool>, buttons: [ClassicAlertButton] = []
    ) -> some View {
        modifier(
            ClassicOverlayPresenter(isPresented: isPresented) { close in
                ClassicAlert(
                    title: title, message: message, buttons: buttons.isEmpty ? [ClassicAlertButton("OK")] : buttons
                ) { close($0?.perform) }
            })
    }
}

private struct ClassicAlert: View {
    let title: String
    let message: String?
    let buttons: [ClassicAlertButton]
    let close: (ClassicAlertButton?) -> Void
    @State private var isShown = false
    @State private var isClosing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Cancel first, as iPhone OS laid them out.
    private var ordered: [ClassicAlertButton] {
        buttons.filter { $0.role == .cancel } + buttons.filter { $0.role != .cancel }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isShown ? 0.32 : 0)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            panel
                .scaleEffect(reduceMotion || isShown ? 1 : (isClosing ? 0.96 : 1.12))
                .opacity(isShown ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.32, dampingFraction: 0.72)) {
                isShown = true
            }
        }
        .accessibilityAction(.escape) {
            if let cancel = buttons.first(where: { $0.role == .cancel }) { dismiss(cancel) }
        }
    }

    /// The old alert's navy glass, made the modern way: the page blurred behind it, then tinted, under a crisp rim
    /// and a soft gloss, with rounder corners and a deeper, softer shadow than iPhone OS drew.
    private var panel: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if let message, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                }
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 0, y: -1)
            .fixedSize(horizontal: false, vertical: true)

            if ordered.count == 2 {
                HStack(spacing: 10) { buttonViews }
            } else {
                VStack(spacing: 8) { buttonViews }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(width: 290)
        .background {
            shape.fill(.ultraThinMaterial)
                .overlay {
                    shape.fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.17, green: 0.27, blue: 0.48).opacity(0.82),
                                Color(red: 0.05, green: 0.12, blue: 0.29).opacity(0.9)
                            ],
                            startPoint: .top, endPoint: .bottom)
                    )
                }
                // The gloss: a broad sheen over the top, curving down at its edge as the old alert's did. An overlay,
                // so its width never sizes the panel.
                .overlay(alignment: .top) {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .white.opacity(0.03)], startPoint: .top,
                                endPoint: .bottom)
                        )
                        .frame(width: 420, height: 90)
                        .offset(y: -40)
                }
                .clipShape(shape)
                .environment(\.colorScheme, .dark)
                .overlay { shape.strokeBorder(.white.opacity(0.85), lineWidth: 1.5) }
                .overlay { shape.inset(by: 1.5).stroke(.black.opacity(0.35), lineWidth: 0.5) }
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var buttonViews: some View {
        ForEach(ordered) { button in
            Button(button.title) { dismiss(button) }
                .buttonStyle(
                    AlertButtonStyle(
                        role: button.role, isDefault: button.id == ordered.last?.id && button.role != .cancel)
                )
                .keyboardShortcut(
                    button.role == .cancel ? .cancelAction : (button.id == ordered.last?.id ? .defaultAction : nil))
        }
    }

    private func dismiss(_ button: ClassicAlertButton?) {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(.easeIn(duration: 0.14)) {
            isShown = false
        } completion: {
            close(button)
        }
    }
}

/// The alert's buttons: glass lozenges on the navy, lit across their top half. The default one is a little brighter,
/// Cancel a little darker. Old alerts had no red buttons; a destructive choice gets a soft red title instead, as
/// modern alerts mark it.
private struct AlertButtonStyle: ButtonStyle {
    let role: ClassicAlertButton.Role?
    let isDefault: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        configuration.label
            .font(isDefault ? .headline : .body.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(role == .destructive ? Color(red: 1, green: 0.6, blue: 0.58) : .white)
            .shadow(color: .black.opacity(0.5), radius: 0, y: -1)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                VStack(spacing: 0) {
                    LinearGradient(colors: top, startPoint: .top, endPoint: .bottom)
                    LinearGradient(colors: bottom, startPoint: .top, endPoint: .bottom)
                }
                .brightness(configuration.isPressed ? 0.1 : 0)
                .clipShape(shape)
                .overlay { shape.stroke(.black.opacity(0.4), lineWidth: 1) }
                .overlay { shape.inset(by: 1).stroke(.white.opacity(0.22), lineWidth: 0.5) }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
            .contentShape(shape)
    }

    private var top: [Color] {
        role == .cancel
            ? [.white.opacity(0.2), .white.opacity(0.1)]
            : isDefault ? [.white.opacity(0.42), .white.opacity(0.26)] : [.white.opacity(0.3), .white.opacity(0.18)]
    }

    private var bottom: [Color] {
        role == .cancel
            ? [.white.opacity(0.03), .white.opacity(0.06)]
            : isDefault ? [.white.opacity(0.14), .white.opacity(0.2)] : [.white.opacity(0.08), .white.opacity(0.13)]
    }
}
