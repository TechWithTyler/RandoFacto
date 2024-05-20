//
//  FavoriteFactsListDisplayManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/5/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

// Handles searching and sorting of the favorite facts list.
class FavoriteFactsListDisplayManager: ObservableObject {

    // MARK: - Properties - Favorite Facts Database

    var favoriteFactsDatabase: FavoriteFactsDatabase

    // MARK: - Initialization

    init(favoriteFactsDatabase: FavoriteFactsDatabase) {
        self.favoriteFactsDatabase = favoriteFactsDatabase
    }

    // MARK: - Properties - Searching

    // The search text.
    @Published var searchText = String()

    // The favorite facts that match searchText.
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

    // MARK: - Properties - Sorting

    // The sort order of the favorite facts list (false = Z-A, true = A-Z).
    @AppStorage("sortFavoriteFactsAscending") var sortFavoriteFactsAscending: Bool = false

    // The favorite facts list, sorted in either A-Z or Z-A order.
    var sortedFavoriteFacts: [String] {
        return searchResults.sorted { a, z in
            let sortCondition = sortFavoriteFactsAscending ? a < z : z < a
            return sortCondition
        }
    }

    // MARK: - Color Matching Terms

    // Colors the matching text of favorite and returns the resulting AttributedString.
    func favoriteFactWithColoredMatchingTerms(_ favorite: String) -> AttributedString {
        // 1. Convert the favorite fact String to an AttributedString. As AttributedString is a data type, it's declared in the Foundation framework instead of the SwiftUI framework, even though its cross-platform design makes it shine with SwiftUI. Unlike with NSAttributedString, you can simply initialize it with a String argument without having to use an argument label.
        var attributedString = AttributedString(favorite)
        // 2. Check to see if the fact text contains the entered search text, case insensitive. If so, change the color of the matching part.
        if let range = attributedString.range(of: searchText, options: .caseInsensitive) {
            attributedString[range].foregroundColor = .accentColor
        }
        // 3. Return the attributed string.
        return attributedString
    }

    // MARK: - Copy Fact

    // Copies favorite to the device's clipboard using the platform-specific copy implementation.
    func copyFact(_ favorite: String) {
#if os(macOS)
                            NSPasteboard.general.declareTypes([.string], owner: self)
                            NSPasteboard.general.setString(favorite, forType: .string)
#else
                            UIPasteboard.general.string = favorite
#endif
    }

    // MARK: - Clear Search Text

    func clearSearchText() {
        searchText.removeAll()
    }

}
