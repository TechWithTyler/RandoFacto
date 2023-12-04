//
//  RandoFactoViewModel.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

// This object manages the data storage and authentication in this app.
class RandoFactoViewModel: ObservableObject {
    
    // MARK: - Properties - Objects
    
    // The fact generator
    var factGenerator = FactGenerator()
    
    @Published var authenticationManager: AuthenticationManager
    
    @Published var networkManager: NetworkManager
    
    @Published var favoriteFactsDatabase: FavoriteFactsDatabase 
    
    @Published var favoriteFactsSearchManager: FavoriteFactSearchManager
    
    @Published var errorManager: ErrorManager
    
    // MARK: - Properties - Strings
    
    // The text to display in the fact text view.
    // Properties with the @Published property wrapper will trigger updates to SwiftUI views when they're changed.
    @Published var factText: String = loadingString
    
    // MARK: - Properties - Integers
    
    // The current fact text size as an Int.
    var fontSizeValue: Int {
        return Int(factTextSize)
    }
    
    // Whether to display one of the user's favorite facts or generate a random fact when the app launches. This setting resets to 0 (Random Fact), and is hidden, when the user logs out or deletes their account.
    // The @AppStorage property wrapper binds a property to the given UserDefaults key name. Such properties behave the same as UserDefaults get/set properties such as the "5- or 10-frame" setting in SkippyNums, but with the added benefit of automatic UI refreshing.
    @AppStorage("initialFact") var initialFact: Int = 0
    
    // The text size for facts.
    @AppStorage("factTextSize") var factTextSize: Double = minFontSize
    
    // MARK: - Properties - Pages
    
    // The page currently selected in the sidebar/top-level view. On macOS, the settings view is accessed by the Settings menu item in the app menu instead of as a page.
    @Published var selectedPage: AppPage? = .randomFact
    
    #if os(macOS)
    // THe page currently selected in the Settings window on macOS.
    @AppStorage("selectedSettingsPage") var selectedSettingsPage: SettingsPage = .display
    #endif
    
    // Whether the fact text view is displaying something other than a fact (i.e., a loading or error message).
    var notDisplayingFact: Bool {
        return factText == loadingString || factText == generatingString
    }
    
    // Whether the displayed fact is saved as a favorite.
    var displayedFactIsSaved: Bool {
        return !favoriteFactsDatabase.favoriteFacts.filter({$0.text == factText}).isEmpty
    }
    
    // MARK: - Initialization
    
    // This initializer sets up the network path monitor and Firestore listeners, then displays a fact to the user.
    init() {
        // 1. Configure the app's managers.
        let manager4 = ErrorManager(authenticationManager: nil)
        let manager1 = AuthenticationManager(errorManager: manager4, favoriteFactsDatabase: nil)
        let manager2 = FavoriteFactsDatabase(authenticationManager: nil, errorManager: manager4, networkManager: nil)
        let manager3 = NetworkManager(favoriteFactsDatabase: nil, errorManager: manager4)
        // 2. Set the dependencies after all managers are initialized.
        manager1.favoriteFactsDatabase = manager2
        manager2.authenticationManager = manager1
        manager2.networkManager = manager3
        manager3.favoriteFactsDatabase = manager2
        // 3. Assign managers to the corresponding properties.
        self.authenticationManager = manager1
        self.favoriteFactsDatabase = manager2
        self.networkManager = manager3
        self.errorManager = manager4
        let manager5 = FavoriteFactSearchManager(favoriteFactsDatabase: manager2)
        self.favoriteFactsSearchManager = manager5
        // 4. After waiting a second for the network path monitor to configure and detect the current network connection status, load all the favorite facts into the app.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [self] in
            authenticationManager.addRegisteredUsersHandler()
            favoriteFactsDatabase.loadFavoriteFactsForCurrentUser { [self] in
                guard notDisplayingFact else { return }
                // 3. Generate a random fact.
                if initialFact == 0 || favoriteFactsDatabase.favoriteFacts.isEmpty || !authenticationManager.userLoggedIn {
                    generateRandomFact()
                } else {
                    getRandomFavoriteFact()
                }
            }
        }
    }
    
    // MARK: - Fact Generation
    
    // This method tries to access a random facts API URL and parse JSON data it gives back. It then feeds the fact through another API URL to check if it contains inappropriate words. We do it this way so we don't have to include inappropriate words in the app/code itself. If everything is successful, the fact is displayed to the user, or if an error occurs, it's logged.
    func generateRandomFact() {
        // 1. Ask the fact generator to perform its URL requests to generate a random fact.
        factGenerator.generateRandomFact {
            // 2. Display a message before starting fact generation.
            DispatchQueue.main.async { [self] in
                factText = generatingString
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
        let favoriteFact = favoriteFactsDatabase.favoriteFacts.randomElement()?.text ?? factUnavailableString
        DispatchQueue.main.async { [self] in
            factText = favoriteFact
        }
    }
    
    // This method displays favorite and switches to the "Random Fact" page.
    func displayFavoriteFact(_ favorite: String) {
        DispatchQueue.main.async { [self] in
            factText = favorite
            dismissFavoriteFacts()
        }
    }
    
    // MARK: - Favorite Facts - Unavailable Handler
    
    // This method switches the current page from favoriteFacts to randomFact if a user logs out or is being deleted.
    func dismissFavoriteFacts() {
        if selectedPage == .favoriteFacts {
            DispatchQueue.main.async { [self] in
                selectedPage = .randomFact
            }
        }
    }
    
}
