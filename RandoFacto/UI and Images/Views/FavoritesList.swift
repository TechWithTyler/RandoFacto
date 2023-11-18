//
//  FavoritesList.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct FavoritesList: View {

	@ObservedObject var viewModel: RandoFactoViewModel

	@State private var searchText = String()

	var searchResults: [String] {
		let content = viewModel.favoriteFacts
		let factText = content.map { $0.text }
		if searchText.isEmpty {
			return factText
		} else {
			return factText.filter { $0.contains(searchText) }
		}
	}

	var body: some View {
		VStack {
			if searchResults.isEmpty {
				VStack {
					Text("No Favorites")
						.font(.largeTitle)
					Text("Save facts to view offline by pressing the star button.")
						.font(.callout)
				}
				.foregroundColor(.secondary)
				.padding()
				} else {
					Text("Favorite facts: \(searchResults.count)")
						.multilineTextAlignment(.center)
						.padding(10)
						.font(.title)
					Text("Select a favorite fact to display it.")
						.multilineTextAlignment(.center)
						.padding(10)
						.font(.callout)
					List {
						ForEach(searchResults.sorted(by: >), id: \.self) {
							favorite in
							Button {
								DispatchQueue.main.async { [self] in
									viewModel.factText = favorite
									viewModel.selectedPage = .randomFact
								}
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
		.searchable(text: $searchText, placement: .toolbar, prompt: "Search Favorite Facts")
		// Toolbar
		.toolbar {
				ToolbarItem(placement: .automatic) {
                    UnfavoriteAllButton(viewModel: viewModel)
				}
		}
		.navigationTitle("Favorite Facts List")
		.frame(minWidth: 400, minHeight: 300)
	}
    
    func unfavoriteAction(for favorite: String) -> some View {
        Button(role: .destructive) {
            viewModel.deleteFromFavorites(factText: favorite)
        } label: {
            Label("Unfavorite", image: "star.slash")
        }
    }

}

#Preview {
	FavoritesList(viewModel: RandoFactoViewModel())
}
