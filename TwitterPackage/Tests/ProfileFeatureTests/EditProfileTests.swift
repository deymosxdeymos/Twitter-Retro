import ComposableArchitecture
import Foundation
import Testing

@testable import Models
@testable import ProfileFeature
@testable import TwitterClient
@testable import TwitterDatabase

@MainActor
struct EditProfileTests {
    @Test
    func saveSendsTrimmedEditsAndUpdatesProfileAndViewer() async {
        let sent = LockIsolated<ProfileEdit?>(nil)
        let saved = {
            var user = User.mock
            user.name = "New Name"
            user.bio = "Hello"
            return user
        }()
        let avatar = Data([1, 2, 3])
        var state = ProfileFeature.State(user: .mock, isViewer: true)
        state.editProfile = EditProfileFeature.State(user: .mock)
        let store = TestStore(initialState: state) {
            ProfileFeature()
        } withDependencies: {
            $0[TwitterClient.self].updateProfile = { edit in
                sent.setValue(edit)
                return saved
            }
            $0[TimelineCache.self] = .previewValue
        }

        await store.send(\.editProfile.binding.name, "  New Name ") {
            $0.editProfile?.name = "  New Name "
        }
        await store.send(\.editProfile.binding.bio, "Hello") {
            $0.editProfile?.bio = "Hello"
        }
        await store.send(\.editProfile.avatarPicked, avatar) {
            $0.editProfile?.avatar = avatar
        }
        await store.send(\.editProfile.saveButtonTapped) {
            $0.editProfile?.isSaving = true
        }
        await store.receive(\.editProfile.saveResponse.success) {
            $0.editProfile?.isSaving = false
        }
        await store.receive(\.editProfile.delegate.saved) {
            $0.user = saved
        }
        await store.receive(\.editProfile.dismiss) {
            $0.editProfile = nil
        }

        #expect(sent.value?.name == "New Name")
        #expect(sent.value?.bio == "Hello")
        #expect(sent.value?.avatar == avatar)
        @Shared(.viewer) var viewer
        #expect(viewer == saved)
    }

    @Test
    func saveNeedsAChangeAndANameWithinLimits() {
        var state = EditProfileFeature.State(user: .mock)
        #expect(!state.canSave)
        state.bio = String(repeating: "a", count: EditProfileFeature.Limit.bio + 1)
        #expect(!state.canSave)
        state.bio = "Short"
        #expect(state.canSave)
        state.name = "   "
        #expect(!state.canSave)
    }

    @Test
    func failureKeepsTheEditsAndExplains() async {
        struct Failure: LocalizedError { var errorDescription: String? { "Nope" } }
        var state = EditProfileFeature.State(user: .mock)
        state.bio = "Changed"
        let store = TestStore(initialState: state) {
            EditProfileFeature()
        } withDependencies: {
            $0[TwitterClient.self].updateProfile = { _ in throw Failure() }
        }

        await store.send(.saveButtonTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveResponse.failure) {
            $0.isSaving = false
            $0.errorMessage = "Nope"
        }
    }
}
