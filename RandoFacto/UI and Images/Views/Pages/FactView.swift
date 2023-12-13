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
    }
    
    // MARK: - Fact Text View
    
    var factTextView: some View {
            ScrollableText(appStateManager.factText)
                .font(.system(size: CGFloat(appStateManager.factTextSize)))
                .isTextSelectable(!(appStateManager.notDisplayingFact || appStateManager.factText == factUnavailableString))
                .multilineTextAlignment(.center)
                .animation(.default, value: appStateManager.factTextSize)
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
            if networkManager.online {
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
        .disabled(appStateManager.notDisplayingFact)
    }
    
    // MARK: - Footer
    
    var footer: some View {
        VStack {
            // To include a clickable link in a string, use the format [text](URL), where text is the text to be displayed and URL is the URL the link goes to.
            Text("Facts provided by [uselessfacts.jsph.pl](https://uselessfacts.jsph.pl).")
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
        let displayingLoadingMessage = appStateManager.factText.last == "…" || appStateManager.factText.isEmpty
        if displayingLoadingMessage {
            ToolbarItem(placement: .automatic) {
                LoadingIndicator()
            }
        } else {
            if appStateManager.factText != factUnavailableString && authenticationManager.userLoggedIn {
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
                        if appStateManager.displayedFactIsSaved {
                            Image(systemName: "star.fill")
                                .symbolRenderingMode(.multicolor)
                                .accessibilityLabel("Unfavorite")
                        } else {
                            Image(systemName: "star")
                                .accessibilityLabel("Favorite")
                        }
                    }
                    .help(appStateManager.displayedFactIsSaved ? "Unfavorite" : "Favorite")
                    .disabled(appStateManager.factText == factUnavailableString || authenticationManager.userDeletionStage != nil)
                }
            }
        }
    }
    
}

#Preview {
    ContentView()
}
