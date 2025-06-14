//
//  RandoFactoCommands.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct RandoFactoCommands: Commands {

    // MARK: - Properties - Objects

    @ObservedObject var appStateManager: AppStateManager
    
    @ObservedObject var networkConnectionManager: NetworkConnectionManager
    
    @ObservedObject var errorManager: ErrorManager
    
    @ObservedObject var authenticationManager: AuthenticationManager
    
    @ObservedObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    // MARK: - Menu Commands
    
    @CommandsBuilder var body: some Commands {
        CommandGroup(replacing: .undoRedo) {}
        CommandGroup(replacing: .importExport) {}
        CommandGroup(replacing: .printItem) {}
        CommandGroup(replacing: .textEditing) {
            SpeakButton(for: appStateManager.factText, useShortTitle: false)
                .environmentObject(appStateManager)
                .disabled(appStateManager.factTextDisplayingMessage || appStateManager.selectedPage != .randomFact)
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
                    appStateManager.factTextSize += 1
                }
                .disabled(appStateManager.factTextSize == SATextViewMaxFontSize)
                .keyboardShortcut(KeyEquivalent("+"), modifiers: .command)
                Button("Decrease Fact Text Size") {
                    appStateManager.factTextSize -= 1
                }
                .disabled(appStateManager.factTextSize == SATextViewMinFontSize)
                .keyboardShortcut(KeyEquivalent("-"), modifiers: .command)
            }
        }
        CommandMenu("Fact") {
            Section {
                Button(generateRandomFactButtonTitle) {
                    appStateManager.generateRandomFact()
                }
                .disabled(!networkConnectionManager.deviceIsOnline || appStateManager.factTextDisplayingMessage)
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control]))
                Button(getRandomFavoriteFactButtonTitle) {
                    appStateManager.getRandomFavoriteFact()
                }
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control, .shift]))
                .disabled(!appStateManager.favoriteFactsAvailable || appStateManager.factTextDisplayingMessage)
            }
            .disabled(appStateManager.selectedPage != .randomFact)
            Section {
                if !appStateManager.factTextDisplayingMessage && authenticationManager.userLoggedIn && appStateManager.displayedFactIsSaved {
                    Button("Unfavorite Current Fact…") {
                        favoriteFactsDatabase.favoriteFactToDelete = appStateManager.factText
                        favoriteFactsDatabase.showingDeleteFavoriteFact = true
                    }
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                } else {
                    Button("Favorite Current Fact") {
                        favoriteFactsDatabase.saveFactToFavorites(appStateManager.factText)
                    }
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                    .disabled(appStateManager.factTextDisplayingMessage || appStateManager.factText == factUnavailableString || !authenticationManager.userLoggedIn)
                }
            }
            .disabled(appStateManager.selectedPage != .randomFact)
            if authenticationManager.userLoggedIn {
                Section {
                    UnfavoriteAllButton()
                        .environmentObject(favoriteFactsDatabase)
                }
            }
        }
    }
    
}
