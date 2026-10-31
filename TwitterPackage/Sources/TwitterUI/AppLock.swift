import LocalAuthentication
import SwiftUI

extension View {
    package func appliesAppLock() -> some View {
        modifier(AppLock())
    }
}

private struct AppLock: ViewModifier {
    @AppStorage(RetroSettings.locksAppKey) private var locksApp = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLocked = UserDefaults.standard.bool(forKey: RetroSettings.locksAppKey)
    @State private var promptsWhenActive = false
    @State private var isAuthenticating = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if locksApp, isLocked || scenePhase != .active {
                    LockScreen(isLocked: isLocked, unlock: unlock)
                }
            }
            .task {
                if isLocked { unlock() }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background where locksApp:
                    isLocked = true
                    promptsWhenActive = true
                case .active where promptsWhenActive:
                    promptsWhenActive = false
                    unlock()
                default:
                    break
                }
            }
            .onChange(of: locksApp) {
                if !locksApp { isLocked = false }
            }
    }

    private func unlock() {
        guard locksApp, !isAuthenticating else {
            if !locksApp { isLocked = false }
            return
        }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isLocked = false
            return
        }
        isAuthenticating = true
        Task {
            let unlocked =
                (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Twitter"))
                ?? false
            isAuthenticating = false
            if unlocked { isLocked = false }
        }
    }
}

private struct LockScreen: View {
    let isLocked: Bool
    let unlock: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            TwitterIcon.twitter.image
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            if isLocked {
                Text("Twitter is locked")
                    .font(.headline)
                    .foregroundStyle(Color(.settingsHeaderText))
                    .shadow(color: Color(.settingsHeaderShadow), radius: 0, y: 1)

                Button("Unlock", action: unlock)
                    .buttonStyle(.classicProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
}
