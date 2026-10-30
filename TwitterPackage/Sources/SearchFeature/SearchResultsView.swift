import ComposableArchitecture
import FeedFeature
import SwiftUI
import TwitterUI
import UserListFeature

/// The tab on screen, with Twitter's Top, Latest, People and Media tabs over it.
struct SearchResultsView: View {
    @Bindable var store: StoreOf<SearchResults>

    var body: some View {
        Group {
            if let source = store.tab.source(for: store.query),
                let feedStore = store.scope(state: \.feeds[id: source], action: \.feeds[id: source])
            {
                FeedView(store: feedStore)
                    .id(source)
            } else {
                UserListView(store: store.scope(state: \.people, action: \.people))
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                ClassicSegmentedControl(SearchResults.Tab.allCases, selection: $store.tab.animation(.snappy)) { tab in
                    Text(tab.title)
                }
                .accessibilityLabel("Results")
                .frame(maxWidth: 360)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
}
