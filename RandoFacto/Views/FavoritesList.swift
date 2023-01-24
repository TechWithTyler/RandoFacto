//
//  FavoritesList.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/23/23.
//

import SwiftUI

struct FavoritesList: View {

	var parent: ContentView

	var body: some View {
		NavigationStack {
			VStack {
				if parent.randoFactoDatabase.favorites.isEmpty {
					Text("No Favorites")
						.font(.largeTitle)
						.foregroundColor(.secondary)
				} else {
					List {
						ForEach(parent.randoFactoDatabase.favorites, id: \.self) {
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
									Text("Delete")
								}
							}
						}.onDelete(perform: delete(at:))
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						parent.showingFavoritesList = false
					} label: {
						Text("Done")
					}
				}
			}
		}
		.frame(minWidth: 300, minHeight: 300)
	}

	func delete(at indexSet: IndexSet) {
		guard let index = Array(indexSet).first else { return }
		let favorite = parent.randoFactoDatabase.favorites[index]
		parent.randoFactoDatabase.deleteFromFavorites(fact: favorite)
	}

}

struct FavoritesList_Previews: PreviewProvider {
    static var previews: some View {
		FavoritesList(parent: ContentView())
    }
}
