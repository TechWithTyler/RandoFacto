//
//  RandoFactoCommands.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//

import SwiftUI

struct RandoFactoCommands: Commands {
    
    @ObservedObject var appStateManager: AppStateManager
    
    @ObservedObject var networkManager: NetworkManager
    
    @ObservedObject var errorManager: ErrorManager
    
    @ObservedObject var authenticationManager: AuthenticationManager
    
    @ObservedObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    // MARK: - Menu Commands
    
    @CommandsBuilder var body: some Commands {
        CommandGroup(replacing: .undoRedo) {}
        CommandGroup(replacing: .importExport) {}
        CommandGroup(replacing: .printItem) {}
        CommandGroup(replacing: .textEditing) {}
        CommandGroup(replacing: .help) {
            Button("RandoFacto Help") {
                showHelp()
            }
            .keyboardShortcut(KeyEquivalent("?"), modifiers: [.command])
        }
        CommandGroup(replacing: .textFormatting) {
            Section {
                Button("Increase Fact Text Size") {
                    appStateManager.factTextSize += 1
                }
                .disabled(appStateManager.factTextSize == maxFontSize)
                .keyboardShortcut(KeyEquivalent("+"), modifiers: .command)
                Button("Decrease Fact Text Size") {
                    appStateManager.factTextSize -= 1
                }
                .disabled(appStateManager.factTextSize == minFontSize)
                .keyboardShortcut(KeyEquivalent("-"), modifiers: .command)
            }
        }
        CommandMenu("Fact") {
            Section {
                Button(generateRandomFactButtonTitle) {
                    appStateManager.generateRandomFact()
                }
                .disabled(!networkManager.online || appStateManager.notDisplayingFact)
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control]))
                Button(getRandomFavoriteFactButtonTitle) {
                    appStateManager.getRandomFavoriteFact()
                }
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control, .shift]))
                .disabled(!appStateManager.favoriteFactsAvailable || appStateManager.notDisplayingFact)
            }
            Section {
                if !appStateManager.notDisplayingFact && authenticationManager.userLoggedIn && appStateManager.displayedFactIsSaved {
                    Button("Delete Current Fact From Favorites") {
                        favoriteFactsDatabase.deleteFromFavorites(factText: appStateManager.factText)
                    }
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                } else {
                    Button("Save Current Fact to Favorites") {
                        favoriteFactsDatabase.saveToFavorites(factText: appStateManager.factText)
                    }
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                    .disabled(appStateManager.notDisplayingFact || appStateManager.factText == factUnavailableString || !authenticationManager.userLoggedIn)
                }
            }
            if authenticationManager.userLoggedIn {
                Section {
                    UnfavoriteAllButton()
                        .environmentObject(favoriteFactsDatabase)
                }
            }
        }
    }
    
}
