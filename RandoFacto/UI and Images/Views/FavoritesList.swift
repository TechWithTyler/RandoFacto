//
//  FavoritesList.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct FavoritesList: View {
    
    @ObservedObject var viewModel: RandoFactoManager
    
    @State private var searchText = String()
    
    var searchResults: [String] {
        let content = viewModel.favoriteFacts
        let factText = content.map { $0.text }
        if searchText.isEmpty {
            return factText
        } else {
            return factText.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack {
            if searchResults.isEmpty {
                VStack {
                    Text("No Favorites")
                        .font(.largeTitle)
                    Text("Save facts to view offline by pressing the \(Image(systemName: "star")) button.")
                        .font(.callout)
                }
                .foregroundColor(.secondary)
                .padding()
            } else {
                List {
                    Section(header:
                                HStack {
                        Spacer()
                        VStack(alignment: .center) {
                            Text("Favorite facts: \(searchResults.count)")
                                .multilineTextAlignment(.center)
                                .padding(10)
                                .font(.title)
                            Text("Select a favorite fact to display it.")
                                .multilineTextAlignment(.center)
                                .padding(10)
                                .font(.callout)
                        }
                        Spacer()
                    }) {
                        ForEach(searchResults.sorted(by: >), id: \.self) {
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
        .animation(.default, value: searchResults)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Favorite Facts")
        // Toolbar
        .toolbar {
            ToolbarItem(placement: .automatic) {
                UnfavoriteAllButton(viewModel: viewModel)
                    .help("Unfavorite All")
            }
        }
        .navigationTitle("Favorite Facts List")
        .frame(minWidth: 400, minHeight: 300)
    }
    
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
    FavoritesList(viewModel: RandoFactoManager())
}
