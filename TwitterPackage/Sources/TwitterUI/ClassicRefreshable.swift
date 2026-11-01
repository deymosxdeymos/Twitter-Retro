import SwiftUI

extension View {
    /// The action reports success so a failed request never advances "Last Updated".
    /// Put `ClassicRefreshControlStyle` inside the scroll content to hide only its system spinner.
    package func classicRefreshable(lastUpdated: Date? = nil, action: @escaping () async -> Bool) -> some View {
        modifier(ClassicRefreshable(lastUpdated: lastUpdated, action: action))
    }
}

private struct ClassicRefreshable: ViewModifier {
    let lastUpdated: Date?
    let action: () async -> Bool
    @State private var pull = PullToRefresh()

    func body(content: Content) -> some View {
        content
            .refreshable {
                pull.isRefreshing = true
                ClassicSound.psst2.play()
                let succeeded = await action() && !Task.isCancelled
                pull.finish(succeeded: succeeded, at: .now)
                if succeeded { ClassicSound.pop.play() }
            }
            .onScrollGeometryChange(for: PullGeometry.self) { geometry in
                PullGeometry(
                    distance: max(-(geometry.contentOffset.y + geometry.contentInsets.top), 0),
                    topInset: geometry.contentInsets.top
                )
            } action: { _, geometry in
                if !pull.isRefreshing { pull.restingTopInset = geometry.topInset }
                pull.distance = max(geometry.distance + geometry.topInset - pull.restingTopInset, 0)
            }
            .onScrollPhaseChange { _, phase in
                pull.isDragging = phase == .interacting
            }
            .onChange(of: pull.phase) { old, new in
                if old == .pull, new == .release { ClassicSound.psst1.play() }
            }
            .overlay(alignment: .top) {
                if pull.distance > 0 {
                    ClassicPullToRefresh(
                        phase: pull.phase,
                        lastUpdated: lastUpdated ?? pull.lastSuccessfulRefresh,
                        height: pull.distance
                    )
                }
            }
    }
}

private struct PullGeometry: Equatable {
    var distance: CGFloat
    var topInset: CGFloat
}

@Observable
final class PullToRefresh {
    // UIKit doesn't expose its arm distance. The arrow and catch sound share this approximation.
    static let triggerDistance: CGFloat = 80

    var distance: CGFloat = 0
    var restingTopInset: CGFloat = 0
    var isDragging = false
    var isRefreshing = false
    private(set) var lastSuccessfulRefresh: Date?

    func finish(succeeded: Bool, at date: Date) {
        if succeeded { lastSuccessfulRefresh = date }
        isRefreshing = false
    }

    var phase: ClassicPullToRefresh.Phase {
        if isRefreshing { return .loading }
        return isDragging && distance >= Self.triggerDistance ? .release : .pull
    }
}
