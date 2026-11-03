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
    @State private var phase = Phase.hidden
    @State private var isClosing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase {
        case hidden, overshoot, shown
    }

    /// Cancel first, as iPhone OS laid them out.
    private var ordered: [ClassicAlertButton] {
        buttons.filter { $0.role == .cancel } + buttons.filter { $0.role != .cancel }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(phase == .hidden ? 0 : 0.4)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            panel
                .scaleEffect(reduceMotion ? 1 : scale)
                .opacity(phase == .hidden ? 0 : 1)
        }
        .onAppear(perform: show)
        .accessibilityAction(.escape) {
            if let cancel = buttons.first(where: { $0.role == .cancel }) { dismiss(cancel) }
        }
    }

    private var scale: CGFloat {
        switch phase {
        case .hidden: 0.8
        case .overshoot: 1.05
        case .shown: 1
        }
    }

    private var panel: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if let message, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                }
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 0, y: -1)
            .fixedSize(horizontal: false, vertical: true)

            if ordered.count == 2 {
                HStack(spacing: 10) { buttonViews }
            } else {
                VStack(spacing: 8) { buttonViews }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .frame(width: 284)
        .background {
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.24, blue: 0.43).opacity(0.94),
                            Color(red: 0.05, green: 0.11, blue: 0.27).opacity(0.94)
                        ],
                        startPoint: .top, endPoint: .bottom)
                )
                .overlay(alignment: .top) {
                    // The panel's gloss: a broad, soft-edged sheen over its top.
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.28), .white.opacity(0.06)], startPoint: .top,
                                endPoint: .bottom)
                        )
                        .frame(height: 70)
                        .offset(y: -28)
                        .clipShape(shape)
                }
                .overlay { shape.strokeBorder(.white.opacity(0.92), lineWidth: 2) }
                .shadow(color: .black.opacity(0.55), radius: 10, y: 5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var buttonViews: some View {
        ForEach(ordered) { button in
            Button(button.title) { dismiss(button) }
                .buttonStyle(AlertButtonStyle(role: button.role))
                .keyboardShortcut(
                    button.role == .cancel ? .cancelAction : (button.id == ordered.last?.id ? .defaultAction : nil))
        }
    }

    private func show() {
        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.15)) { phase = .shown }
            return
        }
        withAnimation(.easeOut(duration: 0.14)) {
            phase = .overshoot
        } completion: {
            withAnimation(.easeInOut(duration: 0.1)) { phase = .shown }
        }
    }

    private func dismiss(_ button: ClassicAlertButton?) {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(.easeIn(duration: 0.15)) {
            phase = .hidden
        } completion: {
            close(button)
        }
    }
}

/// The alert's buttons: glassy lozenges on the blue, the Cancel one darker, a destructive one red.
private struct AlertButtonStyle: ButtonStyle {
    let role: ClassicAlertButton.Role?

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 0, y: -1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                VStack(spacing: 0) {
                    LinearGradient(colors: top, startPoint: .top, endPoint: .bottom)
                    LinearGradient(colors: bottom, startPoint: .top, endPoint: .bottom)
                }
                .brightness(configuration.isPressed ? -0.12 : 0)
                .clipShape(shape)
                .overlay { shape.stroke(.black.opacity(0.55), lineWidth: 1) }
                .overlay { shape.inset(by: 1).stroke(.white.opacity(0.25), lineWidth: 0.5) }
            }
            .contentShape(shape)
    }

    private var top: [Color] {
        switch role {
        case .cancel: [.white.opacity(0.24), .white.opacity(0.12)]
        case .destructive: [Color(red: 0.93, green: 0.42, blue: 0.40), Color(red: 0.82, green: 0.2, blue: 0.18)]
        case nil: [.white.opacity(0.4), .white.opacity(0.24)]
        }
    }

    private var bottom: [Color] {
        switch role {
        case .cancel: [.white.opacity(0.04), .white.opacity(0.08)]
        case .destructive: [Color(red: 0.7, green: 0.06, blue: 0.05), Color(red: 0.76, green: 0.1, blue: 0.09)]
        case nil: [.white.opacity(0.14), .white.opacity(0.2)]
        }
    }
}
