//
//  FavoriteFactsListView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct FavoriteFactsListView: View {
    
    // MARK: - Properties - Objects
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    @EnvironmentObject var favoriteFactsListDisplayManager: FavoriteFactsListDisplayManager
    
    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if appStateManager.isLoading {
                loadingDisplay
            } else {
                VStack {
                    if favoriteFactsDatabase.favoriteFacts.isEmpty {
                       favoriteFactsEmptyDisplay
                    } else if favoriteFactsListDisplayManager.searchResults.isEmpty {
                        noMatchesDisplay
                    } else {
                        favoriteFactsList
                    }
                }
                .animation(.default, value: favoriteFactsListDisplayManager.sortedFavoriteFacts)
                // The searchable(text:placement:prompt:) modifier adds a search box with the given search text String binding, placement, and placeholder text prompt. The list contains everything in the FavoriteFactListDisplayManager's sortedFavoriteFacts array, which returns all favorite facts if the search box is empty or only favorite facts matching search terms if the search box contains text. The sortedFavoriteFacts array is a computed property whose value depends on the search text.
                .searchable(text: $favoriteFactsListDisplayManager.searchText, placement: .toolbar, prompt: "Search Favorite Facts")
                // Toolbar
                // The search box is placed in the toolbar by the modifier above.
                .toolbar {
                    toolbarContent
                }
            }
        }
        .navigationTitle("Favorite Facts List")
        .onDisappear {
            favoriteFactsListDisplayManager.clearSearchText()
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
            Text("No Favorite Facts")
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
            Text("No Favorite Facts Containing \"\(favoriteFactsListDisplayManager.searchText)\"")
                .font(.largeTitle)
            Text("Please check your search terms.")
                .font(.callout)
        }
        .foregroundStyle(.secondary)
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
                ForEach(favoriteFactsListDisplayManager.sortedFavoriteFacts, id: \.self) {
                    favorite in
                    HStack {
                        Button {
                            appStateManager.displayFavoriteFact(favorite)
                        } label: {
                            Image(systemName: "star.fill")
                                .symbolRenderingMode(.multicolor)
                            Text(favoriteFactsListDisplayManager.favoriteFactWithColoredMatchingTerms(favorite))
                                .font(.system(size: CGFloat(appStateManager.factTextSize)))
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.primary)
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
                            favoriteFactsListDisplayManager.copyFact(favorite)
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
                Text("\(favoriteFactsListDisplayManager.searchText.isEmpty ? "Favorite facts" : "Search results"): \(favoriteFactsListDisplayManager.sortedFavoriteFacts.count)")
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
            favoriteFactsDatabase.favoriteFactToDelete = favorite
            favoriteFactsDatabase.showingDeleteFavoriteFact = true
        } label: {
            Label(inMenu ? "Unfavorite…" : "Unfavorite", systemImage: "star.slash")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            OptionsMenu(title: .menu) {
                Picker("Sort", selection: $favoriteFactsListDisplayManager.sortFavoriteFactsAscending) {
                    Text("Ascending (A-Z)").tag(true)
                    Text("Descending (Z-A)").tag(false)
                }
                .pickerStyle(.menu)
                Divider()
                UnfavoriteAllButton()
                    .environmentObject(favoriteFactsDatabase)
            }
        }
    }
    
}

#Preview("Loading") {
    FavoriteFactsListView()
        #if DEBUG
        .withPreviewData {
            appStateManager, _, _, _, _, _ in
            appStateManager.factText = loadingString
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
            appStateManager, _, _, _, _, _ in
            appStateManager.factText = sampleFact
        }
    #endif
    #if os(macOS)
        .frame(width: 800, height: 600)
    #endif
}
