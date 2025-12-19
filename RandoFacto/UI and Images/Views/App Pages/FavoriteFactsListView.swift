//
//  FavoriteFactsListView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct FavoriteFactsListView: View {
    
    // MARK: - Properties - Objects
    
    @EnvironmentObject var windowStateManager: WindowStateManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    @EnvironmentObject var favoriteFactsDisplayManager: FavoriteFactsDisplayManager
    
    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if windowStateManager.isLoading {
                loadingDisplay
            } else {
                VStack {
                    if favoriteFactsDatabase.favoriteFacts.isEmpty {
                       favoriteFactsEmptyDisplay
                    } else if favoriteFactsDisplayManager.searchResults.isEmpty {
                        noMatchesDisplay
                    } else {
                        favoriteFactsList
                    }
                }
                .animation(.default, value: favoriteFactsDisplayManager.sortedFavoriteFacts)
                // The searchable(text:placement:prompt:) modifier adds a search box with the given search text String binding, placement, and placeholder text prompt. The list contains everything in the FavoriteFactListDisplayManager's sortedFavoriteFacts array, which returns all favorite facts if the search box is empty or only favorite facts matching search terms if the search box contains text. The sortedFavoriteFacts array is a computed property whose value depends on the search text.
                .searchable(text: $favoriteFactsDisplayManager.searchText, placement: .toolbar, prompt: "Search Favorite Facts")
                // Toolbar
                // The search box is placed in the toolbar by the modifier above.
                .toolbar {
                    toolbarContent
                }
            }
        }
        .navigationTitle("Favorite Facts List")
        .onDisappear {
            favoriteFactsDisplayManager.clearSearchText()
        }
    }
    
    // MARK: - Loading Display
    
    @ViewBuilder
    var loadingDisplay: some View {
        LoadingIndicator(message: "Loading favorite facts…")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .padding()
    }
    
    // MARK: - Favorite Facts Empty Display
    
    @ViewBuilder
    var favoriteFactsEmptyDisplay: some View {
        VStack {
            Text("No favorite facts")
                .font(.largeTitle)
            // In SwiftUI, you don't need to use attributed strings to embed SF Symbols in text--you can simply use an Image view as you would any other value in string interpolation!
            Text("Save facts to view offline by pressing the \(Image(systemName: "star")) button while viewing a fact.")
                .font(.callout)
        }
        .foregroundStyle(.secondary)
        .padding()
    }
    
    // MARK: - No Matches Display
    
    @ViewBuilder
    var noMatchesDisplay: some View {
        VStack {
            Text("No favorite facts containing \"\(favoriteFactsDisplayManager.searchText)\"")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Please check your search terms.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
    
    // MARK: - Favorite Facts List
    
    @ViewBuilder
    var favoriteFactsList: some View {
        List {
            Section {
                header
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            Section {
                ForEach(favoriteFactsDisplayManager.sortedFavoriteFacts, id: \.self) {
                    favorite in
                    HStack {
                        Button {
                            windowStateManager.displayFavoriteFact(favorite)
                        } label: {
                            Image(systemName: "star.fill")
                                .symbolRenderingMode(.multicolor)
                            Text(favoriteFactsDisplayManager.favoriteFactWithColoredMatchingTerms(favorite))
                                .font(.system(size: CGFloat(windowStateManager.factTextSize)))
                                .multilineTextAlignment(.leading)
                                .tint(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical)
                        }
                        Divider()
                        SpeakButton(for: favorite)
                            .labelStyle(.topIconBottomTitle)
                            .imageScale(.large)
                            .padding(.horizontal)
#if os(iOS)
                            .hoverEffect(.highlight)
#endif
                    }
                    .buttonStyle(.borderless)
                    .contextMenu {
                        Button {
                            favoriteFactsDisplayManager.copyFact(favorite)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Divider()
                        unfavoriteAction(for: favorite, inMenu: true)
                    }
                    .swipeActions {
                        unfavoriteAction(for: favorite)
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    var header: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                Text("\(favoriteFactsDisplayManager.searchText.isEmpty ? "Favorite facts" : "Search results"): \(favoriteFactsDisplayManager.sortedFavoriteFacts.count)")
                    .multilineTextAlignment(.center)
                    .font(.title)
                Text("Select a favorite fact to display it.")
                    .multilineTextAlignment(.center)
                    .padding(1)
                    .font(.callout)
            }
            Spacer()
        }
    }
    
    // MARK: - Unfavorite Action
    
    @ViewBuilder
    func unfavoriteAction(for favorite: String, inMenu: Bool = false) -> some View {
        Button(role: .destructive) {
            favoriteFactsDisplayManager.favoriteFactToDelete = favorite
            favoriteFactsDisplayManager.showingDeleteFavoriteFact = true
        } label: {
            Label(inMenu ? "Unfavorite…" : "Unfavorite", systemImage: "star.slash")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            OptionsMenu(title: .menu) {
                Picker(selection: $favoriteFactsDisplayManager.sortFavoriteFactsAscending) {
                    Text("Ascending (A-Z)").tag(true)
                    Text("Descending (Z-A)").tag(false)
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .pickerStyle(.menu)
                Divider()
                UnfavoriteAllButton()
                    .environmentObject(favoriteFactsDatabase)
            }
        }
    }
    
}

// MARK: - Preview

#Preview("Loading") {
    FavoriteFactsListView()
        #if DEBUG
        .withPreviewData {
            windowStateManager, _, _, _, _, _, _, _ in
            windowStateManager.factText = loadingString
        }
    #endif
    #if os(macOS)
        .frame(width: 800, height: 600)
    #endif
}

#Preview("Loaded") {
    FavoriteFactsListView()
        #if DEBUG
        .withPreviewData {
            windowStateManager, _, _, _, _, _, _, _ in
            windowStateManager.factText = sampleFact
        }
    #endif
    #if os(macOS)
        .frame(width: 800, height: 600)
    #endif
}
