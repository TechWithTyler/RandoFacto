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

	@Environment(\.dismiss) var dismiss

	@ObservedObject var viewModel: RandoFactoViewModel

	@State private var searchText = String()

	var searchResults: [String] {
		let content = viewModel.favoriteFacts
		if searchText.isEmpty {
			return content
		} else {
			return content.filter { $0.contains(searchText) }
		}
	}

	var body: some View {
#if os(macOS)
		SAMVisualEffectViewSwiftUIRepresentable {
			content
		}
#else
		content
#endif
	}

	var content: some View {
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
							List {
								ForEach(searchResults.sorted(by: >), id: \.self) {
									favorite in
									Button {
										DispatchQueue.main.async {
											viewModel.factText = favorite
											dismiss()
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
								.searchable(text: $searchText, placement: .toolbar, prompt: "Search Favorite Facts")
							}
							.listStyle(.plain)
							.background(.clear)
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
