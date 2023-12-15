//
//  UnfavoriteAllButton.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct UnfavoriteAllButton: View {
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    var body: some View {
        Button(role: .destructive) {
            favoriteFactsDatabase.showingDeleteAllFavoriteFacts = true
        } label: {
            Label("Unfavorite All…", systemImage: "star.slash.fill")
        }
    }

}

#Preview {
    UnfavoriteAllButton()
        .environmentObject(FavoriteFactsDatabase())
}
