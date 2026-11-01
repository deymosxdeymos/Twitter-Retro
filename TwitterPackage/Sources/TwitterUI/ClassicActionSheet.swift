import SwiftUI

/// One button in a ``View/classicActionSheet(isPresented:actions:)``.
package struct ClassicActionSheetAction: Identifiable {
    package let id: String
    let title: String
    let isDestructive: Bool
    let perform: () -> Void

    package init(_ title: String, isDestructive: Bool = false, perform: @escaping () -> Void) {
        self.id = title
        self.title = title
        self.isDestructive = isDestructive
        self.perform = perform
    }
}

extension View {
    /// iPhone OS 3's `UIActionSheet`: the page dims and a slate tray rises with stacked glossy buttons, the dark Cancel
    /// set apart at the bottom. The chosen action runs after the sheet is gone, so it can present a sheet of its own.
    package func classicActionSheet(isPresented: Binding<Bool>, actions: [ClassicActionSheetAction]) -> some View {
        modifier(ClassicActionSheetModifier(isPresented: isPresented, actions: actions))
    }
}

private struct ClassicActionSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let actions: [ClassicActionSheetAction]
    @State private var isCovering = false
    @State private var pending: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented, initial: true) { _, isPresented in
                guard isPresented != isCovering else { return }
                // The cover only hosts the sheet; the dimming and slide are the sheet's own animation.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { isCovering = isPresented }
            }
            .fullScreenCover(isPresented: $isCovering, onDismiss: finish) {
                ClassicActionSheet(actions: actions) { action in
                    pending = action?.perform
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { isCovering = false }
                }
                .presentationBackground(.clear)
            }
    }

    /// The action goes first, while whatever presented the sheet still considers it open; its own state may close it.
    private func finish() {
        let action = pending
        pending = nil
        action?()
        isPresented = false
    }
}

private struct ClassicActionSheet: View {
    let actions: [ClassicActionSheetAction]
    let close: (ClassicActionSheetAction?) -> Void
    @State private var isShown = false
    @State private var isClosing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(isShown ? 0.45 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss(nil) }
                .accessibilityHidden(true)

            if isShown {
                tray
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { isShown = true }
        }
        .accessibilityAction(.escape) { dismiss(nil) }
    }

    private var tray: some View {
        VStack(spacing: 10) {
            ForEach(actions) { action in
                Button(action.title) { dismiss(action) }
                    .buttonStyle(ClassicSheetButtonStyle(kind: action.isDestructive ? .destructive : .normal))
            }

            Button("Cancel") { dismiss(nil) }
                .buttonStyle(ClassicSheetButtonStyle(kind: .cancel))
                .keyboardShortcut(.cancelAction)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
        .background {
            SlateTray().ignoresSafeArea(edges: .bottom)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func dismiss(_ action: ClassicActionSheetAction?) {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(.easeIn(duration: 0.2)) {
            isShown = false
        } completion: {
            close(action)
        }
    }
}

/// The sheet's translucent blue-grey slab, lit along its top edge.
private struct SlateTray: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.36, green: 0.40, blue: 0.47),
                Color(red: 0.20, green: 0.23, blue: 0.29),
                Color(red: 0.13, green: 0.15, blue: 0.19)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(0.97)
        .overlay(alignment: .top) {
            VStack(spacing: 0) {
                Color.black.opacity(0.6).frame(height: 1)
                Color.white.opacity(0.35).frame(height: 1)
            }
        }
    }
}

private struct ClassicSheetButtonStyle: ButtonStyle {
    enum Kind {
        case normal, destructive, cancel
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        let isLight = kind == .normal && !configuration.isPressed
        configuration.label
            .font(.title3.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(isLight ? Color(white: 0.08) : .white)
            .shadow(
                color: isLight ? .white.opacity(0.9) : .black.opacity(0.55),
                radius: 0,
                y: isLight ? 1 : -1
            )
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background { Gloss(colors: colors(isPressed: configuration.isPressed)) }
            .contentShape(.rect(cornerRadius: 10))
    }

    /// Top-half and bottom-half gradients, split by the gloss line. Any pressed button turns the old selection blue.
    private func colors(isPressed: Bool) -> (top: [Color], bottom: [Color]) {
        if isPressed {
            return (
                [Color(red: 0.47, green: 0.65, blue: 0.96), Color(red: 0.25, green: 0.48, blue: 0.91)],
                [Color(red: 0.12, green: 0.38, blue: 0.86), Color(red: 0.16, green: 0.45, blue: 0.90)]
            )
        }
        switch kind {
        case .normal:
            return (
                [Color(white: 1), Color(white: 0.95)],
                [Color(white: 0.88), Color(white: 0.93)]
            )
        case .destructive:
            return (
                [Color(red: 0.93, green: 0.45, blue: 0.43), Color(red: 0.85, green: 0.22, blue: 0.20)],
                [Color(red: 0.74, green: 0.07, blue: 0.06), Color(red: 0.80, green: 0.13, blue: 0.11)]
            )
        case .cancel:
            return (
                [Color(red: 0.42, green: 0.45, blue: 0.51), Color(red: 0.29, green: 0.31, blue: 0.36)],
                [Color(red: 0.15, green: 0.17, blue: 0.20), Color(red: 0.20, green: 0.22, blue: 0.26)]
            )
        }
    }
}

private struct Gloss: View {
    let colors: (top: [Color], bottom: [Color])

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        VStack(spacing: 0) {
            LinearGradient(colors: colors.top, startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: colors.bottom, startPoint: .top, endPoint: .bottom)
        }
        .clipShape(shape)
        .overlay {
            shape
                .inset(by: 1)
                .stroke(.white.opacity(0.35), lineWidth: 1)
                .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
        }
        .overlay { shape.stroke(.black.opacity(0.75), lineWidth: 1) }
        .shadow(color: .white.opacity(0.18), radius: 0, y: 1)
    }
}
