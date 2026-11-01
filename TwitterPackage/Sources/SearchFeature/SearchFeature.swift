import ComposableArchitecture
import Models
import Routing
import TwitterClient

@Reducer
package struct SearchFeature {
    @ObservableState
    package struct State: Equatable {
        var query = ""
        /// What was searched lately, newest first.
        @Shared(.recentSearches) var recentSearches
        /// Searches kept on purpose, in the order they were saved. On this device only: the client has no endpoint
        /// for Twitter's own saved searches.
        @Shared(.savedSearches) var savedSearches
        @Presents var results: SearchResults.State?
        var submittedQuery: String?
        var suggestions: [User] = []
        /// What's trending, shown before anything's searched.
        var trends: [Trend] = []
        var trendsError: String?
        var hasLoadedTrends = false
        /// Trends are on their way: a view appearing again meanwhile doesn't ask twice.
        var isLoadingTrends = false

        package init() {}

        package init(submitting query: String) {
            self.query = query
            submittedQuery = query
            results = SearchResults.State(query: query)
        }
    }

    package enum Action: BindableAction {
        case binding(BindingAction<State>)
        case clearRecentSearchesButtonTapped
        case delegate(ContentDelegate)
        case recentSearchTapped(String)
        case savedSearchDeleted(String)
        case savedSearchTapped(String)
        case saveSearchButtonTapped
        case results(PresentationAction<SearchResults.Action>)
        case resultsCleared(query: String)
        case searchSubmitted
        case suggestionTapped(User)
        case suggestionsResponse(query: String, Result<[User], any Error>)
        case task
        case trendTapped(Trend)
        case trendsResponse(Result<[Trend], any Error>)
    }

    @Dependency(TwitterClient.self) var client
    @Dependency(\.continuousClock) var clock

    private enum CancelID { case suggestions }

    package init() {}

    package var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.query):
                if state.query.isEmpty {
                    state.results = nil
                    state.submittedQuery = nil
                }
                guard let query = state.suggestionQuery else {
                    state.suggestions = []
                    return .cancel(id: CancelID.suggestions)
                }
                return .run { send in
                    try await clock.sleep(for: .milliseconds(250))
                    await send(.suggestionsResponse(query: query, Result { try await client.typeahead(query) }))
                }
                .cancellable(id: CancelID.suggestions, cancelInFlight: true)

            case .binding, .delegate:
                return .none

            case .clearRecentSearchesButtonTapped:
                state.$recentSearches.withLock { $0 = [] }
                return .none

            case .recentSearchTapped(let query):
                state.query = query
                return .send(.searchSubmitted)

            case .savedSearchDeleted(let query):
                state.$savedSearches.withLock { $0.removeAll { $0 == query } }
                return .none

            case .savedSearchTapped(let query):
                state.query = query
                return .send(.searchSubmitted)

            case .saveSearchButtonTapped:
                guard let query = state.submittedQuery else { return .none }
                state.$savedSearches.withLock {
                    if let index = $0.firstIndex(where: { $0.caseInsensitiveCompare(query) == .orderedSame }) {
                        $0.remove(at: index)
                    } else {
                        $0.append(query)
                    }
                }
                return .none

            case .results(.presented(.delegate(let delegate))):
                return .send(.delegate(delegate))

            case .results:
                return .none

            case .resultsCleared(let query):
                state.results = SearchResults.State(query: query)
                return .none

            case .searchSubmitted:
                let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty, query != state.submittedQuery else { return .none }
                state.submittedQuery = query
                state.suggestions = []
                state.$recentSearches.withLock {
                    $0.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
                    $0.insert(query, at: 0)
                    $0 = Array($0.prefix(State.recentSearchLimit))
                }
                // Gone first, so the old results' effects are cancelled before the new ones start.
                state.results = nil
                return .merge(.cancel(id: CancelID.suggestions), .send(.resultsCleared(query: query)))

            case .suggestionTapped(let user):
                state.suggestions = []
                return .merge(.cancel(id: CancelID.suggestions), .send(.delegate(.open(.profile(user)))))

            case .suggestionsResponse(let query, let result):
                guard query == state.suggestionQuery else { return .none }
                state.suggestions = Array(((try? result.get()) ?? []).prefix(6))
                return .none

            case .task:
                // Only Explore shows them; a search opened from elsewhere starts with its results.
                guard !state.hasLoadedTrends, !state.isLoadingTrends, state.results == nil else { return .none }
                state.isLoadingTrends = true
                return .run { send in
                    await send(.trendsResponse(Result { try await client.trends() }))
                }

            case .trendTapped(let trend):
                state.query = trend.query
                return .send(.searchSubmitted)

            case .trendsResponse(.success(let trends)):
                state.hasLoadedTrends = true
                state.isLoadingTrends = false
                state.trends = trends
                state.trendsError = nil
                return .none

            case .trendsResponse(.failure(let error)):
                state.hasLoadedTrends = true
                state.isLoadingTrends = false
                state.trendsError = error.localizedDescription
                return .none
            }
        }
        .ifLet(\.$results, action: \.results) {
            SearchResults()
        }
    }
}

extension SearchFeature.State {
    static let recentSearchLimit = 10

    /// Whether the search on screen is saved; nil before anything's been searched.
    var isSubmittedQuerySaved: Bool? {
        guard let submittedQuery, query == submittedQuery else { return nil }
        return savedSearches.contains { $0.caseInsensitiveCompare(submittedQuery) == .orderedSame }
    }

    var suggestionQuery: String? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query != submittedQuery, !query.hasPrefix("#") else { return nil }
        let handle = query.hasPrefix("@") ? String(query.dropFirst()) : query
        return handle.isEmpty ? nil : handle
    }
}

extension SharedKey where Self == FileStorageKey<[String]>.Default {
    /// Searches made lately, kept on disk, newest first.
    static var recentSearches: Self {
        Self[.fileStorage(.applicationSupportDirectory.appending(component: "recent-searches.json")), default: []]
    }

    /// Searches saved from the search bar's bookmark button, kept on disk.
    static var savedSearches: Self {
        Self[.fileStorage(.applicationSupportDirectory.appending(component: "saved-searches.json")), default: []]
    }
}
