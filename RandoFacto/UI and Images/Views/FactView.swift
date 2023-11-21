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
        TranslucentFooterVStack {
            factView
        } translucentFooterContent: {
            buttons
            Divider()
            footer
        }
        .navigationTitle("Random Fact")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // Toolbar
        .toolbar {
            toolbarContent
        }
    }

    var factView: some View {
        ScrollView {
            VStack {
                Text(viewModel.factText)
                    .font(.system(size: CGFloat(viewModel.factTextSize)))
                    .isTextSelectable(!(viewModel.notDisplayingFact || viewModel.factText == factUnavailableString))
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer(minLength: 200)
            }
        }
    }

    var footer: some View {
        VStack {
            Text("Facts provided by uselessfacts.jsph.pl.")
            Text("Favorite facts database powered by Google Firebase.")
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }

    // MARK: - Buttons

    var buttons: some View {
        ConditionalHVStack {
            if viewModel.favoriteFactsAvailable {
                Button {
                    DispatchQueue.main.async {
                        // Sets factText to a random fact from the favorite facts list.
                        viewModel.factText = viewModel.getRandomFavoriteFact()
                    }
                } label: {
                    Text(getRandomFavoriteFactButtonTitle)
                }
                .disabled(viewModel.userDeletionStage != nil)
                #if os(iOS)
                .padding()
                #endif
            }
            if viewModel.online {
                Button {
                    viewModel.generateRandomFact()
                } label: {
                    Text(generateRandomFactButtonTitle)
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
			if viewModel.factText != factUnavailableString && viewModel.userLoggedIn {
                ToolbarItem(placement: .automatic) {
                    Button {
                        DispatchQueue.main.async {
                            if viewModel.displayedFactIsSaved {
                                viewModel.deleteFromFavorites(factText: viewModel.factText)
                            } else {
                                viewModel.saveToFavorites(factText: viewModel.factText)
                            }
                        }
                    } label: {
                        if viewModel.displayedFactIsSaved {
                            Image(systemName: "star.fill")
                                .symbolRenderingMode(.multicolor)
                                .accessibilityLabel("Unfavorite")
                        } else {
                            Image(systemName: "star")
                                .accessibilityLabel("Favorite")
                        }
                    }
                    .help(viewModel.displayedFactIsSaved ? "Unfavorite" : "Favorite")
                    .disabled(viewModel.factText == factUnavailableString || viewModel.userDeletionStage != nil)
                }
			}
		}
	}

}

#Preview {
	ContentView(viewModel: RandoFactoViewModel())
}
