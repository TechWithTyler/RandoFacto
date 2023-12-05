//
//  FavoriteFactSearchManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/5/23.
//

import SwiftUI

struct FavoriteFactSearchManager {
    
    // MARK: - Properties - Favorite Facts List
    
    var favoriteFacts: [FavoriteFact] = []
    
    // MARK: - Properties - Searching
    
    // The FavoriteFactsList search text.
    var searchText = String()
    
    // The favorite facts that match searchText.
    var searchResults: [String] {
        // 1. Define the content being searched.
        let content = favoriteFacts
        // 2. Get the text from each FavoriteFact object.
        let facts = content.map { $0.text }
        // 3. If searchText is empty, return all facts.
        if searchText.isEmpty {
            return facts
        } else {
            // 4. Return facts that contain all or part of the search text.
            return facts.filter { fact in
                let range = fact.range(of: searchText, options: .caseInsensitive)
                let textMatchesSearchTerm = range != nil
                return textMatchesSearchTerm
            }
        }
    }
    
    // MARK: - Properties - Sorting
    
    // The sort order of the favorite facts list.
    @AppStorage("sortFavoriteFactsAscending") var sortFavoriteFactsAscending: Bool = false
    
    // The favorite facts list, sorted in either A-Z or Z-A order.
    var sortedFavoriteFacts: [String] {
        return searchResults.sorted { a, z in
            return sortFavoriteFactsAscending ? a < z : a > z
        }
    }
    
}
