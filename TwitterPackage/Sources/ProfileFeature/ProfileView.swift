import ComposableArchitecture
import FeedFeature
import SwiftUI
import TwitterUI

package struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>
    @Environment(\.columnBarPlacement) private var columnBarPlacement

    package init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    package var body: some View {
        Group {
            if let user = store.user, user.blocksViewer || (user.isBlocking && !store.isShowingBlockedPosts) {
                BlockedProfile(user: user, store: store)
            } else if let feedsStore = store.scope(state: \.feeds, action: \.feeds), let user = store.user {
                FeedsView(store: feedsStore) {
                    ProfileHeader(user: user, isViewer: store.isViewer, store: store)
                }
            } else if let errorMessage = store.errorMessage {
                ContentUnavailableView {
                    Label("Couldn't load @\(store.screenName)", twitterIcon: .warningStroke)
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again") { store.send(.task) }
                        .buttonStyle(.classic)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(store.user?.name ?? "@\(store.screenName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.hasMenu {
                ColumnMenuToolbarItem("Account", placement: columnBarPlacement) {
                    ProfileMenuItems(store: store)
                }
            }
        }
        .task { store.send(.task) }
        .sheet(
            isPresented: Binding {
                store.isShowingSettings
            } set: { isPresented in
                if !isPresented { store.send(.settingsDismissed) }
            }
        ) {
            SettingsView(store: store)
        }
        // Full screen and square-edged on iPhone, as the composer; a form sheet on iPad.
        .fullScreenCover(
            item: Self.isPhone ? $store.scope(state: \.editProfile, action: \.editProfile) : .constant(nil)
        ) { editStore in
            EditProfileView(store: editStore)
        }
        .sheet(item: Self.isPhone ? .constant(nil) : $store.scope(state: \.editProfile, action: \.editProfile)) {
            editStore in
            EditProfileView(store: editStore)
        }
    }

    private static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
}

/// A profile's "…" menu: the viewer's own account settings, or blocking someone else.
package struct ProfileMenuItems: View {
    let store: StoreOf<ProfileFeature>

    package init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    package var body: some View {
        Button("Lists", twitterIcon: .listsStroke) {
            store.send(.listsButtonTapped)
        }

        if let url = store.user?.profileURL {
            ShareLink(item: url) {
                Label("Share Profile", twitterIcon: .share)
            }

            Button("Copy Link to Profile", twitterIcon: .link) {
                UIPasteboard.general.url = url
            }
        }

        Divider()

        if store.isViewer {
            Button("Edit Profile", twitterIcon: .personStroke) {
                store.send(.editProfileButtonTapped)
            }

            Button("Settings", twitterIcon: .settings) {
                store.send(.settingsButtonTapped)
            }

            PostRowStylePicker()

            Divider()

            Button("Sign Out", twitterIcon: .signOut, role: .destructive) {
                store.send(.signOutButtonTapped)
            }
        } else if let user = store.user {
            Button(
                user.isMuting ? "Unmute @\(user.screenName)" : "Mute @\(user.screenName)",
                twitterIcon: user.isMuting ? .unmute : .mute
            ) {
                store.send(.muteButtonTapped)
            }

            Button(
                user.isBlocking ? "Unblock @\(user.screenName)" : "Block @\(user.screenName)",
                twitterIcon: user.isBlocking ? .unblock : .block
            ) {
                store.send(.blockButtonTapped)
            }
        }
    }
}

extension ProfileFeature.State {
    /// Whether ``ProfileMenuItems`` has anything to offer yet.
    package var hasMenu: Bool { isViewer || user != nil }
}
