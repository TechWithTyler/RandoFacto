//
//  AppStateManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase
import Speech
import SheftAppsStylishUI

// Manages the fact generation/display and pages. This is not to be confused with an NSApplicationDelegate or UIApplicationDelegate.
class AppStateManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    // MARK: - Properties - Objects
    
    // The fact generator.
    #if(DEBUG)
    @Published
    #endif
    var factGenerator = FactGenerator()
    
    var errorManager: ErrorManager
    
    var networkConnectionManager: NetworkConnectionManager
    
    var favoriteFactsDatabase: FavoriteFactsDatabase
    
    var favoriteFactsListDisplayManager: FavoriteFactsListDisplayManager
    
    var authenticationManager: AuthenticationManager
    
    var speechSynthesizer = AVSpeechSynthesizer()

    // MARK: - Properties - Strings
    
    // The text to display in the fact text view.
    // Properties with the @Published property wrapper will trigger updates to SwiftUI views when they're changed. Their values must be value types (i.e. structs), not reference types (i.e. classes).
    @Published var factText: String = loadingString
    
    // The fact currently being spoken.
    @Published var factBeingSpoken: String = String()
    
    // The @AppStorage property wrapper binds a property to the given UserDefaults key name. Such properties behave the same as UserDefaults get/set properties such as the "5- or 10-frame" setting in SkippyNums, but with the added benefit of automatic UI refreshing.
    // The ID string of the currently selected voice.
    @AppStorage("selectedVoiceID") var selectedVoiceID: String = defaultVoiceID

    // The voices that are currently available on the device.
    @Published var voices: [AVSpeechSynthesisVoice] = []

    // MARK: - Properties - Integers

    // The current fact text size as an Int.
    var factTextSizeAsInt: Int {
        return Int(factTextSize)
    }

    // The text size for facts.
    @AppStorage("factTextSize") var factTextSize: Double = SATextViewMinFontSize

    // MARK: - Properties - Pages
    
    // The page currently selected in the sidebar/top-level view. On macOS, the settings view is accessed by the Settings menu item in the app menu instead of as a page.
    @Published var selectedPage: AppPage? = .randomFact {
        didSet {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    #if os(macOS)
    // The page currently selected in the Settings window on macOS.
    @AppStorage("selectedSettingsPage") var selectedSettingsPage: SettingsPage = .display
    #endif
    
    // MARK: - Properties - Booleans
    
    // Whether the onboarding sheet should appear on the next app launch (i.e., the first launch of version 2024.2 or later, or after resetting the app).
    @AppStorage("shouldOnboard") var shouldOnboard: Bool = true

    // Whether the onboarding sheet should be/is being displayed.
    @Published var showingOnboarding: Bool = false
    
    // Whether the reset alert should be/is being displayed.
    @Published var showingResetAlert: Bool = false

    // Whether favorite facts are available to be displayed.
    var favoriteFactsAvailable: Bool {
        return authenticationManager.userLoggedIn && !favoriteFactsDatabase.favoriteFacts.isEmpty && !authenticationManager.isDeletingAccount
    }
    
    // Whether the app is loading.
    var isLoading: Bool {
        return factText == loadingString
    }
    
    // Whether the fact text view is displaying something other than a fact (i.e., a loading message).
    var factTextDisplayingMessage: Bool {
        return isLoading || factText == generatingRandomFactString || favoriteFactsDatabase.randomizerIterations > 0
    }
    
    // Whether the displayed fact is saved as a favorite.
    var displayedFactIsSaved: Bool {
        return !favoriteFactsDatabase.favoriteFacts.filter({$0.text == factText}).isEmpty
    }
    
    // MARK: - Initialization
    
    init(errorManager: ErrorManager, networkConnectionManager: NetworkConnectionManager, favoriteFactsDatabase: FavoriteFactsDatabase, favoriteFactsListDisplayManager: FavoriteFactsListDisplayManager, authenticationManager: AuthenticationManager) {
        // 1. Link the managers.
        self.errorManager = errorManager
        self.networkConnectionManager = networkConnectionManager
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.favoriteFactsListDisplayManager = favoriteFactsListDisplayManager
        self.authenticationManager = authenticationManager
        super.init()
        // 3. Set the speech synthesizer delegate and load the list of installed voices.
        speechSynthesizer.delegate = self
        DispatchQueue.main.async { [self] in
            loadVoices()
        }
        // 3. After waiting 2 seconds for network connection checking and favorite facts database loading to complete, display a fact to the user.
        displayInitialFact()
    }
    
    // MARK: - Fact Generation
    
    // This method either generates a random fact or displays a random favorite fact to the user, based on authentication state, number of favorite facts, and settings.
    func displayInitialFact() {
        // 1. Wait 2 seconds to give the network path monitor time to configure.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(initializationTime)) { [self] in
            // 2. Display a fact to the user.
            if favoriteFactsDatabase.initialFact == 0 || favoriteFactsDatabase.favoriteFacts.isEmpty || !authenticationManager.userLoggedIn {
                generateRandomFact()
            } else {
                getRandomFavoriteFact()
            }
        }
    }
    
    // This method tries to access a random facts API URL and parse JSON data it gives back. It then feeds the fact through another API URL to check if it contains inappropriate words. We do it this way so we don't have to include inappropriate words in the app/code itself. If everything is successful, the fact is displayed to the user, or if an error occurs, it's logged.
    func generateRandomFact() {
        // 1. Ask the fact generator to perform its URL requests to generate a random fact.
        factGenerator.generateRandomFact { [self] in
            // 2. Display a message before starting fact generation.
            DispatchQueue.main.async { [self] in
                dismissFavoriteFacts()
                speechSynthesizer.stopSpeaking(at: .immediate)
                factText = generatingRandomFactString
            }
        } completionHandler: { [self]
            fact, error in
            DispatchQueue.main.async { [self] in
                if let fact = fact {
                    // 3. If we get a fact, display it.
                    factText = fact
                } else if let error = error {
                    // 4. If an error occurs, log it.
                    factText = factUnavailableString
                    errorManager.showError(error)
                }
            }
        }
    }
    
    // MARK: - Favorite Facts - Display Favorite Fact

    // This method gets a random fact from the favorite facts list and sets factText to its text.
    func getRandomFavoriteFact() {
        let block: (() -> Void) = { [self] in
            let favoriteFact = favoriteFactsDatabase.favoriteFacts.randomElement()?.text ?? factUnavailableString
            factText = favoriteFact
        }
        DispatchQueue.main.async { [self] in
            speechSynthesizer.stopSpeaking(at: .immediate)
            dismissFavoriteFacts()
            if favoriteFactsDatabase.favoriteFactsRandomizerEffect && favoriteFactsDatabase.favoriteFacts.count >= 5 {
                favoriteFactsDatabase.setupRandomizerTimer {
                    withAnimation {
                        block()
                    }
                }
            } else {
                favoriteFactsDatabase.randomizerTimer?.invalidate()
                favoriteFactsDatabase.randomizerTimer = nil
                block()
            }
        }
    }

    // This method displays favorite and switches to the "Random Fact" page.
    func displayFavoriteFact(_ favorite: String) {
        DispatchQueue.main.async { [self] in
            factText = favorite
            speechSynthesizer.stopSpeaking(at: .immediate)
            dismissFavoriteFacts()
        }
    }
    
    // MARK: - Favorite Facts - Dismiss
    
    // This method switches the current page from favoriteFacts to randomFact if a user logs out or is being deleted.
    func dismissFavoriteFacts() {
        if selectedPage == .favoriteFacts {
            DispatchQueue.main.async { [self] in
                selectedPage = .randomFact
            }
        }
    }
    
    // MARK: - Reset
    
    // This method resets all settings to default and logs out the current user.
    func resetApp() {
        // 1. Logout the current user, which will reset all login-required settings to default.
        authenticationManager.logoutCurrentUser()
        // 2. Reset all settings.
        factTextSize = SATextViewMinFontSize
        selectedPage = .randomFact
        favoriteFactsListDisplayManager.searchText.removeAll()
        favoriteFactsListDisplayManager.sortFavoriteFactsAscending = false
        selectedVoiceID = defaultVoiceID
        // 3. Reset the selected settings page on macOS.
        #if os(macOS)
        selectedSettingsPage = .display
        #endif
        // 4. Set the onboarding sheet to show on the next launch.
        shouldOnboard = true
    }
    
}

extension AppStateManager {
    
    // MARK: - Speech - Load Voices
    
    // This method loads all installed voices into the app.
    func loadVoices() {
        if #available(macOS 14, iOS 17, visionOS 1, *) {
            AVSpeechSynthesizer.requestPersonalVoiceAuthorization { [self] status in
                voices = AVSpeechSynthesisVoice.speechVoices().filter({$0.language == "en-US"})
            }
        } else {
            voices = AVSpeechSynthesisVoice.speechVoices().filter({$0.language == "en-US"})
        }
    }
    
    // MARK: - Speech - Speak Fact
    
    // This method speaks fact using the selected voice.
    func speakFact(fact: String) {
        DispatchQueue.main.async { [self] in
            speechSynthesizer.stopSpeaking(at: .immediate)
            if factBeingSpoken != fact {
                let utterance = AVSpeechUtterance(string: fact)
                utterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceID)
                speechSynthesizer.speak(utterance)
            }
        }
    }
    
    // MARK: - Speech - Synthesizer Delegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        factBeingSpoken = utterance.speechString
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        factBeingSpoken = String()
    }
    
}
