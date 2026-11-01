import ComposableArchitecture
import Models
import SwiftUI
import TwitterUI

package struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>
    @FocusState private var isSearching: Bool

    package init(store: StoreOf<SearchFeature>) {
        self.store = store
    }

    package var body: some View {
        VStack(spacing: 0) {
            ClassicSearchBar(
                text: $store.query,
                isFocused: $isSearching,
                isSaved: store.isSubmittedQuerySaved,
                submit: {
                    isSearching = false
                    store.send(.searchSubmitted)
                },
                toggleSaved: { store.send(.saveSearchButtonTapped, animation: .snappy) },
                cancel: {
                    isSearching = false
                    // Back to the search on screen, or to Explore if there wasn't one.
                    store.query = store.submittedQuery ?? ""
                }
            )

            ZStack {
                let isSuggesting = isSearching && store.suggestionQuery != nil
                content
                    .accessibilityHidden(isSuggesting)

                if isSuggesting {
                    SuggestionsList(
                        query: store.query,
                        suggestions: store.suggestions,
                        search: {
                            isSearching = false
                            store.send(.searchSubmitted)
                        },
                        select: { user in
                            isSearching = false
                            store.send(.suggestionTapped(user))
                        }
                    )
                }
            }
            .frame(maxHeight: .infinity)
        }
        .task { store.send(.task) }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if let resultsStore = store.scope(state: \.results, action: \.results.presented) {
            SearchResultsView(store: resultsStore)
        } else if !store.trends.isEmpty || !store.recentSearches.isEmpty || !store.savedSearches.isEmpty {
            ExploreList(
                savedSearches: store.savedSearches,
                recentSearches: store.recentSearches,
                trends: store.trends,
                search: { store.send(.recentSearchTapped($0)) },
                deleteSaved: { store.send(.savedSearchDeleted($0), animation: .snappy) },
                clearRecentSearches: { store.send(.clearRecentSearchesButtonTapped, animation: .snappy) },
                select: { store.send(.trendTapped($0)) }
            )
        } else if !store.hasLoadedTrends {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView(
                "Search Twitter",
                twitterIcon: .searchStroke,
                description: Text("Find Tweets, people, and #topics.")
            )
        }
    }
}

/// What's typed, as a search to run, then the accounts it matches, over whatever was on screen.
private struct SuggestionsList: View {
    let query: String
    let suggestions: [User]
    let search: () -> Void
    let select: (User) -> Void

    var body: some View {
        List {
            Button(action: search) {
                Label("Search for “\(query)”", twitterIcon: .searchStroke)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)

            ForEach(suggestions) { user in
                Button {
                    select(user)
                } label: {
                    HStack(spacing: 10) {
                        Avatar(user: user, size: 36)

                        AuthorLine(user: user, date: nil, layout: .stacked)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(.rect)
                    .tweetMetrics()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(user.name), @\(user.screenName)")
            }
        }
        .listStyle(.plain)
        .background(.background)
    }
}

/// Explore before a search, as Twitter 4.x's Search tab: saved searches, recent ones, then trends, each under a plain
/// table's gradient header.
private struct ExploreList: View {
    let savedSearches: [String]
    let recentSearches: [String]
    let trends: [Trend]
    let search: (String) -> Void
    let deleteSaved: (String) -> Void
    let clearRecentSearches: () -> Void
    let select: (Trend) -> Void

    var body: some View {
        List {
            if !savedSearches.isEmpty {
                Section {
                    ForEach(savedSearches, id: \.self) { query in
                        queryRow(query, icon: .bookmarkStroke)
                            .swipeActions {
                                Button("Delete", role: .destructive) { deleteSaved(query) }
                            }
                            .contextMenu {
                                Button("Remove Saved Search", twitterIcon: .trash, role: .destructive) {
                                    deleteSaved(query)
                                }
                            }
                    }
                } header: {
                    header("Saved Searches")
                }
            }

            if !recentSearches.isEmpty {
                Section {
                    ForEach(recentSearches, id: \.self) { query in
                        queryRow(query, icon: .searchStroke)
                    }
                } header: {
                    header("Recent") {
                        Button("Clear", action: clearRecentSearches)
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear Recent Searches")
                    }
                }
            }

            if !trends.isEmpty {
                Section {
                    ForEach(trends) { trend in
                        Button {
                            select(trend)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trend.name)
                                    .font(.body.weight(.bold))

                                if let detail = [trend.context, trend.volume].compactMap(\.self).first {
                                    Text(detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    header("Trends")
                }
            }
        }
        .listStyle(.plain)
        // The first header sits right under the search bar, as a table's did.
        .contentMargins(.top, 0, for: .scrollContent)
    }

    private func queryRow(_ query: String, icon: TwitterIcon) -> some View {
        Button {
            search(query)
        } label: {
            Label(query, twitterIcon: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func header(_ title: LocalizedStringKey, @ViewBuilder trailing: () -> some View = { EmptyView() })
        -> some View
    {
        ClassicPlainHeader(title, trailing: trailing)
            .listRowInsets(EdgeInsets())
    }
}
