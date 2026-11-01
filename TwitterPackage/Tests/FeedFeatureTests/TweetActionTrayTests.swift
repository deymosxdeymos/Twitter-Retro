import CoreGraphics
import Testing

@testable import FeedFeature

@MainActor
struct TweetActionTrayTests {
    @Test
    func onlyOneTweetHasAnOpenTray() {
        let trays = TweetActionTrayState()
        trays.toggle("first")
        #expect(trays.tweetID == "first")
        trays.toggle("second")
        #expect(trays.tweetID == "second")
        trays.toggle("second")
        #expect(trays.tweetID == nil)
    }

    @Test
    func leftSwipeOpensButAClosedRowsRightSwipeBelongsToNavigation() {
        #expect(TweetActionSwipe.Coordinator.canBegin(velocity: CGPoint(x: -200, y: 10), startX: 200, isOpen: false))
        #expect(!TweetActionSwipe.Coordinator.canBegin(velocity: CGPoint(x: 200, y: 10), startX: 200, isOpen: false))
        #expect(TweetActionSwipe.Coordinator.canBegin(velocity: CGPoint(x: 200, y: 10), startX: 200, isOpen: true))
    }

    @Test
    func verticalAndDiagonalDragsStayWithScrolling() {
        for velocity in [CGPoint(x: 5, y: 200), CGPoint(x: -100, y: 100), CGPoint(x: 0, y: 0)] {
            #expect(!TweetActionSwipe.Coordinator.canBegin(velocity: velocity, startX: 200, isOpen: false))
            #expect(!TweetActionSwipe.Coordinator.canBegin(velocity: velocity, startX: 200, isOpen: true))
        }
    }

    @Test
    func leadingEdgeIsReservedForBackSwipe() {
        for startX in [CGFloat(0), 20, 36] {
            #expect(
                !TweetActionSwipe.Coordinator.canBegin(velocity: CGPoint(x: 200, y: 0), startX: startX, isOpen: true))
            #expect(
                !TweetActionSwipe.Coordinator.canBegin(velocity: CGPoint(x: -200, y: 0), startX: startX, isOpen: false))
        }
    }
}
