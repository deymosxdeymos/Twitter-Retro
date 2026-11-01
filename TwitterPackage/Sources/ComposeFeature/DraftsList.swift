import ComposableArchitecture
import SwiftUI
import TwitterUI

/// Drafts to pick up again: tap one to finish it, swipe to delete.
struct DraftsList: View {
    let store: StoreOf<ComposeFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ClassicNavigationBar("Drafts") {
                EmptyView()
            } trailing: {
                Button("Done") { dismiss() }
                    .buttonStyle(.classicProminent)
                    .keyboardShortcut(.cancelAction)
            }

            List {
                ForEach(store.drafts) { draft in
                    Button {
                        store.send(.draftTapped(draft))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            if let replyingTo = draft.replyingTo {
                                Text("Replying to @\(replyingTo.author.screenName)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Text(draft.text)
                                .lineLimit(3)

                            Text(draft.savedAt, format: .relative(presentation: .named))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { store.send(.deleteDrafts($0)) }
            }
            .listStyle(.plain)
            .overlay {
                if store.drafts.isEmpty {
                    ContentUnavailableView(
                        "No Drafts", twitterIcon: .drafts, description: Text("Saved Tweets will appear here."))
                }
            }
        }
        .background(.background)
        .presentationDragIndicator(.hidden)
    }
}
