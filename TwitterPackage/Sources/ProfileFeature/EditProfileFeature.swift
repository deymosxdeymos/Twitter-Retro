import ComposableArchitecture
import Foundation
import Models
import TwitterClient

/// Editing the signed-in account's profile: name, bio, location, website, and new pictures.
@Reducer
package struct EditProfileFeature {
    /// Twitter's limits.
    package enum Limit {
        package static let name = 50
        package static let bio = 160
        package static let location = 30
        package static let website = 100
    }

    @ObservableState
    package struct State: Equatable {
        let user: User
        var name: String
        var bio: String
        var location: String
        var website: String
        /// A new avatar, square JPEG, not yet saved.
        var avatar: Data?
        /// A new header, 3:1 JPEG, not yet saved.
        var banner: Data?
        var isSaving = false
        var errorMessage: String?

        package init(user: User) {
            self.user = user
            name = user.name
            bio = user.bio
            location = user.location
            website = user.websiteURL?.absoluteString ?? user.website ?? ""
        }

        var hasChanges: Bool {
            name != user.name || bio != user.bio || location != user.location
                || website != (user.websiteURL?.absoluteString ?? user.website ?? "") || avatar != nil || banner != nil
        }

        var isValid: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= Limit.name
                && bio.count <= Limit.bio && location.count <= Limit.location && website.count <= Limit.website
        }

        var canSave: Bool { hasChanges && isValid && !isSaving }
    }

    package enum Action: BindableAction {
        case avatarPicked(Data)
        case bannerPicked(Data)
        case binding(BindingAction<State>)
        case cancelButtonTapped
        case delegate(Delegate)
        case errorDismissed
        case saveButtonTapped
        case saveResponse(Result<User, any Error>)

        @CasePathable
        package enum Delegate: Equatable {
            case saved(User)
        }
    }

    @Dependency(TwitterClient.self) var client
    @Dependency(\.dismiss) var dismiss

    package init() {}

    package var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .avatarPicked(let data):
                state.avatar = data
                return .none

            case .bannerPicked(let data):
                state.banner = data
                return .none

            case .binding:
                return .none

            case .cancelButtonTapped:
                guard !state.isSaving else { return .none }
                return .run { _ in await dismiss() }

            case .delegate:
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none

            case .saveButtonTapped:
                guard state.canSave else { return .none }
                state.isSaving = true
                let edit = ProfileEdit(
                    name: state.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    bio: state.bio.trimmingCharacters(in: .whitespacesAndNewlines),
                    location: state.location.trimmingCharacters(in: .whitespacesAndNewlines),
                    website: state.website.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatar: state.avatar,
                    banner: state.banner
                )
                return .run { send in
                    await send(.saveResponse(Result { try await client.updateProfile(edit) }))
                }

            case .saveResponse(.success(let user)):
                state.isSaving = false
                return .run { send in
                    await send(.delegate(.saved(user)))
                    await dismiss()
                }

            case .saveResponse(.failure(let error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
