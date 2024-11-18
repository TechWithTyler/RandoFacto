//
//  DisplaySettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct DisplaySettingsPageView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase

    var body: some View {
        Form {
            if authenticationManager.userLoggedIn {
                Section {
                    Picker("Fact on Launch", selection: $favoriteFactsDatabase.initialFact) {
                        Text(randomFactSettingTitle).tag(0)
                        Text("Random Favorite Fact").tag(1)
                    }
                } footer: {
                    Text("This setting will reset to \"\(randomFactSettingTitle)\" when you logout or delete your account.")
                }
                Section {
                    Toggle("Favorite Fact Randomizer Effect", isOn: $favoriteFactsDatabase.favoriteFactsRandomizerEffect)
                    if favoriteFactsDatabase.favoriteFacts.count < 5 {
                        InfoText("The randomizer effect only works if you have at least 5 favorite facts (you currently have \(favoriteFactsDatabase.favoriteFacts.count)).")
                    }
                } footer: {
                    Text("Turn this on if you want \(appName!) to \"spin through\" several random favorite facts instead of simply displaying a random favorite fact.\nThis setting will reset to off when you logout or delete your account.")
                }
            }
            Section {
                TextSizeSlider(labelText: "Fact Text Size", textSize: $appStateManager.factTextSize, previewText: sampleFact)
            }
            .animation(.default, value: appStateManager.factTextSize)
        }
        .formStyle(.grouped)
    }

}

#Preview {
        DisplaySettingsPageView()
#if DEBUG
    .withPreviewData()
#endif
}
