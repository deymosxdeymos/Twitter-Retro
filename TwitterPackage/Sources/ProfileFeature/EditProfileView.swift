import ColumnNavigation
import ComposableArchitecture
import PhotosUI
import SwiftUI
import TwitterUI

/// Twitter 4.x's Edit Profile: a grouped table under the silver bar, pictures first, then the words.
struct EditProfileView: View {
    @Bindable var store: StoreOf<EditProfileFeature>
    @State private var pickedAvatar: PhotosPickerItem?
    @State private var pickedBanner: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            ClassicNavigationBar("Edit Profile") {
                Button("Cancel") { store.send(.cancelButtonTapped) }
                    .buttonStyle(.classic)
                    .keyboardShortcut(.cancelAction)
                    .disabled(store.isSaving)
            } trailing: {
                Button {
                    store.send(.saveButtonTapped)
                } label: {
                    HStack(spacing: 6) {
                        if store.isSaving { ProgressView().tint(.white) }
                        Text(store.isSaving ? "Saving…" : "Save")
                    }
                }
                .buttonStyle(.classicProminent)
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!store.canSave)
            }

            Form {
                Section {
                    PhotosPicker(selection: $pickedAvatar, matching: .images) {
                        LabeledContent("Photo") {
                            avatarPreview
                        }
                    }

                    PhotosPicker(selection: $pickedBanner, matching: .images) {
                        LabeledContent("Header") {
                            bannerPreview
                        }
                    }
                }

                Section {
                    field("Name", text: $store.name, limit: EditProfileFeature.Limit.name)
                        .textContentType(.name)

                    field("Location", text: $store.location, limit: EditProfileFeature.Limit.location)
                        .textContentType(.addressCity)

                    field("Website", text: $store.website, limit: EditProfileFeature.Limit.website)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    TextField("Bio", text: $store.bio, prompt: Text("Describe yourself"), axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Bio")
                } header: {
                    Text("Bio")
                } footer: {
                    let remaining = EditProfileFeature.Limit.bio - store.bio.count
                    Text("\(remaining)")
                        .monospacedDigit()
                        .foregroundStyle(remaining < 0 ? .red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityLabel("\(remaining) characters remaining")
                }
            }
            .formStyle(.classicGrouped)
            .scrollDismissesKeyboard(.interactively)
            .background { HatchedBackdrop().ignoresSafeArea() }
        }
        .interactiveDismissDisabled(store.hasChanges || store.isSaving)
        .task(id: pickedAvatar) {
            guard let pickedAvatar else { return }
            if let data = await ProfilePicture.avatar(from: pickedAvatar) { store.send(.avatarPicked(data)) }
            self.pickedAvatar = nil
        }
        .task(id: pickedBanner) {
            guard let pickedBanner else { return }
            if let data = await ProfilePicture.banner(from: pickedBanner) { store.send(.bannerPicked(data)) }
            self.pickedBanner = nil
        }
        .classicAlert(
            "Couldn't Save Profile", message: store.errorMessage,
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0, store.errorMessage != nil { store.send(.errorDismissed) } }
            ))
    }

    /// A row with its label on the left and the value typed in on the right, as 4.x's profile fields.
    private func field(_ title: LocalizedStringKey, text: Binding<String>, limit: Int) -> some View {
        LabeledContent(title) {
            TextField(title, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(text.wrappedValue.count > limit ? .red : Color(.label))
        }
    }

    private var avatarPreview: some View {
        Group {
            if let data = store.avatar, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Avatar(user: store.user, size: 44)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(.rect(cornerRadius: Avatar.cornerRadius(forSize: 44)))
        .accessibilityHidden(true)
    }

    private var bannerPreview: some View {
        Group {
            if let data = store.banner, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let url = store.user.bannerURL {
                RemoteImage(url: url, pointSize: 200) { Color.clear }
            } else {
                Rectangle().fill(.twitterBlue.tertiary)
            }
        }
        .frame(width: 132, height: 44)
        .clipShape(.rect(cornerRadius: 4))
        .accessibilityHidden(true)
    }
}

/// Pictures sized the way Twitter keeps them: a 400 pt square avatar and a 1500 × 500 header, centre-cropped.
enum ProfilePicture {
    static func avatar(from item: PhotosPickerItem) async -> Data? {
        await jpeg(from: item, size: CGSize(width: 400, height: 400))
    }

    static func banner(from item: PhotosPickerItem) async -> Data? {
        await jpeg(from: item, size: CGSize(width: 1500, height: 500))
    }

    private static func jpeg(from item: PhotosPickerItem, size: CGSize) async -> Data? {
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            return nil
        }
        let scale = max(size.width / image.size.width, size.height / image.size.height)
        let drawn = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let cropped = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(
                in: CGRect(
                    x: (size.width - drawn.width) / 2, y: (size.height - drawn.height) / 2,
                    width: drawn.width, height: drawn.height))
        }
        return cropped.jpegData(compressionQuality: 0.85)
    }
}
