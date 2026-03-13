//
//  FavoriteFactsDisplayManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/5/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import AVFoundation

// Handles searching and sorting of the favorite facts list and the display of favorite facts and related dialogs.
class FavoriteFactsDisplayManager: ObservableObject {

    // MARK: - Properties - Favorite Facts Database

    var favoriteFactsDatabase: FavoriteFactsDatabase

    // MARK: - Properties - Strings

    // The search text.
    @Published var searchText = String()

    // The favorite facts that match searchText, or all favorite facts if searchText is empty.
    var searchResults: [String] {
        // 1. Define the content being searched.
        let content = favoriteFactsDatabase.favoriteFacts
        // 2. Get the text from each FavoriteFact object.
        let facts = content.map { $0.text }
        // 3. If searchText is empty, return all facts.
        if searchText.isEmpty {
            return facts
        } else {
            // 4. If searchText contains text, return facts that contain all or part of the search text.
            return facts.filter { fact in
                let range = fact.range(of: searchText, options: .caseInsensitive)
                let textMatchesSearchTerm = range != nil
                return textMatchesSearchTerm
            }
        }
    }

    // The favorite facts list/search results, sorted in either ascending (A-Z) or descending (Z-A) order.
    var sortedFavoriteFacts: [String] {
        return searchResults.sorted { a, z in
            let sortCondition = sortFavoriteFactsAscending ? a < z : z < a
            return sortCondition
        }
    }

    // MARK: - Properties - Integers

    // The maximum number of iterations for the randomizer effect. The randomizer effect starts out fast and gradually slows down, by using the equation randomizerIterations divided by (maxRandomizerIterations times 4).
    let maxRandomizerIterations: Int = 20

    // The number of iterations the randomizer effect has gone through. The randomizer stops after this property reaches maxRandomizerIterations.
    var randomizerIterations: Int = 0

    // MARK: - Properties - Floats

    // The blur radius of the fact text view when the randomizer effect is playing.
    let randomizerBlurRadius: CGFloat = 30

    // MARK: - Properties - Randomizer Timer

    // The timer used for the randomizer effect.
    var randomizerTimer: Timer? = nil

    // MARK: - Properties - Randomizer Click Player

    // The audio player used for the randomizer click sound.
    var audioPlayer: AVAudioPlayer? = nil

    // MARK: - Properties - Booleans

    // Whether RandoFacto should "spin through" a user's favorite facts when getting a random favorite fact. This setting resets to off and is hidden when the user logs out or deletes their account.
    @AppStorage(UserDefaults.KeyNames.favoriteFactsRandomizerEffect) var favoriteFactsRandomizerEffect: Bool = false

    // Whether a click is heard during the favorite fact randomizer effect.
    @AppStorage(UserDefaults.KeyNames.favoriteFactsRandomizerClick) var favoriteFactsRandomizerClick: Bool = true

    // Whether RandoFacto should generate a new random fact if it generates a fact that matches a favorite.
    @AppStorage(UserDefaults.KeyNames.skipFavoritesOnFactGeneration) var skipFavoritesOnFactGeneration: Bool = false

    // Whether the randomizer effect is playing.
    var randomizerRunning: Bool {
        return randomizerIterations > 0
    }

    // The sort order of the favorite facts list (false = Z-A, true = A-Z).
    @AppStorage(UserDefaults.KeyNames.sortFavoriteFactsAscending) var sortFavoriteFactsAscending: Bool = false

    // Whether the "delete this favorite fact" alert should be/is being displayed.
    @Published var showingDeleteFavoriteFact: Bool = false

    // Whether the "delete all favorite facts" alert should be/is being displayed.
    @Published var showingDeleteAllFavoriteFacts: Bool = false

    // The favorite fact to be deleted.
    @Published var favoriteFactToDelete: String? = nil

    // MARK: - Initialization

    init(favoriteFactsDatabase: FavoriteFactsDatabase) {
        self.favoriteFactsDatabase = favoriteFactsDatabase
    }

    // MARK: - Randomizer Timer - Setup

    // This method sets up the randomizer timer.
    func setupRandomizerTimer(block: @escaping (() -> Void)) {
        // 1. Start the randomizerTimer without repeat, since the timer's interval increases as randomizerIterations increases and the time interval of running Timers can't be changed directly.
        let randomizerTimeInterval = TimeInterval(randomizerIterations) / TimeInterval(maxRandomizerIterations * 4)
        randomizerTimer = Timer.scheduledTimer(withTimeInterval: randomizerTimeInterval, repeats: false, block: { [self] timer in
            // 2. Play a click sound if enabled.
            if favoriteFactsRandomizerClick {
                playRandomizerClick()
            }
            // 3. If randomizerIterations equals maxRandomizerIterations, stop the timer and reset the count.
            if randomizerIterations == maxRandomizerIterations {
                timer.invalidate()
                randomizerTimer = nil
                randomizerIterations = 0
            } else {
                // 4. Otherwise, increase the count and restart the timer.
                randomizerIterations += 1
                timer.invalidate()
                setupRandomizerTimer {
                    block()
                }
            }
            block()
        })
    }

    // MARK: - Randomizer Timer - Stop

    // This method stops the randomizer timer and sets it to nil.
    func stopRandomizerTimer() {
        randomizerTimer?.invalidate()
        randomizerTimer = nil
        randomizerIterations = 0
    }

    // MARK: - Randomizer Click

    func playRandomizerClick() {
        // 1. Make sure the audio file is present in the app bundle.
        let filename = "click"
        let fileExtension = "wav"
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            fatalError("Failed to find \(filename).\(fileExtension) in bundle")
        }
        // 2. Try to load the file into the player and play it.
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.stop()
            audioPlayer?.play()
        } catch {
            fatalError("Error playing audio file click.wav: \(error.localizedDescription)")
        }
    }

    // MARK: - Favorite Facts List - Color Matching Terms

    // Colors the matching text of favorite and returns the resulting AttributedString.
    func favoriteFactWithColoredMatchingTerms(_ favorite: String) -> AttributedString {
        // 1. Convert the favorite fact String to an AttributedString. As AttributedString is a data type, it's declared in the Foundation framework instead of the SwiftUI framework, even though its cross-platform design makes it shine with SwiftUI. Unlike with NSAttributedString, you can simply initialize it with a String argument without having to use an argument label.
        var attributedString = AttributedString(favorite)
        // 2. Check to see if the fact text contains the entered search text, case insensitive. If so, change the color of the matching part.
        if let range = attributedString.range(of: searchText, options: .caseInsensitive) {
            attributedString[range].backgroundColor = .accentColor.opacity(0.5)
        }
        // 3. Return the attributed string.
        return attributedString
    }

    // MARK: - Favorite Facts List - Copy Fact

    // Copies favorite to the device's clipboard using the platform-specific copy implementation.
    func copyFact(_ favorite: String) {
#if os(macOS)
        NSPasteboard.general.declareTypes([.string], owner: self)
        NSPasteboard.general.setString(favorite, forType: .string)
#else
        UIPasteboard.general.string = favorite
#endif
    }

    // MARK: - Favorite Facts List - Clear Search Text

    func clearSearchText() {
        searchText.removeAll()
    }

}
