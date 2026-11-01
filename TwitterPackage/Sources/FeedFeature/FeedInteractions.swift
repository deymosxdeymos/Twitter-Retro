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
            .alert($store.scope(state: \.alert, action: \.alert))
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
