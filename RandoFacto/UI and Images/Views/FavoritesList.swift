//
//  FavoritesList.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI

struct FavoritesList: View {

	var parent: ContentView

	var body: some View {
		NavigationStack {
			VStack {
				if parent.randoFactoDatabase.favoriteFacts.isEmpty {
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
						Text("Favorite facts: \(parent.randoFactoDatabase.favoriteFacts.count)")
							.multilineTextAlignment(.center)
							.padding(10)
							.font(.title)
						Text("Select a favorite fact to display it.")
							.multilineTextAlignment(.center)
							.padding(10)
							.font(.callout)
						List {
							ForEach(parent.randoFactoDatabase.favoriteFacts, id: \.self) {
								favorite in
								Button {
									parent.factText = favorite
									parent.showingFavoritesList = false
								} label: {
									Text(favorite)
										.lineLimit(nil)
										.multilineTextAlignment(.leading)
										.foregroundColor(.primary)
								}
								.buttonStyle(.borderless)
								.contextMenu {
									Button {
										parent.randoFactoDatabase.deleteFromFavorites(fact: favorite)
									} label: {
										Text("Unfavorite")
									}
								}
							}.onDelete(perform: delete(at:))
						}
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button {
						parent.showingFavoritesList = false
					} label: {
						Text("Done")
					}
				}
			}
		}
		.navigationTitle("Favorite Facts List")
		.frame(minWidth: 300, minHeight: 300)
	}

	func delete(at indexSet: IndexSet) {
		guard let index = Array(indexSet).first else { return }
		let favorite = parent.randoFactoDatabase.favoriteFacts[index]
		parent.randoFactoDatabase.deleteFromFavorites(fact: favorite)
	}

}

#Preview {
	FavoritesList(parent: ContentView())
}
