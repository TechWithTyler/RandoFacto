//
//  FactView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct FactView: View {

	// MARK: - Properties - Objects

	@ObservedObject var viewModel: RandoFactoViewModel

	// MARK: - View

	var body: some View {
		VStack {
			factView
			Spacer()
			buttons
			Divider()
			footer
		}
		.padding()
		.navigationTitle("Random Fact")
		.navigationBarTitleDisplayMode(.inline)
		// Toolbar
		.toolbar {
			toolbarContent
		}
	}

	var factView: some View {
		ScrollView {
			Text(viewModel.factText)
				.font(.largeTitle)
				.isTextSelectable(!(viewModel.notDisplayingFact || viewModel.factText == viewModel.factUnavailableString))
				.multilineTextAlignment(.center)
		}
	}

	var footer: some View {
		VStack {
			Text("Facts provided by [uselessfacts.jsph.pl](https://uselessfacts.jsph.pl).")
			Text("Favorite facts database powered by Google Firebase.")
		}
		.font(.footnote)
		.foregroundColor(.secondary)
	}

	// MARK: - Buttons

	var buttons: some View {
		ConditionalHVStack {
			if viewModel.userLoggedIn {
				if !(viewModel.favoriteFacts.isEmpty) {
					Button {
						DispatchQueue.main.async {
							// Sets factText to a random fact from the favorite facts list.
							viewModel.factText = viewModel.getRandomFavoriteFact()
						}
					} label: {
						Text("Get Random Favorite Fact")
					}
#if os(iOS)
					.padding()
#endif
				}
			}
			if viewModel.online {
				Button {
					viewModel.generateRandomFact()
				} label: {
					Text("Generate Random Fact")
				}
#if os(iOS)
				.padding()
#endif
			}
		}
		.disabled(viewModel.notDisplayingFact)
	}

	// MARK: - Toolbar

	@ToolbarContentBuilder
	var toolbarContent: some ToolbarContent {
		let displayingLoadingMessage = viewModel.factText.last == "…" || viewModel.factText.isEmpty
		if displayingLoadingMessage {
			ToolbarItem(placement: .automatic) {
				LoadingIndicator()
			}
		} else {
			if viewModel.factText != viewModel.factUnavailableString && viewModel.userLoggedIn {
				ToolbarItem(placement: .automatic) {
					if viewModel.favoriteFacts.contains(viewModel.factText) {
						Button {
							DispatchQueue.main.async {
								viewModel.deleteFromFavorites(fact: viewModel.factText)
							}
						} label: {
							Image(systemName: "heart.fill")
								.symbolRenderingMode(.multicolor)
								.accessibilityLabel("Unfavorite")
						}.padding()
							.help("Unfavorite")
							.disabled(viewModel.notDisplayingFact || viewModel.factText == viewModel.factUnavailableString)
					} else {
						Button {
							DispatchQueue.main.async {
								viewModel.saveToFavorites(fact: viewModel.factText)
							}
						} label: {
							Image(systemName: "heart")
								.accessibilityLabel("Favorite")
						}.padding()
							.help("Favorite")
							.disabled(viewModel.notDisplayingFact || viewModel.factText == viewModel.factUnavailableString)
					}
				}
			}
		}
	}

}

#Preview {
	ContentView(viewModel: RandoFactoViewModel())
}