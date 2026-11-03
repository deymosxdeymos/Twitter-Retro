import ComposableArchitecture
import SwiftUI
import Translation
import TwitterUI

private struct FeedInteractions: ViewModifier {
    @Bindable var store: StoreOf<FeedFeature>
    @State private var trays = TweetActionTrayState()

    func body(content: Content) -> some View {
        content
            .classicRefreshable(lastUpdated: store.lastRefreshed) {
                await store.send(.refreshPulled).finish()
                return store.errorMessage == nil
            }
            .environment(\.tweetActionTray, trays)
            .onScrollPhaseChange { _, phase in
                if phase == .interacting { trays.tweetID = nil }
            }
            .task { store.send(.task) }
            .classicAlert(store.alert) { store.send(.alert($0)) }
            .translationPresentation(
                isPresented: Binding {
                    store.translating != nil
                } set: { isPresented in
                    if !isPresented { store.send(.translationDismissed) }
                },
                text: store.translating?.text ?? ""
            )
            .environment(
                \.openURL,
                OpenURLAction { url in
                    store.send(.linkTapped(url))
                    return .handled
                })
    }
}

extension View {
    func feedInteractions(store: StoreOf<FeedFeature>) -> some View {
        modifier(FeedInteractions(store: store))
    }
}

extension View {
    /// A TCA `AlertState` shown as ``View/classicAlert(_:message:isPresented:buttons:)``: its title, message and
    /// buttons, with dismissal and each button's action sent back as presentation actions.
    func classicAlert<Action>(
        _ alert: AlertState<Action>?, send: @escaping (PresentationAction<Action>) -> Void
    ) -> some View {
        classicAlert(
            alert.map { String(state: $0.title) } ?? "",
            message: alert?.message.map { String(state: $0) },
            isPresented: Binding(
                get: { alert != nil },
                set: { if !$0, alert != nil { send(.dismiss) } }
            ),
            buttons: (alert?.buttons ?? []).map { button in
                ClassicAlertButton(
                    String(state: button.label),
                    role: button.role == .cancel ? .cancel : button.role == .destructive ? .destructive : nil
                ) {
                    button.withAction { action in
                        if let action { send(.presented(action)) }
                    }
                }
            }
        )
    }
}
