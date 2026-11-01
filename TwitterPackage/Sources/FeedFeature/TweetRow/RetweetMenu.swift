import ComposableArchitecture
import Models
import SwiftUI
import TweetEngagement
import TwitterUI

/// Tweetie's Retweet button: an action sheet offering Retweet (or Undo Retweet) and Quote Tweet.
struct RetweetMenu<ButtonLabel: View>: View {
    let tweet: Tweet
    let engagement: Engagement
    let store: StoreOf<FeedFeature>
    @ViewBuilder var label: ButtonLabel
    @State private var isAsking = false

    var body: some View {
        Button {
            isAsking = true
        } label: {
            label
        }
        .classicActionSheet(
            isPresented: $isAsking,
            actions: [
                ClassicActionSheetAction(engagement.repost.isOn ? "Undo Retweet" : "Retweet") {
                    store.send(.repostButtonTapped(tweet))
                },
                ClassicActionSheetAction("Quote Tweet") {
                    store.send(.quoteButtonTapped(tweet))
                }
            ]
        )
    }
}
