import ComposableArchitecture
import Models
import SwiftUI
import TweetEngagement
import TwitterUI

@Observable
final class TweetActionTrayState {
    var tweetID: Tweet.ID?

    func toggle(_ id: Tweet.ID) {
        tweetID = tweetID == id ? nil : id
    }
}

extension EnvironmentValues {
    @Entry var tweetActionTray: TweetActionTrayState? = nil
}

/// Tweetie's tucked-away actions, with bookmarks and Quote Tweet kept from the modern client.
struct TweetActionTray: View {
    let tweet: Tweet
    let engagement: Engagement
    let store: StoreOf<FeedFeature>
    let close: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Button {
                close()
                store.send(.replyButtonTapped(tweet))
            } label: {
                TrayLabel("Reply", icon: .replyStroke)
            }
            .disabled(!tweet.viewerCanReply)

            RetweetMenu(tweet: tweet, engagement: engagement, store: store) {
                TrayLabel("Retweet", icon: engagement.repost.isOn ? .repost : .repostStroke)
                    .foregroundStyle(engagement.repost.isOn ? .twitterRepost : .white)
            }

            FavoriteActionButton(isFavorite: engagement.like.isOn) {
                store.send(.likeButtonTapped(tweet))
            } label: {
                TrayLabel("Favorite", icon: engagement.like.isOn ? .heart : .heartStroke)
                    .foregroundStyle(engagement.like.isOn ? .twitterLike : .white)
            }

            Button {
                store.send(.bookmarkButtonTapped(tweet))
            } label: {
                TrayLabel(
                    engagement.bookmark.isOn ? "Saved" : "Save",
                    icon: engagement.bookmark.isOn ? .bookmark : .bookmarkStroke
                )
                .foregroundStyle(engagement.bookmark.isOn ? .twitterBlue : .white)
            }
            .accessibilityLabel(engagement.bookmark.isOn ? "Remove Bookmark" : "Bookmark")

            ShareLink(item: tweet.url) {
                TrayLabel("Share", icon: .share)
            }

            Button(action: close) {
                TrayLabel("Close", icon: .close)
            }
            .accessibilityLabel("Close Tweet Actions")
        }
        .buttonStyle(TrayButtonStyle())
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background {
            LinearGradient(colors: [.black, ClassicChrome.tabBarColor], startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .top) { Color.black.frame(height: 1) }
                .overlay(alignment: .bottom) { Color.white.opacity(0.12).frame(height: 0.5) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tweet-action-tray")
    }
}

private struct TrayLabel: View {
    let title: LocalizedStringKey
    let icon: TwitterIcon

    init(_ title: LocalizedStringKey, icon: TwitterIcon) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 5) {
            icon.image
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
            Text(title)
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(minWidth: 44, maxWidth: .infinity, minHeight: 64, alignment: .top)
        .padding(.top, 8)
        .contentShape(.rect)
    }
}

private struct TrayButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(!isEnabled ? 0.4 : configuration.isPressed ? 0.55 : 1)
    }
}
