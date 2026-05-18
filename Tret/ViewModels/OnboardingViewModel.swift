import Foundation
import SwiftUI
import UIKit

@MainActor
@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable, Identifiable {
        case usernamePhoto
        case bio
        case languages
        case linksHashtags
        case preview
        var id: Int { rawValue }
    }

    enum UsernameStatus: Equatable {
        case idle
        case validating
        case available
        case taken
        case invalid(String)
    }

    // Источник данных авторизованной сессии
    let pending: AppState.PendingProfile

    // --- Поля профиля ---
    var username: String = ""
    var usernameStatus: UsernameStatus = .idle
    var bio: String = ""
    var selectedLanguages: [String] = []
    var githubRaw: String = ""
    var websiteRaw: String = ""
    var hashtagInput: String = ""
    var hashtags: [String] = []

    // --- UI state ---
    var currentStep: Step = .usernamePhoto
    var isSubmitting = false
    var submitError: String?

    private var usernameCheckTask: Task<Void, Never>?

    private let userService: UserServiceProtocol

    init(
        pending: AppState.PendingProfile,
        userService: UserServiceProtocol = UserService.shared
    ) {
        self.pending = pending
        self.userService = userService

        let suggestions = UsernameGenerator.suggestions(
            displayName: pending.displayName,
            email: pending.email,
            count: 1
        )
        self.username = suggestions.first ?? ""
        if !username.isEmpty {
            scheduleUsernameCheck()
        }
    }

    // MARK: - Step Navigation

    var stepIndex: Int { currentStep.rawValue }
    var stepCount: Int { Step.allCases.count }

    func goNext() {
        guard canProceed else { return }
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func goBack() {
        if let previous = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = previous
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case .usernamePhoto:
            return usernameStatus == .available
        case .bio:
            return Validators.validateBio(bio) == .valid
        case .languages:
            return !selectedLanguages.isEmpty
        case .linksHashtags:
            if !githubRaw.isEmpty && !URLValidator.isValidGitHub(githubRaw) { return false }
            if !websiteRaw.isEmpty && !URLValidator.isValid(websiteRaw) { return false }
            return true
        case .preview:
            return true
        }
    }

    // MARK: - Username

    func usernameChanged(_ newValue: String) {
        let normalized = newValue.lowercased()
        username = normalized
        let validation = Validators.validateUsername(normalized)
        if validation != .valid {
            usernameStatus = .invalid(validation.userMessage ?? "Некорректное имя")
            usernameCheckTask?.cancel()
            return
        }
        usernameStatus = .validating
        scheduleUsernameCheck()
    }

    func applySuggestion(_ suggested: String) {
        usernameChanged(suggested)
    }

    var usernameSuggestions: [String] {
        UsernameGenerator.suggestions(
            displayName: pending.displayName,
            email: pending.email,
            count: 4
        )
    }

    private func scheduleUsernameCheck() {
        usernameCheckTask?.cancel()
        let nameSnapshot = username
        usernameCheckTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(AppConstants.usernameDebounceMilliseconds))
            guard let self else { return }
            guard !Task.isCancelled, self.username == nameSnapshot else { return }
            do {
                let available = try await self.userService.checkUsernameAvailable(nameSnapshot)
                guard !Task.isCancelled, self.username == nameSnapshot else { return }
                self.usernameStatus = available ? .available : .taken
            } catch {
                guard !Task.isCancelled, self.username == nameSnapshot else { return }
                self.usernameStatus = .invalid(error.localizedDescription)
            }
        }
    }

    // MARK: - Bio

    func bioChanged(_ raw: String) {
        if raw.count > AppConstants.maxBioCharacters {
            bio = String(raw.prefix(AppConstants.maxBioCharacters))
        } else {
            bio = raw
        }
    }

    var bioRemaining: Int {
        AppConstants.maxBioCharacters - bio.count
    }

    // MARK: - Languages

    func toggleLanguage(_ language: ProgrammingLanguage) {
        if let index = selectedLanguages.firstIndex(of: language.id) {
            selectedLanguages.remove(at: index)
            return
        }
        guard selectedLanguages.count < AppConstants.maxProgrammingLanguages else { return }
        selectedLanguages.append(language.id)
    }

    var canAddMoreLanguages: Bool {
        selectedLanguages.count < AppConstants.maxProgrammingLanguages
    }

    // MARK: - Hashtags

    func addHashtag() {
        let normalized = Validators.normalizeHashtag(hashtagInput)
        guard Validators.validateHashtag(normalized) == .valid else { return }
        guard hashtags.count < AppConstants.maxHashtags else { return }
        guard !hashtags.contains(normalized) else { return }
        hashtags.append(normalized)
        hashtagInput = ""
    }

    func removeHashtag(_ tag: String) {
        hashtags.removeAll { $0 == tag }
    }

    var canAddMoreHashtags: Bool {
        hashtags.count < AppConstants.maxHashtags
    }

    // MARK: - Submit

    func submit(appState: AppState) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }

        do {
            let avatarURL = pending.photoURL?.absoluteString

            let now = Date()
            let user = AppUser(
                id: pending.uid,
                email: pending.email,
                displayName: pending.displayName.isEmpty ? username : pending.displayName,
                username: username,
                avatarURL: avatarURL,
                bio: bio,
                programmingLanguages: selectedLanguages,
                githubURL: URLValidator.normalize(githubRaw),
                websiteURL: URLValidator.normalize(websiteRaw),
                hashtags: hashtags,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                repostsCount: 0,
                createdAt: now,
                updatedAt: now
            )

            try await userService.createUser(user)
            appState.completeOnboarding(user: user)
        } catch let error as NSError {
            if error.code == 409 {
                submitError = "Имя пользователя \(username) уже занято — попробуйте другое."
                currentStep = .usernamePhoto
                usernameStatus = .taken
            } else {
                submitError = error.localizedDescription
            }
        }
    }
}
