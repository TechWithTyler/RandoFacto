//
//  RandoFactoCommands.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//

import SwiftUI

struct RandoFactoCommands: Commands {
    
    @ObservedObject var viewModel: RandoFactoManager
    
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
                    viewModel.factTextSize += 1
                }
                .disabled(viewModel.factTextSize == maxFontSize)
                .keyboardShortcut(KeyEquivalent("+"), modifiers: .command)
                Button("Decrease Fact Text Size") {
                    viewModel.factTextSize -= 1
                }
                .disabled(viewModel.factTextSize == minFontSize)
                .keyboardShortcut(KeyEquivalent("-"), modifiers: .command)
            }
        }
        CommandMenu("Fact") {
            Section {
                Button(generateRandomFactButtonTitle) {
                    viewModel.generateRandomFact()
                }
                .disabled(!viewModel.online || viewModel.notDisplayingFact)
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control]))
                Button(getRandomFavoriteFactButtonTitle) {
                    viewModel.getRandomFavoriteFact()
                }
                .keyboardShortcut(KeyboardShortcut(KeyEquivalent("g"), modifiers: [.command, .control, .shift]))
                .disabled(!viewModel.favoriteFactsAvailable || viewModel.notDisplayingFact)
            }
            Section {
                if !viewModel.notDisplayingFact && viewModel.userLoggedIn && viewModel.displayedFactIsSaved {
                    Button("Delete Current Fact From Favorites") {
                        viewModel.deleteFromFavorites(factText: viewModel.factText)
                    }
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                } else {
                    Button("Save Current Fact to Favorites") {
                        viewModel.saveToFavorites(factText: viewModel.factText)
                    }
                    .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command, .shift]))
                    .disabled(viewModel.notDisplayingFact || viewModel.factText == factUnavailableString || !viewModel.userLoggedIn)
                }
            }
            if viewModel.userLoggedIn {
                Section {
                    UnfavoriteAllButton(viewModel: viewModel)
                }
            }
        }
    }
    
}
