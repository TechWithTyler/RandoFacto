//
//  SettingsManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/19/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SheftAppsStylishUI

// Manages settings window state.
class SettingsManager: NSObject, ObservableObject {

    // MARK: - Properties - Objects

    var factGenerator: FactGenerator = FactGenerator()

    var favoriteFactsDisplayManager: FavoriteFactsDisplayManager

    var authenticationManager: AuthenticationManager

    var errorManager: ErrorManager

    var speechManager: SpeechManager

    // MARK: - Properties - Strings

    @AppStorage(UserDefaults.KeyNames.selectedVoiceID) var selectedVoiceID: String = SADefaultVoiceID

    // MARK: - Properties - Doubles

    // The text size for facts.
    @AppStorage(UserDefaults.KeyNames.factTextSize) var factTextSize: Double = SATextViewIdealMinFontSize

    // MARK: - Properties - Pages

    // The page currently selected in the sidebar/top-level view. On macOS, the settings view is accessed by the Settings menu item in the app menu instead of as a page.
    @Published var selectedPage: AppPage? = .randomFact {
        didSet {
            speechManager.speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

#if os(macOS)
    // The page currently selected in the Settings window on macOS.
    @AppStorage(UserDefaults.KeyNames.selectedSettingsPage) var selectedSettingsPage: SettingsPage = .facts
#endif

    // MARK: - Properties - Booleans

    // Whether the reset alert should be/is being displayed.
    @Published var showingResetAlert: Bool = false

    // Whether the onboarding sheet should appear on the next app launch (i.e., the first launch of version 2024.2 or later, or after resetting the app).
    @AppStorage(UserDefaults.KeyNames.shouldOnboard) var shouldOnboard: Bool = true

    // MARK: - Initialization

    init(favoriteFactsDisplayManager: FavoriteFactsDisplayManager, authenticationManager: AuthenticationManager, errorManager: ErrorManager, speechManager: SpeechManager) {
        self.favoriteFactsDisplayManager = favoriteFactsDisplayManager
        self.authenticationManager = authenticationManager
        self.errorManager = errorManager
        self.speechManager = speechManager
    }

    // MARK: - Reset

    // This method resets all settings to default and logs out the current user.
    func resetApp() {
        // 1. Logout the current user, which will reset all login-required settings to default.
        authenticationManager.logoutCurrentUser { [self] error in
            if let error = error {
                errorManager.showError(error)
            }
        }
        // 2. Reset all in-app/non-accessibility settings.
        factTextSize = SATextViewIdealMinFontSize
        selectedPage = .randomFact
        favoriteFactsDisplayManager.favoriteFactsRandomizerClick = true
        favoriteFactsDisplayManager.searchText.removeAll()
        favoriteFactsDisplayManager.sortFavoriteFactsAscending = false
        selectedVoiceID = SADefaultVoiceID
        // 3. Reset the selected settings page on macOS.
        #if os(macOS)
        selectedSettingsPage = .facts
        #endif
        // 4. Set the onboarding sheet to show on the next launch.
        shouldOnboard = true
        // 5. In internal builds, reset the fact generator URL request timeout interval.
        #if DEBUG
        factGenerator.urlRequestTimeoutInterval = defaultURLRequestTimeoutInterval
        #endif
    }

}
