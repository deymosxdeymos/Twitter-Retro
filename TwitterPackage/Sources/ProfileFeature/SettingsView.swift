import ColumnNavigation
import ComposableArchitecture
import FeedFeature
import Models
import SwiftUI
import TwitterUI
import UserNotifications

/// Settings, from your own profile: the account you're signed in with, how Tweets look, sounds, and about the app.
struct SettingsView: View {
    let store: StoreOf<ProfileFeature>
    @Shared(.postRowStyle) private var postRowStyle
    @Shared(.appStorage(MediaAutoplay.settingKey)) private var autoplaysMedia = MediaAutoplay.defaultValue
    @Shared(.appStorage(ClassicSound.settingKey)) private var playsSounds = true
    @Shared(.appStorage(Appearance.settingKey)) private var appearance = Appearance.system
    @Shared(.appStorage(RetroSettings.showsExactCountsKey)) private var showsExactCounts = false
    @Shared(.appStorage(RetroSettings.showsClientKey)) private var showsClient = true
    @Shared(.appStorage(RetroSettings.confirmsLikesKey)) private var confirmsLikes = false
    @Shared(.appStorage(RetroSettings.confirmsFollowsKey)) private var confirmsFollows = false
    @Shared(.appStorage(RetroSettings.confirmsTweetsKey)) private var confirmsTweets = false
    @Shared(.appStorage(RetroSettings.locksAppKey)) private var locksApp = false
    @Shared(.appStorage(RetroSettings.notifiesKey)) private var notifies = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if let viewer = store.user {
                    Section("Account") {
                        HStack(spacing: 12) {
                            Avatar(user: viewer, size: 44)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewer.name)
                                    .font(.body.weight(.bold))

                                Text(verbatim: "@\(viewer.screenName)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Sign Out", twitterIcon: .signOut, role: .destructive) {
                            dismiss()
                            store.send(.signOutButtonTapped)
                        }
                    }
                }

                Section {
                    LabeledContent("Tweet Layout") {
                        Picker("Tweet Layout", selection: Binding($postRowStyle)) {
                            ForEach(PostRowStyle.allCases, id: \.self) { style in
                                Text(style.title)
                            }
                        }
                        .labelsHidden()
                    }

                    LabeledContent("Appearance") {
                        ClassicSegmentedControl(Appearance.allCases, selection: Binding($appearance)) { appearance in
                            Text(appearance.title)
                        }
                        .frame(maxWidth: 220)
                    }

                    Toggle("Sounds", isOn: Binding($playsSounds))
                } header: {
                    Text("Display and Sound")
                } footer: {
                    Text("Sounds play as you pull a timeline to refresh, as in Twitter for iPad.")
                }

                Section {
                    Toggle("Exact Counts", isOn: Binding($showsExactCounts))

                    Toggle("Source Labels", isOn: Binding($showsClient))
                } header: {
                    Text("Tweets")
                } footer: {
                    Text(
                        "Twitter named the app a Tweet came from, like Twitter for iPhone. Exact counts read 12,345 instead of 12.3K."
                    )
                }

                Section {
                    Toggle("Before Favoriting", isOn: Binding($confirmsLikes))

                    Toggle("Before Following", isOn: Binding($confirmsFollows))

                    Toggle("Before Tweeting", isOn: Binding($confirmsTweets))
                } header: {
                    Text("Ask First")
                }

                Section {
                    Toggle("New Notifications", isOn: notificationsToggle)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text(
                        "Checks for new notifications in the background now and then. iOS decides how often, so they can arrive late."
                    )
                }

                Section {
                    Toggle("Lock Twitter", isOn: Binding($locksApp))
                } header: {
                    Text("Privacy")
                } footer: {
                    if let biometry = DeviceUnlock.biometryName {
                        Text("Asks for \(biometry) or your passcode when you open Twitter.")
                    } else {
                        Text("Asks for your passcode when you open Twitter.")
                    }
                }

                Section {
                    Toggle("Autoplay Videos and GIFs", isOn: Binding($autoplaysMedia))
                } header: {
                    Text("Media")
                } footer: {
                    Text("Videos and GIFs in timelines play muted as they scroll into view.")
                }

                Section("About") {
                    LabeledContent("Version", value: Self.version)
                }

                #if DEBUG
                    Section("Debug") {
                        NavigationLink("Columns") {
                            ColumnDebugPanel()
                                .navigationTitle("Columns")
                                .ignoresSafeArea()
                        }
                    }
                #endif
            }
            .formStyle(.classicGrouped)
            .background { HatchedBackdrop() }
            .classicTitleBar()
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", role: .confirm) { dismiss() }
                        .buttonStyle(.classicProminent)
                        .fixedSize()
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }

    private var notificationsToggle: Binding<Bool> {
        Binding {
            notifies
        } set: { isOn in
            guard isOn else {
                $notifies.withLock { $0 = false }
                return
            }
            Task {
                let granted =
                    (try? await UNUserNotificationCenter.current().requestAuthorization(options: [
                        .alert, .badge, .sound
                    ]))
                    ?? false
                $notifies.withLock { $0 = granted }
            }
        }
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#if DEBUG
    /// The column stack's live tuning, from the prototype.
    private struct ColumnDebugPanel: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> ColumnDebugPanelViewController {
            ColumnDebugPanelViewController()
        }

        func updateUIViewController(_ controller: ColumnDebugPanelViewController, context: Context) {}
    }
#endif
