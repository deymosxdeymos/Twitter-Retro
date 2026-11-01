import SwiftUI
import UIKit

package struct ClassicPullToRefresh: View {
    package enum Phase: Equatable {
        case pull
        case release
        case loading
    }

    let phase: Phase
    let lastUpdated: Date?
    let height: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    package init(phase: Phase, lastUpdated: Date?, height: CGFloat) {
        self.phase = phase
        self.lastUpdated = lastUpdated
        self.height = height
    }

    package var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.footnote.weight(.bold))

                if let lastUpdated {
                    Text("Last Updated: \(lastUpdated.formatted(date: .numeric, time: .shortened))")
                        .font(.caption)
                }
            }
            .foregroundStyle(Color(.pullRefreshText))
            .shadow(color: Color(.pullRefreshTextShadow), radius: 0, y: 1)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 60)
            .padding(.bottom, 12)

            Group {
                if phase == .loading {
                    ProgressView()
                        .tint(Color(.pullRefreshText))
                        .frame(width: 23, height: 23)
                        .padding(.bottom, 18)
                } else {
                    Image("PullArrow", bundle: .module)
                        .rotationEffect(.degrees(phase == .release ? -180 : 0))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: phase)
                        .padding(.bottom, 6)
                }
            }
            .padding(.leading, 25)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
        .background(Color(.pullRefreshBackground))
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var title: LocalizedStringKey {
        switch phase {
        case .pull: "Pull down to refresh…"
        case .release: "Release to refresh…"
        case .loading: "Loading…"
        }
    }
}
