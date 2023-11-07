//
//  FavoritesList.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI

struct FavoritesList: View {

	@ObservedObject var viewModel: RandoFactoViewModel

	var body: some View {
		NavigationStack {
			VStack {
				if viewModel.favoriteFacts.isEmpty {
					VStack {
						Text("No Favorites")
							.font(.largeTitle)
						Text("Save facts to view offline by pressing the heart button.")
							.font(.callout)
					}
					.foregroundColor(.secondary)
					.padding()
				} else {
					VStack {
						Text("Favorite facts: \(viewModel.favoriteFacts.count)")
							.multilineTextAlignment(.center)
							.padding(10)
							.font(.title)
						Text("Select a favorite fact to display it.")
							.multilineTextAlignment(.center)
							.padding(10)
							.font(.callout)
						Form {
							List {
								ForEach(viewModel.favoriteFacts.sorted(by: >), id: \.self) {
									favorite in
									Button {
										DispatchQueue.main.async {
											viewModel.factText = favorite
											viewModel.showingFavoriteFactsList = false
										}
									} label: {
										Text(favorite)
											.lineLimit(nil)
											.multilineTextAlignment(.leading)
											.foregroundColor(.primary)
											.frame(maxWidth: .infinity, alignment: .leading)
									}
									.buttonStyle(.borderless)
									.contextMenu {
										Button {
											viewModel.deleteFromFavorites(fact: favorite)
										} label: {
											Text("Unfavorite")
										}
									}
									.swipeActions {
										Button(role: .destructive) {
											viewModel.deleteFromFavorites(fact: favorite)
										} label: {
											Text("Unfavorite")
										}
									}
								}
							}
						}
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button {
						viewModel.showingFavoriteFactsList = false
					} label: {
						Text("Done")
					}
				}
			}
		}
		.navigationTitle("Favorite Facts List")
		.frame(minWidth: 400, minHeight: 300)
	}

}

#Preview {
	FavoritesList(viewModel: RandoFactoViewModel())
}
