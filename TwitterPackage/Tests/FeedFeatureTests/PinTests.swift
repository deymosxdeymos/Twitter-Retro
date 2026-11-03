import ComposableArchitecture
import Foundation
import Testing

@testable import FeedFeature
@testable import Models
@testable import TwitterClient
@testable import TwitterDatabase

@MainActor
struct PinTests {
    private func ownTweet() -> Tweet {
        var tweet = Tweet.mocks[0]
        tweet.author = .mock
        return tweet
    }

    @Test
    func pinningOnYourProfileMarksItAndReloads() async {
        @Shared(.viewer) var viewer = User.mock
        let tweet = ownTweet()
        let calls = LockIsolated<[Bool]>([])
        let store = TestStore(initialState: FeedFeature.State(source: .userPosts(userID: User.mock.id))) {
            FeedFeature()
        } withDependencies: {
            $0[TwitterClient.self].setPinned = { isPinned, id in
                #expect(id == tweet.id)
                calls.withValue { $0.append(isPinned) }
            }
            $0[TwitterClient.self].feed = { _, _ in FeedPage(items: [], bottomCursor: nil, topCursor: nil) }
            $0[TimelineCache.self] = .previewValue
            $0.date.now = Date(timeIntervalSince1970: 0)
        }
        store.exhaustivity = .off

        await store.send(.pinButtonTapped(tweet))
        #expect(viewer?.pinnedTweetID == tweet.id)
        await store.receive(\.refreshPulled)

        await store.send(.pinButtonTapped(tweet))
        #expect(viewer?.pinnedTweetID == nil)
        await store.receive(\.refreshPulled)
        #expect(calls.value == [true, false])
    }

    @Test
    func failureRestoresThePreviousPin() async {
        struct Failure: LocalizedError { var errorDescription: String? { "Nope" } }
        var me = User.mock
        me.pinnedTweetID = "older"
        @Shared(.viewer) var viewer = me
        let store = TestStore(initialState: FeedFeature.State(source: .home(following: false))) {
            FeedFeature()
        } withDependencies: {
            $0[TwitterClient.self].setPinned = { _, _ in throw Failure() }
        }
        store.exhaustivity = .off

        await store.send(.pinButtonTapped(ownTweet()))
        await store.receive(\.pinFailed)
        #expect(viewer?.pinnedTweetID == "older")
        #expect(store.state.alert != nil)
    }

    @Test
    func someoneElsesTweetCannotBePinned() async {
        @Shared(.viewer) var viewer = User.mock
        var tweet = Tweet.mocks[0]
        tweet.author = .mockFriend
        let store = TestStore(initialState: FeedFeature.State(source: .home(following: false))) {
            FeedFeature()
        }
        await store.send(.pinButtonTapped(tweet))
        #expect(viewer?.pinnedTweetID == nil)
    }
}
