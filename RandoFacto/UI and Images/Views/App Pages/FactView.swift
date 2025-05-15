//
//  FactView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
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
    // Gives a MacBook, 2015-present Magic Trackpad, or iPhone user ultra-slick haptic taps for each favorite fact randomizer iteration (like the clicks of a spinner).
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
            #if !os(macOS)
            // Only show the fact text size buttons on iOS--macOS users will already have a keyboard shortcut for it.
            factTextSizeButtons
            Divider()
            #endif
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

    @ViewBuilder
    var factTextView: some View {
        let canSelectFactText = !(appStateManager.factTextDisplayingMessage || appStateManager.factText == factUnavailableString || favoriteFactsDatabase.randomizerRunning)
        ScrollableText(appStateManager.factText)
            .multilineTextAlignment(.center)
            .font(.system(size: CGFloat(appStateManager.factTextSize)))
            .animation(.default, value: appStateManager.factTextSize)
            .isTextSelectable(canSelectFactText)
            .blur(radius: favoriteFactsDatabase.randomizerRunning ? favoriteFactsDatabase.randomizerBlurRadius : 0)
            .accessibilityHidden(favoriteFactsDatabase.randomizerRunning)
            .scrollDisabled(favoriteFactsDatabase.randomizerRunning)
    }

    // MARK: - Fact Text Size Buttons

    #if !os(macOS)
    @ViewBuilder
    var factTextSizeButtons: some View {
        VStack {
            Text("Fact Text Size")
            Text("\(appStateManager.factTextSizeAsInt)pt")
            HStack(spacing: 0) {
                Button {
                    appStateManager.factTextSize -= 1
                } label: {
                    Label("Decrease Fact Text Size", systemImage: "textformat.size.smaller")
                        .frame(width: 105, height: 20)
                }
                .hoverEffect(.highlight)
                .disabled(appStateManager.factTextSize == SATextViewMinFontSize)
                Button {
                    appStateManager.factTextSize += 1
                } label: {
                    Label("Increase Fact Text Size", systemImage: "textformat.size.larger")
                        .frame(width: 105, height: 20)
                }
                .hoverEffect(.highlight)
                .disabled(appStateManager.factTextSize == SATextViewMaxFontSize)
            }
            .font(.system(size: 25))
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
        }
        .padding(10)
    }
    #endif

    // MARK: - Fact Generation Buttons

    @ViewBuilder
    var factGenerationButtons: some View {
        ConditionalHVStack {
            if appStateManager.favoriteFactsAvailable {
                Button {
                    appStateManager.getRandomFavoriteFact()
                } label: {
                    Label(getRandomFavoriteFactButtonTitle, systemImage: "star")
                        .frame(width: factGenerationButtonWidth)
                }
                .buttonStyle(.bordered)
#if os(iOS)
                .padding(2.5)
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
                .buttonStyle(.bordered)
#if os(iOS)
                .padding(2.5)
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

    @ViewBuilder
    var creditsText: some View {
        VStack {
            // To include a clickable link in a string, use the format [text](URL), where text is the text to be displayed and URL is the URL the link goes to. String interpolation can't be used in the URL part of a string link.
            Text("Facts provided by [\(appStateManager.factGenerator.randomFactsAPIName)](https://uselessfacts.jsph.pl).")
            if authenticationManager.userLoggedIn {
                Text("Favorite facts database powered by [Firebase](https://firebase.google.com).")
            }
        }
        .padding(.top, 1)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        let shouldShowLoadingIndicator = appStateManager.factText.last == "…" || appStateManager.factText.isEmpty || favoriteFactsDatabase.randomizerRunning
        if shouldShowLoadingIndicator {
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
                            Label(appStateManager.displayedFactIsSaved ? "Unfavorite" : "Favorite", systemImage: appStateManager.displayedFactIsSaved ? "star.fill" : "star")
                                .symbolRenderingMode(appStateManager.displayedFactIsSaved ? .multicolor : .monochrome)
                                .animatedSymbolReplacement()
                        }
                        .help(appStateManager.displayedFactIsSaved ? "Unfavorite This Fact" : "Favorite This Fact")
                        .disabled(appStateManager.factText == factUnavailableString || authenticationManager.isDeletingAccount)
                    }
                }
            }
        }
    }

}

#Preview("Loading") {
    FactView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            appStateManager.factText = loadingString
        }
    #endif
}

#Preview("Loaded") {
    FactView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            appStateManager.factText = sampleFact
        }
    #endif
}

#Preview("Generating") {
    FactView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            appStateManager.factText = generatingRandomFactString
        }
    #endif
}
