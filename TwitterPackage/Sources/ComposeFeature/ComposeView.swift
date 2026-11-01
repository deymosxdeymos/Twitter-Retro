import ComposableArchitecture
import PhotosUI
import SwiftUI
import TwitterClient
import TwitterUI

/// The text field typing goes to: the first Tweet's, or one of the thread's.
private enum Editor: Hashable {
    case first
    case followUp(ComposeFeature.FollowUp.ID)
}

package struct ComposeView: View {
    @Bindable var store: StoreOf<ComposeFeature>

    package init(store: StoreOf<ComposeFeature>) {
        self.store = store
    }
    @FocusState private var focusedEditor: Editor?
    @State private var pickedItems: [PhotosPickerItem] = []
    @AppStorage(RetroSettings.confirmsTweetsKey) private var confirmsTweets = false
    @State private var isConfirmingTweet = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let isPhone = UIDevice.current.userInterfaceIdiom == .phone

    private var editingAnimation: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.18) }

    package var body: some View {
        VStack(spacing: 0) {
            ClassicNavigationBar(store.draft.replyingTo == nil ? "New Tweet" : "Reply") {
                Button("Cancel") { store.send(.cancelButtonTapped) }
                    .buttonStyle(.classic)
                    .keyboardShortcut(.cancelAction)
                    .disabled(store.isPosting || store.isDismissing)
            } trailing: {
                Button {
                    if confirmsTweets { isConfirmingTweet = true } else { store.send(.postButtonTapped) }
                } label: {
                    HStack(spacing: 6) {
                        if store.isPosting { ProgressView().tint(.white) }
                        Text(store.isPosting ? "Sending…" : "Tweet")
                    }
                }
                .buttonStyle(.classicProminent)
                .disabled(!store.canPost)
                .keyboardShortcut(.return, modifiers: .command)
                .alert("Send this Tweet?", isPresented: $isConfirmingTweet) {
                    Button("Tweet") { store.send(.postButtonTapped) }
                    Button("Cancel", role: .cancel) {}
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let replyingTo = store.draft.replyingTo {
                        ReplyContext(tweet: replyingTo)
                    }

                    TextField(
                        store.draft.replyingTo == nil ? "What's happening?" : "Tweet your reply",
                        text: $store.text,
                        axis: .vertical
                    )
                    .font(.title3)
                    .accessibilityLabel(store.draft.replyingTo == nil ? "Tweet text" : "Reply text")
                    .lineLimit(4...)
                    .focused($focusedEditor, equals: .first)

                    if !store.mentionSuggestions.isEmpty {
                        MentionSuggestions(users: store.mentionSuggestions) {
                            store.send(.mentionSuggestionTapped($0))
                        }
                    }

                    if !store.attachments.isEmpty {
                        AttachmentStrip(attachments: store.attachments) { id in
                            store.send(.removeAttachmentButtonTapped(id), animation: editingAnimation)
                        }
                    }

                    if let quoting = store.draft.quoting {
                        QuoteCard(tweet: quoting) {}
                            .disabled(true)
                    }

                    ForEach(store.followUps) { followUp in
                        FollowUpEditor(
                            text: Binding {
                                followUp.text
                            } set: {
                                store.send(.followUpTextChanged(followUp.id, $0))
                            },
                            remainingCharacters: followUp.remainingCharacters
                        ) {
                            store.send(.removeFollowUpButtonTapped(followUp.id), animation: editingAnimation)
                        }
                        .focused($focusedEditor, equals: .followUp(followUp.id))
                    }

                    if let errorMessage = store.errorMessage {
                        Label(errorMessage, twitterIcon: .warningStroke)
                            .font(.footnote)
                            .foregroundStyle(.twitterError)
                    }
                }
                .padding()
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .disabled(store.isPosting || store.isDismissing)
            // A solid shelf follows the keyboard instead of a floating glass toolbar.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    PhotosPicker(
                        selection: $pickedItems,
                        maxSelectionCount: max(store.remainingPhotos, 1),
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label("Add Media", twitterIcon: .mediaStroke)
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Add Media")
                    .disabled(store.remainingPhotos == 0 || store.isPosting)

                    Button("Add another Tweet", twitterIcon: .plus) {
                        store.send(.addFollowUpButtonTapped, animation: editingAnimation)
                    }
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Add another Tweet")
                    .disabled(!store.hasText || store.isPosting)

                    if store.offersDrafts {
                        Button("Drafts") { store.send(.draftsButtonTapped) }
                            .buttonStyle(.classic)
                    }

                    Spacer(minLength: 8)

                    CharacterCountdown(remaining: store.remainingCharacters)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .buttonStyle(.classicBar(isOnSideBar: false))
                .background { ClassicShelf().ignoresSafeArea(edges: .bottom) }
            }
        }
        .background(.background)
        .interactiveDismissDisabled(
            !store.text.isEmpty || !store.attachments.isEmpty || !store.followUps.isEmpty || store.isPosting
        )
        // Twitter's question on Cancel, as the old action sheet: discard at the top in red, keep, or go back.
        .classicActionSheet(
            isPresented: Binding(
                get: { store.confirmation != nil },
                set: { if !$0, store.confirmation != nil { store.send(.confirmation(.dismiss)) } }
            ),
            actions: [
                ClassicActionSheetAction("Delete Draft", isDestructive: true) {
                    store.send(.confirmation(.presented(.deleteTapped)))
                },
                ClassicActionSheetAction("Save Draft") {
                    store.send(.confirmation(.presented(.saveDraftTapped)))
                }
            ]
        )
        // Full screen and square-edged on iPhone, like the composer it covers.
        .fullScreenCover(isPresented: isPhone ? $store.isShowingDrafts : .constant(false)) {
            DraftsList(store: store)
        }
        .sheet(isPresented: isPhone ? .constant(false) : $store.isShowingDrafts) {
            DraftsList(store: store)
        }
        .task(id: pickedItems) {
            guard !pickedItems.isEmpty else { return }
            let uploads = await MediaUpload.load(pickedItems)
            pickedItems = []
            store.send(.mediaPicked(uploads), animation: editingAnimation)
        }
        .onAppear { focusedEditor = .first }
        // A Tweet added to the thread is where typing goes next.
        .onChange(of: store.followUps.last?.id) { _, newID in
            if let newID { focusedEditor = .followUp(newID) }
        }
    }
}

struct CharacterCountdown: View {
    let remaining: Int

    var body: some View {
        Text(remaining, format: .number)
            .font(.title3.monospacedDigit())
            .foregroundStyle(remaining < 0 ? .twitterError : remaining < 20 ? .twitterWarning : .twitterSecondary)
            .frame(minWidth: 52, minHeight: 44, alignment: .trailing)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(
                remaining < 0 ? "\(-remaining) characters over the limit" : "\(remaining) characters remaining")
    }
}
