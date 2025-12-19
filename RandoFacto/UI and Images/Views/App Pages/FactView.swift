//
//  FactView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct FactView: View {

    // MARK: - Properties - Objects

    @EnvironmentObject var windowStateManager: WindowStateManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase

    @EnvironmentObject var favoriteFactsDisplayManager: FavoriteFactsDisplayManager

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
        .onChange(of: favoriteFactsDisplayManager.randomizerIterations) { oldValue, newValue in
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
        let canSelectFactText = !(windowStateManager.factTextDisplayingMessage || windowStateManager.factText == factUnavailableString || favoriteFactsDisplayManager.randomizerRunning)
        ScrollableText(windowStateManager.factText)
            .multilineTextAlignment(.center)
            .font(.system(size: CGFloat(windowStateManager.factTextSize)))
            .animation(.default, value: windowStateManager.factTextSize)
            .isTextSelectable(canSelectFactText)
            .blur(radius: favoriteFactsDisplayManager.randomizerRunning ? favoriteFactsDisplayManager.randomizerBlurRadius : 0)
            .accessibilityHidden(favoriteFactsDisplayManager.randomizerRunning)
            .scrollDisabled(favoriteFactsDisplayManager.randomizerRunning)
    }

    // MARK: - Fact Text Size Buttons

    #if !os(macOS)
    @ViewBuilder
    var factTextSizeButtons: some View {
        VStack {
            Text("Fact Text Size")
            Text("\(windowStateManager.factTextSizeAsInt)pt")
            HStack(spacing: 0) {
                Button {
                    windowStateManager.factTextSize -= 1
                } label: {
                    Label("Decrease Fact Text Size", systemImage: "textformat.size.smaller")
                        .frame(width: 105, height: 20)
                }
                .hoverEffect(.highlight)
                .disabled(windowStateManager.factTextSize == SATextViewMinFontSize)
                Button {
                    windowStateManager.factTextSize += 1
                } label: {
                    Label("Increase Fact Text Size", systemImage: "textformat.size.larger")
                        .frame(width: 105, height: 20)
                }
                .hoverEffect(.highlight)
                .disabled(windowStateManager.factTextSize == SATextViewMaxFontSize)
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
            if windowStateManager.favoriteFactsAvailable {
                Button {
                    windowStateManager.getRandomFavoriteFact()
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
                    windowStateManager.generateRandomFact()
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
        .disabled(windowStateManager.factTextDisplayingMessage)
    }

    // MARK: - Footer

    @ViewBuilder
    var creditsText: some View {
        VStack {
            // To include a clickable link in a string, use the format [text](URL), where text is the text to be displayed and URL is the URL the link goes to. String interpolation can't be used in the URL part of a string link.
            Text("Facts provided by [\(windowStateManager.factGenerator.randomFactsAPIName)](https://uselessfacts.jsph.pl).")
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
        let shouldShowLoadingIndicator = windowStateManager.factText.last == "…" || windowStateManager.factText.isEmpty || favoriteFactsDisplayManager.randomizerRunning
        if shouldShowLoadingIndicator {
            ToolbarItem(placement: .automatic) {
                LoadingIndicator()
            }
        } else {
            if !windowStateManager.factTextDisplayingMessage && windowStateManager.factText != factUnavailableString {
                ToolbarItem(placement: .automatic) {
                    SpeakButton(for: windowStateManager.factText)
                        .help(windowStateManager.factBeingSpoken.isEmpty ? "Speak fact" : "Stop speaking")
                }
                if authenticationManager.userLoggedIn {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            windowStateManager.toggleFavoriteFact()
                        } label: {
                            Label(windowStateManager.displayedFactIsSaved ? "Unfavorite" : "Favorite", systemImage: windowStateManager.displayedFactIsSaved ? "star.fill" : "star")
                                .symbolRenderingMode(windowStateManager.displayedFactIsSaved ? .multicolor : .monochrome)
                                .animatedSymbolReplacement()
                        }
                        .help(windowStateManager.displayedFactIsSaved ? "Unfavorite This Fact" : "Favorite This Fact")
                        .disabled(windowStateManager.factText == factUnavailableString || authenticationManager.isDeletingAccount)
                    }
                }
            }
        }
    }

}

// MARK: - Preview

#Preview("Loading") {
    FactView()
        #if DEBUG
        .withPreviewData { windowStateManager, _, _, _, _, _, _, _ in
            windowStateManager.factText = loadingString
        }
    #endif
}

#Preview("Loaded") {
    FactView()
        #if DEBUG
        .withPreviewData { windowStateManager, _, _, _, _, _, _, _ in
            windowStateManager.factText = sampleFact
        }
    #endif
}

#Preview("Generating") {
    FactView()
        #if DEBUG
        .withPreviewData { windowStateManager, _, _, _, _, _, _, _ in
            windowStateManager.factText = generatingRandomFactString
        }
    #endif
}
