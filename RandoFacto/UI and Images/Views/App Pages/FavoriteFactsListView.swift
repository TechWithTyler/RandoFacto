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
                .searchable(text: $favoriteFactsListDisplayManager.searchText, placement: .toolbar, prompt: "Search Favorite Facts")
                // Toolbar
                .toolbar {
                    toolbarContent
                }
            }
        }
        .navigationTitle("Favorite Facts List")
        .onDisappear {
            favoriteFactsListDisplayManager.searchText.removeAll()
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
            Text("No Favorites")
                .font(.largeTitle)
            // In SwiftUI, you don't need to use attributed strings to embed SF Symbols in text--you can simply use an Image view as you would any other value in string interpolation!
            Text("Save facts to view offline by pressing the \(Image(systemName: "star")) button.")
                .font(.callout)
        }
        .foregroundColor(.secondary)
        .padding()
    }
    
    // MARK: - No Matches Display
    
    @ViewBuilder
    var noMatchesDisplay: some View {
        VStack {
            Text("No Favorites Containing \"\(favoriteFactsListDisplayManager.searchText)\"")
                .font(.largeTitle)
            Text("Please check your search terms.")
                .font(.callout)
        }
        .foregroundColor(.secondary)
        .padding()
    }
    
    // MARK: - Favorite Facts List
    
    @ViewBuilder
    var favoriteFactsList: some View {
        List {
            Section(header: header) {
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
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical)
                        }
                        Divider()
                        SpeakButton(for: favorite)
                            .labelStyle(.topIconBottomTitle)
                            .padding(.horizontal)
                        #if os(iOS)
                            .hoverEffect(.highlight)
                        #endif
                    }
                    .buttonStyle(.borderless)
                    .contextMenu {
                        Button {
#if os(macOS)
                            NSPasteboard.general.declareTypes([.string], owner: self)
                            NSPasteboard.general.setString(favorite, forType: .string)
#else
                            UIPasteboard.general.string = favorite
#endif
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Divider()
                        unfavoriteAction(for: favorite)
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
                    .padding(10)
                    .font(.title)
                Text("Select a favorite fact to display it.")
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .font(.callout)
            }
            Spacer()
        }
    }
    
    // MARK: - Unfavorite Action
    
    @ViewBuilder
    func unfavoriteAction(for favorite: String) -> some View {
        Button(role: .destructive) {
            favoriteFactsDatabase.favoriteFactToDelete = favorite
            favoriteFactsDatabase.showingDeleteFavoriteFact = true
        } label: {
            Label("Unfavorite…", systemImage: "star.slash")
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

#Preview {
    FavoriteFactsListView()
        #if DEBUG
        .withPreviewData()
    #endif
    #if os(macOS)
        .frame(width: 800, height: 600)
    #endif
}
