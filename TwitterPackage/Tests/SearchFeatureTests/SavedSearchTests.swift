import ComposableArchitecture
import Testing

@testable import SearchFeature

@MainActor
struct SavedSearchTests {
    @Test
    func bookmarkButtonSavesAndUnsavesTheSearchOnScreen() async {
        let store = TestStore(initialState: SearchFeature.State(submitting: "swift")) {
            SearchFeature()
        }
        store.exhaustivity = .off

        #expect(store.state.isSubmittedQuerySaved == false)
        await store.send(.saveSearchButtonTapped) {
            $0.$savedSearches.withLock { $0 = ["swift"] }
        }
        #expect(store.state.isSubmittedQuerySaved == true)
        await store.send(.saveSearchButtonTapped) {
            $0.$savedSearches.withLock { $0 = [] }
        }
    }

    @Test
    func nothingToSaveBeforeSearching() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        }
        #expect(store.state.isSubmittedQuerySaved == nil)
        await store.send(.saveSearchButtonTapped)
    }

    @Test
    func deletingRemovesOnlyThatSearch() async {
        var state = SearchFeature.State()
        state.$savedSearches.withLock { $0 = ["swift", "tca"] }
        let store = TestStore(initialState: state) {
            SearchFeature()
        }
        await store.send(.savedSearchDeleted("swift")) {
            $0.$savedSearches.withLock { $0 = ["tca"] }
        }
    }
}
