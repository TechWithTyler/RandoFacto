//
//  FavoriteFactsSearchManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/3/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

class FavoriteFactsSearchManager {
    
    var favoriteFactsDatabase: FavoriteFactsDatabase?
    
    // The FavoriteFactsList search text.
    var searchText = String()
    
    // The sort order of the favorite facts list.
    @AppStorage("sortFavoriteFactsAscending") var sortFavoriteFactsAscending: Bool = false
    
    // The favorite facts that match searchText.
    var searchResults: [String] {
        // 1. Define the content being searched.
        guard let content = favoriteFactsDatabase?.favoriteFacts else { return [] }
        // 2. Get the text from each FavoriteFact object.
        let facts = content.map { $0.text }
        // 3. If searchText is empty, return all facts. Otherwise, continue on to filter the results based on searchText.
        if searchText.isEmpty {
            return facts
        } else {
            return facts.filter { factText in
                // 4. Construct a regular expression pattern with word boundaries and ".*" for partial matching.
                let searchTermRegex = "\\b.*" + NSRegularExpression.escapedPattern(for: searchText) + ".*\\b"
                // 5. Create an instance of NSRegularExpression with the constructed pattern and case-insensitive option
                let regex = try? NSRegularExpression(pattern: searchTermRegex, options: .caseInsensitive)
                // 6. Filter the facts array based on whether each fact's text matches the regular expression.
                if let regex = regex {
                    let range = NSRange(location: 0, length: factText.utf16.count)
                    // 7. Check if the text contains a match for the regular expression
                    return regex.firstMatch(in: factText, options: [], range: range) != nil
                } else {
                    // 8. If the text doesn't contain a match, return false to exclude this fact.
                    return false
                }
            }
        }
    }
    
    // The favorite facts list, sorted in either A-Z or Z-A order.
    var sortedFavoriteFacts: [String] {
        return searchResults.sorted { a, z in
            return sortFavoriteFactsAscending ? a < z : a > z
        }
    }
    
    init(favoriteFactsDatabase: FavoriteFactsDatabase?) {
        self.favoriteFactsDatabase = favoriteFactsDatabase
    }
    
}
