import SwiftUI
import UIKit

/// Place inside the scroll content, so only that scroll view's system spinner is hidden.
package struct ClassicRefreshControlStyle: UIViewRepresentable {
    package init() {}

    package func makeUIView(context: Context) -> SpinnerStyleView {
        SpinnerStyleView()
    }

    package func updateUIView(_ view: SpinnerStyleView, context: Context) {
        view.updateRefreshControl()
    }

    package static func dismantleUIView(_ view: SpinnerStyleView, coordinator: ()) {
        view.restoreTint()
    }

    package final class SpinnerStyleView: UIView {
        private weak var styledControl: UIRefreshControl?
        private var originalTint: UIColor?

        package override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil {
                restoreTint()
            } else {
                updateRefreshControl()
            }
        }

        package override func layoutSubviews() {
            super.layoutSubviews()
            updateRefreshControl()
        }

        func updateRefreshControl() {
            var ancestor = superview
            while let view = ancestor {
                if let scrollView = view as? UIScrollView {
                    guard let control = scrollView.refreshControl else { return }
                    if styledControl !== control {
                        restoreTint()
                        originalTint = control.tintColor
                        styledControl = control
                    }
                    control.tintColor = .clear
                    return
                }
                ancestor = view.superview
            }
        }

        func restoreTint() {
            styledControl?.tintColor = originalTint
            styledControl = nil
            originalTint = nil
        }
    }
}
