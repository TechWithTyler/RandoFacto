//
//  WindowStateManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

// Manages the fact generation/display and pages.
class WindowStateManager: NSObject, ObservableObject {

    // MARK: - Properties - Objects

    // The fact generator.
#if(DEBUG)
    @Published
#endif
    var factGenerator = FactGenerator()

    var speechManager: SpeechManager

    var errorManager: ErrorManager

    var favoriteFactsDatabase: FavoriteFactsDatabase

    var favoriteFactsDisplayManager: FavoriteFactsDisplayManager

    var authenticationManager: AuthenticationManager

    // MARK: - Properties - Strings

    // The text to display in the fact text view.
    // Properties with the @Published property wrapper will trigger updates to SwiftUI views when they're changed. Their values must be value types (i.e. structs), not reference types (i.e. classes).
    @Published var factText: String = loadingString

    // The fact currently being spoken.
    @Published var factBeingSpoken: String = String()

    // The @AppStorage property wrapper binds a property to the given UserDefaults key name. Such properties behave the same as UserDefaults get/set properties such as the "5- or 10-frame" setting in SkippyNums, but with the added benefit of automatic UI refreshing.
    // The ID string of the currently selected voice.
    @AppStorage(UserDefaults.KeyNames.selectedVoiceID) var selectedVoiceID: String = SADefaultVoiceID

    // The voices that are currently available on the device.
    @Published var voices: [AVSpeechSynthesisVoice] = []

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

    // Whether the onboarding sheet should appear on the next app launch (i.e., the first launch of version 2024.2 or later, or after resetting the app).
    @AppStorage(UserDefaults.KeyNames.shouldOnboard) var shouldOnboard: Bool = true

    // Whether the onboarding sheet should be/is being displayed.
    @Published var showingOnboarding: Bool = false

    // Whether favorite facts are available to be displayed.
    var favoriteFactsAvailable: Bool {
        return authenticationManager.userLoggedIn && !authenticationManager.isDeletingAccount && !favoriteFactsDatabase.favoriteFacts.isEmpty
    }

    // Whether the window is loading.
    var isLoading: Bool {
        return factText == loadingString
    }

    // Whether the fact text view is displaying something other than a fact (i.e., a loading message).
    var factTextDisplayingMessage: Bool {
        return isLoading || factText == generatingRandomFactString || favoriteFactsDisplayManager.randomizerRunning
    }

    // Whether the displayed fact is saved as a favorite.
    var displayedFactIsSaved: Bool {
        return !favoriteFactsDatabase.favoriteFacts.filter({$0.text == factText}).isEmpty
    }

    // MARK: - Properties - Integers

    // The current fact text size as an Int.
    var factTextSizeAsInt: Int {
        return Int(factTextSize)
    }

    // MARK: - Initialization

    init(speechManager: SpeechManager, errorManager: ErrorManager, favoriteFactsDatabase: FavoriteFactsDatabase, favoriteFactsDisplayManager: FavoriteFactsDisplayManager, authenticationManager: AuthenticationManager) {
        // 1. Link the managers.
        self.speechManager = speechManager
        self.errorManager = errorManager
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.favoriteFactsDisplayManager = favoriteFactsDisplayManager
        self.authenticationManager = authenticationManager
        super.init()
        // 2. After waiting 2 seconds for network connection checking and favorite facts database loading to complete, display a fact to the user.
        displayInitialFact()
    }

    // MARK: - Fact Generation

    // This method either generates a random fact or displays a random favorite fact to the user, based on authentication state, number of favorite facts, and settings.
    func displayInitialFact() {
        // 1. Wait 2 seconds to give the network path monitor time to configure.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(initializationTime)) { [self] in
            // 2. If "Initial Display" is set to "Generate Random Fact", or there are no favorite facts/the user isn't logged in, generate a random fact. If it's set to "Get Random Favorite Fact", display a random favorite fact. If it's set to "Show Favorite Facts List", switch to the favorite facts list.
            if favoriteFactsDatabase.initialFact == 0 || favoriteFactsDatabase.favoriteFacts.isEmpty || !authenticationManager.userLoggedIn {
                generateRandomFact()
            } else if favoriteFactsDatabase.initialFact == 2 {
                displayFavoriteFact((favoriteFactsDatabase.favoriteFacts.randomElement()?.text)!, forInitialization: true)
                selectedPage = .favoriteFacts
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
                speechManager.speechSynthesizer.stopSpeaking(at: .immediate)
                factText = generatingRandomFactString
            }
        } completionHandler: { [self]
            fact, error in
            DispatchQueue.main.async { [self] in
                if let fact = fact {
                    // 3. If we get a fact, display it. If it matches a favorite fact and "Skip Favorites On Fact Generation" is enabled, generate a new random fact until we get a non-favorite.
                    if favoriteFactsDatabase.favoriteFacts.contains(where: {$0.text == fact}) && favoriteFactsDisplayManager.skipFavoritesOnFactGeneration {
                        generateRandomFact()
                    } else {
                        displayFact(fact)
                    }
                } else if let error = error {
                    // 4. If an error occurs, log it.
                    factText = factUnavailableString
                        errorManager.showError(error)
                }
            }
        }
    }

    // This method sets factText to fact.
    func displayFact(_ fact: String) {
        // 1. Set factText to the fact.
        factText = fact
        // 2. If the option to speak on fact display is enabled, speak the fact.
        if speechManager.speakOnFactDisplay && !favoriteFactsDisplayManager.randomizerRunning {
            speechManager.speakFact(fact: fact)
        }
    }

}

extension WindowStateManager {

    // MARK: - Favorite Facts - Toggle Favorite

    func toggleFavoriteFact() {
        DispatchQueue.main.async { [self] in
            if displayedFactIsSaved {
                favoriteFactsDisplayManager.favoriteFactToDelete = factText
                favoriteFactsDisplayManager.showingDeleteFavoriteFact = true
            } else {
                favoriteFactsDatabase.saveFactToFavorites(factText) { [self] error in
                    if let error = error {
                        errorManager.showError(error)
                    }
                }
            }
        }
    }

    // MARK: - Favorite Facts - Get Random Favorite Fact

    // This method gets a random fact from the favorite facts list and sets factText to its text.
    func getRandomFavoriteFact() {
        // 1. Create the block that will be performed for each randomizer iteration if the randomizer effect is turned on, or just once if it's turned off.
        let block: (() -> Void) = { [self] in
            let favoriteFact = favoriteFactsDatabase.favoriteFacts.randomElement()?.text ?? factUnavailableString
            displayFact(favoriteFact)
        }
        DispatchQueue.main.async { [self] in
            // 2. Dismiss the favorite facts list and stop speaking.
            speechManager.speechSynthesizer.stopSpeaking(at: .immediate)
            dismissFavoriteFacts()
            // 3. If the randomizer effect is enabled and there are at least 5 favorite facts, start the randomizer timer, calling the above block with each iteration.
            if favoriteFactsDisplayManager.favoriteFactsRandomizerEffect && favoriteFactsDatabase.favoriteFacts.count >= 5 {
                favoriteFactsDisplayManager.setupRandomizerTimer {
                    withAnimation {
                        block()
                    }
                }
            } else {
                // 4. Otherwise, nil-out the randomizer timer and call the above block once.
                favoriteFactsDisplayManager.stopRandomizerTimer()
                block()
            }
        }
    }

    // MARK: - Favorite Facts - Display Favorite Fact

    // This method displays favorite and switches to the "Random Fact" page.
    func displayFavoriteFact(_ favorite: String, forInitialization: Bool = false) {
        DispatchQueue.main.async { [self] in
            speechManager.speechSynthesizer.stopSpeaking(at: .immediate)
            displayFact(favorite)
            if !forInitialization {
                dismissFavoriteFacts()
            }
        }
    }

    // MARK: - Favorite Facts - Dismiss

    // This method switches the current page from favoriteFacts to randomFact when fact generation or the randomizer timer starts, or if a user logs out or is being deleted.
    func dismissFavoriteFacts() {
        if selectedPage == .favoriteFacts {
            DispatchQueue.main.async { [self] in
                selectedPage = .randomFact
            }
        }
    }

}
