import SwiftUI

/// Hosts a classic overlay (the action sheet, the alert) over everything, in a clear full-screen cover that appears
/// and goes without animating: the overlay animates its own dimming and entrance. The overlay calls `close` with the
/// chosen action, which runs once the cover is gone, so it can present something of its own.
struct ClassicOverlayPresenter<Overlay: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let overlay: (_ close: @escaping ((() -> Void)?) -> Void) -> Overlay
    @State private var isCovering = false
    @State private var pending: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented, initial: true) { _, isPresented in
                guard isPresented != isCovering else { return }
                withoutAnimation { isCovering = isPresented }
            }
            .fullScreenCover(isPresented: $isCovering, onDismiss: finish) {
                overlay { action in
                    pending = action
                    withoutAnimation { isCovering = false }
                }
                .presentationBackground(.clear)
            }
    }

    /// The action goes first, while whatever presented the overlay still considers it open; its own state may close
    /// it.
    private func finish() {
        let action = pending
        pending = nil
        action?()
        isPresented = false
    }

    private func withoutAnimation(_ body: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
    }
}
