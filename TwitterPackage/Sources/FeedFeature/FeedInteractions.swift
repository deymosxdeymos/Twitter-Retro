import ComposableArchitecture
import SwiftUI
import Translation
import TwitterUI

private struct FeedInteractions: ViewModifier {
    /// About how far the system's refresh control is pulled before it triggers.
    private static let refreshTriggerDistance: CGFloat = 80

    @Bindable var store: StoreOf<FeedFeature>
    /// The pull catching, releasing, then the timeline landing: Twitter for iPad's "psst", "psst" and "pop". The
    /// refresh control plays its own haptics.
    @State private var isPastRefreshTrigger = false
    @State private var pull = PullToRefresh()

    func body(content: Content) -> some View {
        content
            .refreshable {
                pull.isRefreshing = true
                ClassicSound.psst2.play()
                await store.send(.refreshPulled).finish()
                ClassicSound.pop.play()
                pull.isRefreshing = false
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y < -(geometry.contentInsets.top + Self.refreshTriggerDistance)
            } action: { _, isPast in
                if isPast, !isPastRefreshTrigger { ClassicSound.psst1.play() }
                isPastRefreshTrigger = isPast
            }
            .onScrollGeometryChange(for: PullGeometry.self) { geometry in
                PullGeometry(
                    distance: max(-(geometry.contentOffset.y + geometry.contentInsets.top), 0),
                    topInset: geometry.contentInsets.top
                )
            } action: { _, geometry in
                if !pull.isRefreshing { pull.restingTopInset = geometry.topInset }
                pull.distance = geometry.distance + geometry.topInset - pull.restingTopInset
            }
            .onScrollPhaseChange { _, phase in
                pull.isDragging = phase == .interacting
            }
            .overlay(alignment: .top) {
                PullToRefreshHeader(pull: pull, store: store)
            }
            .onAppear { ClassicPullToRefresh.hideSystemSpinner() }
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

private struct PullGeometry: Equatable {
    var distance: CGFloat
    var topInset: CGFloat
}

@Observable
private final class PullToRefresh {
    var distance: CGFloat = 0
    var restingTopInset: CGFloat = 0
    var isDragging = false
    var isRefreshing = false
}

private struct PullToRefreshHeader: View {
    let pull: PullToRefresh
    let store: StoreOf<FeedFeature>

    var body: some View {
        if pull.distance > 0 {
            ClassicPullToRefresh(
                phase: pull.isRefreshing ? (pull.isDragging ? .release : .loading) : .pull,
                lastUpdated: store.lastRefreshed,
                height: pull.distance
            )
        }
    }
}

extension View {
    func feedInteractions(store: StoreOf<FeedFeature>) -> some View {
        modifier(FeedInteractions(store: store))
    }
}
