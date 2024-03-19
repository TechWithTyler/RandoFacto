//
//  FactView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct FactView: View {
    
    // MARK: - Properties - Objects
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    @EnvironmentObject var networkManager: NetworkManager
    
    @EnvironmentObject var errorManager: ErrorManager

    #if os(iOS)
    let randomizerHaptics = UIImpactFeedbackGenerator(style: .light)
    #endif

    // MARK: - Body
    
    var body: some View {
        TranslucentFooterVStack {
            factTextView
        } translucentFooterContent: {
            factGenerationButtons
            Divider()
            footer
        }
        .navigationTitle("Random Fact")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        // Toolbar
        .toolbar {
            toolbarContent
        }
        #if os(iOS)
        .onChange(of: favoriteFactsDatabase.randomizerIterations) { value in
            randomizerHaptics.impactOccurred(intensity: 0.5)
        }
        #endif
    }
    
    // MARK: - Fact Text View
    
    var factTextView: some View {
            ScrollableText(appStateManager.factText)
                .font(.system(size: CGFloat(appStateManager.factTextSize)))
                .isTextSelectable(!(appStateManager.factTextDisplayingMessage || appStateManager.factText == factUnavailableString))
                .multilineTextAlignment(.center)
                .animation(.default, value: appStateManager.factTextSize)
                .blur(radius: favoriteFactsDatabase.randomizerIterations > 0 ? 10 : 0)
                .accessibilityHidden(favoriteFactsDatabase.randomizerIterations > 0)
    }
    
    // MARK: - Fact Generation Buttons
    
    var factGenerationButtons: some View {
        ConditionalHVStack {
            if appStateManager.favoriteFactsAvailable {
                Button {
                    appStateManager.getRandomFavoriteFact()
                } label: {
                    Text(getRandomFavoriteFactButtonTitle)
                        .frame(width: 200)
                }
#if os(iOS)
                .padding()
#endif
                .buttonStyle(.bordered)
                #if os(iOS)
                .hoverEffect(.highlight)
                #endif
            }
            if networkManager.deviceIsOnline {
                Button {
                    appStateManager.generateRandomFact()
                } label: {
                    Text(generateRandomFactButtonTitle)
                        .frame(width: 200)
                }
#if os(iOS)
                .padding()
#endif
                .buttonStyle(.bordered)
                #if os(iOS)
                .hoverEffect(.highlight)
                #endif
            }
        }
        .disabled(appStateManager.factTextDisplayingMessage)
    }
    
    // MARK: - Footer
    
    var footer: some View {
        VStack {
            // To include a clickable link in a string, use the format [text](URL), where text is the text to be displayed and URL is the URL the link goes to.
            Text("Facts provided by [\(appStateManager.factGenerator.randomFactsAPIName)](https://\(appStateManager.factGenerator.randomFactsAPIName)).")
            if authenticationManager.userLoggedIn {
                Text("Favorite facts database powered by [Firebase](https://firebase.google.com).")
            }
        }
        .padding(.top, 1)
        .font(.footnote)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        let displayingLoadingMessage = appStateManager.factText.last == "…" || appStateManager.factText.isEmpty || favoriteFactsDatabase.randomizerIterations > 0
        if displayingLoadingMessage {
            ToolbarItem(placement: .automatic) {
                LoadingIndicator()
            }
        } else {
            if !appStateManager.factTextDisplayingMessage && appStateManager.factText != factUnavailableString {
                ToolbarItem(placement: .automatic) {
                    SpeakButton(for: appStateManager.factText)
                        .help(appStateManager.factBeingSpoken.isEmpty ? "Speak fact" : "Stop speaking")
                }
                if authenticationManager.userLoggedIn {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            DispatchQueue.main.async {
                                if appStateManager.displayedFactIsSaved {
                                    favoriteFactsDatabase.favoriteFactToDelete = appStateManager.factText
                                    favoriteFactsDatabase.showingDeleteFavoriteFact = true
                                } else {
                                    favoriteFactsDatabase.saveFactToFavorites(appStateManager.factText)
                                }
                            }
                        } label: {
                            Image(systemName: appStateManager.displayedFactIsSaved ? "star.fill" : "star")
                                .symbolRenderingMode(appStateManager.displayedFactIsSaved ? .multicolor : .monochrome)
                                .animatedSymbolReplacement()
                                .accessibilityLabel(appStateManager.displayedFactIsSaved ? "Unfavorite" : "Favorite")
                        }
                        .help(appStateManager.displayedFactIsSaved ? "Unfavorite" : "Favorite")
                        .disabled(appStateManager.factText == factUnavailableString || authenticationManager.accountDeletionStage != nil)
                    }
                }
            }
        }
    }
    
}

#Preview {
    FactView()
        .environmentObject(AppStateManager())
        .environmentObject(ErrorManager())
        .environmentObject(NetworkManager())
        .environmentObject(FavoriteFactsDatabase())
        .environmentObject(AuthenticationManager())
}
