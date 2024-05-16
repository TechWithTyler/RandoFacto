//
//  DisplaySettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct DisplaySettingsPageView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase

    // MARK: - Properties - Fact Text Size Slider Text

    var factTextSizeSliderText: String {
        return "Fact Text Size: \(appStateManager.factTextSizeAsInt)pt"
    }

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
                } footer: {
                    Text("Turn this on if you want \(appName!) to \"spin through\" several random favorite facts instead of simply displaying a random favorite fact.\nThis setting will reset to off when you logout or delete your account.")
                }
            }
            Section {
#if os(macOS)
                // Sliders show their labels by default on macOS.
                factTextSizeSlider
#else
                VStack(spacing: 0) {
                    Text(factTextSizeSliderText)
                        .padding(5)
                    factTextSizeSlider
                }
#endif
            }
            Section {
                Text(sampleFact)
                    .font(.system(size: CGFloat(appStateManager.factTextSize)))
                    .listRowBackground(Color.clear)
                    .multilineTextAlignment(.center)
            }
            .animation(.default, value: appStateManager.factTextSize)
        }
        .formStyle(.grouped)
    }

    // MARK: - Fact Text Size Slider

    @ViewBuilder
    var factTextSizeSlider: some View {
        Slider(value: $appStateManager.factTextSize, in: SATextViewFontSizeRange, step: 1) {
            Text(factTextSizeSliderText)
        } minimumValueLabel: {
            Image(systemName: "textformat.size.smaller")
                .accessibilityLabel("Smaller")
        } maximumValueLabel: {
            Image(systemName: "textformat.size.larger")
                .accessibilityLabel("Larger")
        }
        .accessibilityValue("\(appStateManager.factTextSizeAsInt)")
    }

}

#Preview {
        DisplaySettingsPageView()
#if DEBUG
    .withPreviewData()
#endif
}
