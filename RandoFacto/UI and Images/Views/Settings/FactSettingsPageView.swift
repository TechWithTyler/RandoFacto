//
//  FactSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct FactSettingsPageView: View {

    // MARK: - Properties - Objects

    @EnvironmentObject var windowStateManager: WindowStateManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase

    @EnvironmentObject var favoriteFactsDisplayManager: FavoriteFactsDisplayManager

    // MARK: - Properties - Booleans

    @AppStorage(UserDefaults.KeyNames.favoriteFactsRandomizerEffect) var favoriteFactsRandomizerEffect: Bool = false

    @AppStorage(UserDefaults.KeyNames.favoriteFactsRandomizerClick) var favoriteFactsRandomizerClick: Bool = true

    @AppStorage(UserDefaults.KeyNames.skipFavoritesOnFactGeneration) var skipFavoritesOnFactGeneration: Bool = false

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                TextSizeSlider(labelText: "Text Size", textSize: $windowStateManager.factTextSize, previewText: sampleFact)
            }
            .animation(.default, value: windowStateManager.factTextSize)
            if authenticationManager.userLoggedIn {
                Section {
                    Picker("Initial Display", selection: $favoriteFactsDatabase.initialFact) {
                        Text(generateRandomFactButtonTitle).tag(0)
                        Text(getRandomFavoriteFactButtonTitle).tag(1)
                        Text("Show Favorite Facts List").tag(2)
                    }
                } footer: {
                    Text("This setting will reset to \"\(generateRandomFactButtonTitle)\" when you logout or delete your account.")
                }
                Section {
                    Toggle("Skip Favorites On Fact Generation", isOn: $skipFavoritesOnFactGeneration)
                } footer: {
                    Text("Turn this on if you want \(appName!) to skip your favorite facts when generating random facts.\nThis setting will reset to off when you logout or delete your account.\nNote: If this setting is on, fact generation may take longer than usual.")
                }
                Section {
                    Toggle("Favorite Fact Randomizer Effect", isOn: $favoriteFactsRandomizerEffect)
                    if favoriteFactsRandomizerEffect {
                        Toggle("Click Sound", isOn: $favoriteFactsRandomizerClick)
                            .onChange(of: favoriteFactsRandomizerClick) { oldValue, newValue in
                                if newValue {
                                    favoriteFactsDisplayManager.playRandomizerClick()
                                }
                            }
                    }
                    if favoriteFactsDatabase.favoriteFacts.count < 5 {
                        InfoText("The randomizer effect only works if you have at least 5 favorite facts (you currently have \(favoriteFactsDatabase.favoriteFacts.count)).")
                    }
                } footer: {
                    Text("Turn this on if you want \(appName!) to \"spin through\" several random favorite facts instead of simply displaying a random favorite fact.\nThis setting will reset to off when you logout or delete your account.")
                }
            }
        }
        .formStyle(.grouped)
    }

}

// MARK: - Preview

#Preview {
        FactSettingsPageView()
#if DEBUG
    .withPreviewData()
#endif
}
