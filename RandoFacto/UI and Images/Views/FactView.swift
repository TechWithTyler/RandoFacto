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
    
    @EnvironmentObject var viewModel: RandoFactoManager
    
    @EnvironmentObject var networkManager: NetworkManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    // MARK: - View
    
    var body: some View {
        TranslucentFooterVStack {
            factView
        } translucentFooterContent: {
            buttons
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
    
    var factView: some View {
            ScrollableText(viewModel.factText)
                .font(.system(size: CGFloat(viewModel.factTextSize)))
                .isTextSelectable(!(viewModel.notDisplayingFact || viewModel.factText == factUnavailableString))
                .multilineTextAlignment(.center)
                .animation(.default, value: viewModel.factTextSize)
    }
    
    var footer: some View {
        VStack {
            // To include a clickable link in a string, use the format [text](URL), where text is the text to be displayed and URL is the URL the link goes to.
            Text("Facts provided by [uselessfacts.jsph.pl](https://uselessfacts.jsph.pl).")
            if viewModel.userLoggedIn {
                Text("Favorite facts database powered by [Firebase](https://firebase.google.com).")
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }
    
    // MARK: - Buttons
    
    var buttons: some View {
        ConditionalHVStack {
            if viewModel.favoriteFactsAvailable {
                Button {
                    viewModel.getRandomFavoriteFact()
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
                    viewModel.generateRandomFact()
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
        .disabled(viewModel.notDisplayingFact)
    }
    
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        let displayingLoadingMessage = viewModel.factText.last == "…" || viewModel.factText.isEmpty
        if displayingLoadingMessage {
            ToolbarItem(placement: .automatic) {
                LoadingIndicator()
            }
        } else {
            if viewModel.factText != factUnavailableString && viewModel.userLoggedIn {
                ToolbarItem(placement: .automatic) {
                    Button {
                        DispatchQueue.main.async {
                            if viewModel.displayedFactIsSaved {
                                viewModel.deleteFromFavorites(factText: viewModel.factText)
                            } else {
                                viewModel.saveToFavorites(factText: viewModel.factText)
                            }
                        }
                    } label: {
                        if viewModel.displayedFactIsSaved {
                            Image(systemName: "star.fill")
                                .symbolRenderingMode(.multicolor)
                                .accessibilityLabel("Unfavorite")
                        } else {
                            Image(systemName: "star")
                                .accessibilityLabel("Favorite")
                        }
                    }
                    .help(viewModel.displayedFactIsSaved ? "Unfavorite" : "Favorite")
                    .disabled(viewModel.factText == factUnavailableString || viewModel.userDeletionStage != nil)
                }
            }
        }
    }
    
}

#Preview {
    ContentView()
}
