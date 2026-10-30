import SwiftUI
import UIKit

package enum Appearance: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    package static let settingKey = "appearance"

    package var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    fileprivate var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

extension View {
    package func appliesAppearance() -> some View {
        modifier(AppliesAppearance())
    }
}

private struct AppliesAppearance: ViewModifier {
    @AppStorage(Appearance.settingKey) private var appearance = Appearance.system

    func body(content: Content) -> some View {
        content.background {
            WindowStyle(style: appearance.interfaceStyle)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
    }
}

private struct WindowStyle: UIViewRepresentable {
    let style: UIUserInterfaceStyle

    func makeUIView(context: Context) -> StyleView {
        StyleView()
    }

    func updateUIView(_ view: StyleView, context: Context) {
        view.style = style
    }

    final class StyleView: UIView {
        var style = UIUserInterfaceStyle.unspecified {
            didSet { apply(animated: true) }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply(animated: false)
        }

        private func apply(animated: Bool) {
            guard let window, window.overrideUserInterfaceStyle != style else { return }
            guard animated, !UIAccessibility.isReduceMotionEnabled else {
                window.overrideUserInterfaceStyle = style
                return
            }
            let style = style
            UIView.transition(with: window, duration: 0.25, options: [.transitionCrossDissolve, .curveEaseOut]) {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
