//
//  FavoriteFactsList.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct FavoriteFactsList: View {
    
    // MARK: - Properties - View Model
    
    @ObservedObject var viewModel: RandoFactoManager
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            if viewModel.favoriteFacts.isEmpty {
                // Favorite facts empty display
                VStack {
                    Text("No Favorites")
                        .font(.largeTitle)
                    Text("Save facts to view offline by pressing the \(Image(systemName: "star")) button.")
                        .font(.callout)
                }
                .foregroundColor(.secondary)
                .padding()
            } else if viewModel.favoriteFactSearchManager.searchResults.isEmpty {
                // No matches display
                VStack {
                    Text("No Matches")
                        .font(.largeTitle)
                    Text("Please check your search terms.")
                        .font(.callout)
                }
                .foregroundColor(.secondary)
                .padding()
            } else {
                // Favorite facts list
                List {
                    Section(header: header) {
                        ForEach(viewModel.favoriteFactSearchManager.sortedFavoriteFacts, id: \.self) {
                            favorite in
                            Button {
                                viewModel.displayFavoriteFact(favorite)
                            } label: {
                                Text(favorite)
                                    .lineLimit(nil)
                                    .font(.system(size: CGFloat(viewModel.factTextSize)))
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical)
                            }
                            .buttonStyle(.borderless)
                            .contextMenu {
                                unfavoriteAction(for: favorite)
                            }
                            .swipeActions {
                                unfavoriteAction(for: favorite)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: viewModel.favoriteFactSearchManager.sortedFavoriteFacts)
        .searchable(text: $viewModel.favoriteFactSearchManager.searchText, placement: .toolbar, prompt: "Search Favorite Facts")
        // Toolbar
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker("Sort", selection: $viewModel.favoriteFactSearchManager.sortFavoriteFactsAscending) {
                        Text("Sort Ascending (A-Z)").tag(true)
                        Text("Sort Descending (Z-A)").tag(false)
                    }
                    .pickerStyle(.menu)
                    Divider()
                    UnfavoriteAllButton(viewModel: viewModel)
                        .help("Unfavorite All")
                } label: {
                    OptionsMenuLabel()
                }
            }
        }
        .navigationTitle("Favorite Facts List")
        .frame(minWidth: 400, minHeight: 300)
    }
    
    // MARK: - Header
    
    var header: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                Text("Favorite facts: \(viewModel.favoriteFactSearchManager.sortedFavoriteFacts.count)")
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
            viewModel.deleteFromFavorites(factText: favorite)
        } label: {
            Label("Unfavorite", systemImage: "star.slash")
        }
    }
    
}

#Preview {
    FavoriteFactsList(viewModel: RandoFactoManager())
}
