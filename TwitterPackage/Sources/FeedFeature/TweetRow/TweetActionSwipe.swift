import SwiftUI
import UIKit

/// Decide the axis before recognizing, so a vertical scroll isn't captured by a SwiftUI DragGesture.
struct TweetActionSwipe: UIGestureRecognizerRepresentable {
    let isOpen: Bool
    let isEnabled: Bool
    let onSwipe: (Bool) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.name = "classic.tweet-actions"
        recognizer.maximumNumberOfTouches = 1
        recognizer.isEnabled = isEnabled
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.isOpen = isOpen
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard recognizer.state == .ended else { return }
        let translation = recognizer.translation(in: recognizer.view)
        guard abs(translation.x) >= 55, abs(translation.x) > abs(translation.y) * 1.5 else { return }
        onSwipe(translation.x < 0)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(isOpen: isOpen)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isOpen: Bool
        private var startX: CGFloat = 0

        init(isOpen: Bool) {
            self.isOpen = isOpen
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            startX = touch.location(in: gestureRecognizer.view).x
            // Leave carousels and native controls their own horizontal gestures.
            var ancestor = touch.view
            while let view = ancestor, view !== gestureRecognizer.view {
                if view is UIControl || view is UITextView { return false }
                if let scroll = view as? UIScrollView, scroll.contentSize.width > scroll.bounds.width + 1 {
                    return false
                }
                ancestor = view.superview
            }
            return true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            return Self.canBegin(velocity: pan.velocity(in: pan.view), startX: startX, isOpen: isOpen)
        }

        static func canBegin(velocity: CGPoint, startX: CGFloat, isOpen: Bool) -> Bool {
            guard startX > 36, abs(velocity.x) > abs(velocity.y) * 1.5 else { return false }
            return velocity.x < 0 || isOpen
        }
    }
}
