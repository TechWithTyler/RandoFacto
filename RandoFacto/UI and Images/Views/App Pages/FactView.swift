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
    
    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager
    
    @EnvironmentObject var errorManager: ErrorManager

    #if os(iOS)
    // Gives an iPhone, MacBook, or 2015-present Magic Trackpad user ultra-slick haptic taps for each favorite fact randomizer iteration (like the clicks of a spinner).
    let randomizerHaptics = UIImpactFeedbackGenerator(style: .light)
    #elseif os(macOS)
    let randomizerHaptics = NSHapticFeedbackManager.defaultPerformer
    #endif

    // MARK: - Body
    
    var body: some View {
        TranslucentFooterVStack {
            // Main section
            factTextView
        } translucentFooterContent: {
            // Footer section
            factGenerationButtons
            Divider()
            creditsText
        }
        .navigationTitle("Random Fact")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        // Toolbar
        .toolbar {
            toolbarContent
        }
        #if os(iOS) || os(macOS)
        .onChange(of: favoriteFactsDatabase.randomizerIterations) { value in
            #if os(iOS)
            // iPhone supports a wide range of intensities for its haptics.
            randomizerHaptics.impactOccurred(intensity: 0.5)
            #else
            // The Force Touch Trackpad on a MacBook or 2015-present Magic Trackpad, on the other hand, only supports 3 types of haptics. We use the generic haptic pattern here.
            randomizerHaptics.perform(.generic, performanceTime: .default)
            #endif
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
                .blur(radius: favoriteFactsDatabase.randomizerIterations > 0 ? 20 : 0)
                .accessibilityHidden(favoriteFactsDatabase.randomizerIterations > 0)
    }
    
    // MARK: - Fact Generation Buttons
    
    var factGenerationButtons: some View {
        ConditionalHVStack {
            if appStateManager.favoriteFactsAvailable {
                Button {
                    appStateManager.getRandomFavoriteFact()
                } label: {
                    Label(getRandomFavoriteFactButtonTitle, systemImage: "star")
                        .frame(width: factGenerationButtonWidth)
                }
#if os(iOS)
                .padding()
#endif
                .buttonStyle(.bordered)
                #if os(iOS)
                .hoverEffect(.highlight)
                #endif
            }
            if networkConnectionManager.deviceIsOnline {
                Button {
                    appStateManager.generateRandomFact()
                } label: {
                    Label(generateRandomFactButtonTitle, systemImage: "dice")
                        .frame(width: factGenerationButtonWidth)
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
        #if os(macOS)
        // Sometimes, while a section of code can be used on multiple platforms, you may not want to compile it for all of them. In this case, the large control size is just right for this app on macOS, but not for iOS (bordered buttons on iOS are already large by default because of its touch-first UI), so we use the large control size on macOS but leave it as is on the other platforms.
        .controlSize(.large)
        #endif
        .disabled(appStateManager.factTextDisplayingMessage)
    }
    
    // MARK: - Footer
    
    var creditsText: some View {
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
                        .disabled(appStateManager.factText == factUnavailableString || authenticationManager.isDeletingAccount)
                    }
                }
            }
        }
    }
    
}

#Preview {
    FactView()
        .withPreviewData()
}