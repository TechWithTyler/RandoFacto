//
//  UnfavoriteAllButton.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

struct UnfavoriteAllButton: View {

    // MARK: - Properties - Favorite Facts Database

    @EnvironmentObject var favoriteFactsDisplayManager: FavoriteFactsDisplayManager

    // MARK: - Body

    var body: some View {
        Button(role: .destructive) {
            favoriteFactsDisplayManager.showingDeleteAllFavoriteFacts = true
        } label: {
            Label("Unfavorite All…", systemImage: "star.slash.fill")
        }
    }

}

// MARK: - Preview

#Preview {
    UnfavoriteAllButton()
        #if DEBUG
        .withPreviewData()
    #endif
}
