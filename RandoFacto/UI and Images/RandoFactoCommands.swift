//
//  RandoFactoCommands.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct RandoFactoCommands: Commands {

    // MARK: - Properties - Objects

    @FocusedObject var windowStateManager: WindowStateManager?

    @FocusedObject var favoriteFactsDisplayManager: FavoriteFactsDisplayManager?

    @EnvironmentObject var errorManager: ErrorManager
    
    @ObservedObject var networkConnectionManager: NetworkConnectionManager
    
    @ObservedObject var authenticationManager: AuthenticationManager
    
    @ObservedObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    // MARK: - Menu Commands
    
    @CommandsBuilder var body: some Commands {
        CommandGroup(replacing: .undoRedo) {}
        CommandGroup(replacing: .importExport) {}
        CommandGroup(replacing: .printItem) {}
        if let windowStateManager = windowStateManager, let favoriteFactsDisplayManager = favoriteFactsDisplayManager {
        CommandGroup(replacing: .textEditing) {
            SpeakButton(for: windowStateManager.factText, useShortTitle: false)
                .disabled(windowStateManager.factTextDisplayingMessage || windowStateManager.selectedPage != .randomFact)
                .environmentObject(windowStateManager)
        }
        CommandGroup(replacing: .help) {
            Button("\(appName!) Help") {
                showHelp()
            }
            .keyboardShortcut(KeyEquivalent("?"), modifiers: [.command])
            Divider()
            PrivacyPolicyButton()
        }
        CommandGroup(replacing: .textFormatting) {
            Section {
                Button("Increase Fact Text Size") {
                    windowStateManager.factTextSize += 1
                }
                .disabled(windowStateManager.factTextSize == SATextViewMaxFontSize)
                .keyboardShortcut(KeyEquivalent("+"), modifiers: .command)
                Button("Decrease Fact Text Size") {
                    windowStateManager.factTextSize -= 1
                }
                .disabled(windowStateManager.factTextSize == SATextViewMinFontSize)
                .keyboardShortcut(KeyEquivalent("-"), modifiers: .command)
            }
        }
            CommandMenu("Fact") {
                Section {
                    Button(generateRandomFactButtonTitle) {
                        windowStateManager.generateRandomFact()
                    }
                    .disabled(!networkConnectionManager.deviceIsOnline || windowStateManager.factTextDisplayingMessage)
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control]))
                    Button(getRandomFavoriteFactButtonTitle) {
                        windowStateManager.getRandomFavoriteFact()
                    }
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control, .shift]))
                    .disabled(!windowStateManager.favoriteFactsAvailable || windowStateManager.factTextDisplayingMessage)
                }
                .disabled(windowStateManager.selectedPage != .randomFact)
                Section {
                    if !windowStateManager.factTextDisplayingMessage && authenticationManager.userLoggedIn && windowStateManager.displayedFactIsSaved {
                        Button("Unfavorite Current Fact…") {
                            favoriteFactsDisplayManager.favoriteFactToDelete = windowStateManager.factText
                            favoriteFactsDisplayManager.showingDeleteFavoriteFact = true
                        }
                        .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                    } else {
                        Button("Favorite Current Fact") {
                            favoriteFactsDatabase.saveFactToFavorites(windowStateManager.factText) { [self] error in
                                if let error = error {
                                    errorManager.showError(error)
                                }
                            }
                        }
                        .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                        .disabled(windowStateManager.factTextDisplayingMessage || windowStateManager.factText == factUnavailableString || !authenticationManager.userLoggedIn)
                    }
                }
                .disabled(windowStateManager.selectedPage != .randomFact)
                if authenticationManager.userLoggedIn {
                    Section {
                        UnfavoriteAllButton()
                            .environmentObject(favoriteFactsDatabase)
                    }
                }
            }
        }
    }
    
}
