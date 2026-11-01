import Testing
import UIKit

@testable import FeedFeature
@testable import TwitterUI

@MainActor
struct PullToRefreshTests {
    @Test
    func arrowArmsWhileHoldingAndDisarmsWhenPulledBack() {
        let pull = PullToRefresh()
        pull.isDragging = true
        pull.distance = PullToRefresh.triggerDistance - 1
        #expect(pull.phase == .pull)

        pull.distance = PullToRefresh.triggerDistance
        #expect(pull.phase == .release)

        pull.distance += 40
        #expect(pull.phase == .release)

        pull.distance = PullToRefresh.triggerDistance - 1
        #expect(pull.phase == .pull)
    }

    @Test
    func loadingTakesPrecedenceOverDistanceAndDragging() {
        let pull = PullToRefresh()
        pull.isDragging = true
        pull.distance = PullToRefresh.triggerDistance + 40
        pull.isRefreshing = true
        #expect(pull.phase == .loading)

        pull.isDragging = false
        pull.distance = 0
        #expect(pull.phase == .loading)

        pull.isRefreshing = false
        #expect(pull.phase == .pull)
    }

    @Test
    func scrollingWithoutDraggingDoesNotArmTheArrow() {
        let pull = PullToRefresh()
        pull.distance = PullToRefresh.triggerDistance + 40
        #expect(pull.phase == .pull)
    }

    @Test
    func onlySuccessfulRefreshesAdvanceTheTimestamp() {
        let pull = PullToRefresh()
        let first = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 200)
        pull.isRefreshing = true
        pull.finish(succeeded: false, at: first)
        #expect(pull.lastSuccessfulRefresh == nil)
        #expect(!pull.isRefreshing)

        pull.isRefreshing = true
        pull.finish(succeeded: true, at: first)
        #expect(pull.lastSuccessfulRefresh == first)
        #expect(!pull.isRefreshing)

        pull.isRefreshing = true
        pull.finish(succeeded: false, at: later)
        #expect(pull.lastSuccessfulRefresh == first)
        #expect(!pull.isRefreshing)
    }

    @Test
    func spinnerStylingIsLocalAndRestoresTheOriginalTint() {
        let classicScroll = UIScrollView()
        let classicControl = UIRefreshControl()
        classicControl.tintColor = .red
        classicScroll.refreshControl = classicControl
        let otherScroll = UIScrollView()
        let otherControl = UIRefreshControl()
        otherControl.tintColor = .blue
        otherScroll.refreshControl = otherControl

        let marker = ClassicRefreshControlStyle.SpinnerStyleView()
        classicScroll.addSubview(marker)
        marker.updateRefreshControl()
        #expect(classicControl.tintColor == .clear)
        #expect(otherControl.tintColor == .blue)

        marker.restoreTint()
        #expect(classicControl.tintColor == .red)
    }

    @Test
    func replacingTheSystemControlRestoresThePreviousOne() {
        let scroll = UIScrollView()
        let first = UIRefreshControl()
        first.tintColor = .red
        scroll.refreshControl = first
        let marker = ClassicRefreshControlStyle.SpinnerStyleView()
        scroll.addSubview(marker)
        marker.updateRefreshControl()

        let replacement = UIRefreshControl()
        replacement.tintColor = .blue
        scroll.refreshControl = replacement
        marker.updateRefreshControl()
        #expect(first.tintColor == .red)
        #expect(replacement.tintColor == .clear)
        marker.restoreTint()
        #expect(replacement.tintColor == .blue)
    }
}
