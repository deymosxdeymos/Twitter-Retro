import SwiftUI

/// Keeps confirmation and feedback identical in the timeline and the swipe tray. The server still calls this a like.
package struct FavoriteActionButton<Label: View>: View {
    let isFavorite: Bool
    let action: () -> Void
    let label: Label
    @AppStorage(RetroSettings.confirmsLikesKey) private var confirmsFavorites = false
    @State private var isConfirming = false

    package init(isFavorite: Bool, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.isFavorite = isFavorite
        self.action = action
        self.label = label()
    }

    package var body: some View {
        Button {
            if confirmsFavorites, !isFavorite { isConfirming = true } else { action() }
        } label: {
            label
        }
        .accessibilityLabel(isFavorite ? "Remove Favorite" : "Favorite")
        .sensoryFeedback(.selection, trigger: isFavorite)
        .alert("Favorite this Tweet?", isPresented: $isConfirming) {
            Button("Favorite", action: action)
            Button("Cancel", role: .cancel) {}
        }
    }
}

package struct LikeButton: View {
    let action: () -> Void
    let count: Int
    let isLiked: Bool
    @Environment(\.tweetMetrics) private var metrics

    package init(isLiked: Bool, count: Int, action: @escaping () -> Void) {
        self.action = action
        self.count = count
        self.isLiked = isLiked
    }

    package var body: some View {
        FavoriteActionButton(isFavorite: isLiked, action: action) {
            HStack(spacing: 4) {
                TwitterIconView(isLiked ? .heart : .heartStroke)
                    .foregroundStyle(isLiked ? .twitterLike : .twitterSecondary)

                if count > 0 {
                    Text(count.compact)
                        .lineLimit(1)
                        .fixedSize()
                        .font(metrics.font(.subtext2))
                        .monospacedDigit()
                        .foregroundStyle(isLiked ? .twitterLike : .twitterSecondary)
                }
            }
            .frame(minWidth: EngagementLabel.minimumWidth, minHeight: 24, alignment: .leading)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.vertical, 10)
            .contentShape(.rect)
            .padding(.vertical, -10)
        }
        .buttonStyle(.plain)
        .accessibilityValue(count.formatted())
    }
}

#Preview {
    @Previewable @State var isLiked = false
    LikeButton(isLiked: isLiked, count: isLiked ? 561 : 560) {
        isLiked.toggle()
    }
    .padding()
}
