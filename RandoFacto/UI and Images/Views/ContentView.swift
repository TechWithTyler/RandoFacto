//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct ContentView: View {

	@ObservedObject var viewModel: RandoFactoViewModel

	@Environment(\.horizontalSizeClass) var horizontalSizeClass

#if os(iOS)
	var haptics = UINotificationFeedbackGenerator()
#endif

	var body: some View {
		NavigationSplitView {
			List(selection: $viewModel.selectedPage) {
				NavigationLink(value: Page.randomFact) {
					label(for: .randomFact)
				}
				if viewModel.userLoggedIn && viewModel.userDeletionStage == nil {
					NavigationLink(value: Page.favoriteFacts) {
						label(for: .favoriteFacts)
							.badge(viewModel.favoriteFacts.count)
					}
				}
				#if !os(macOS)
				NavigationLink(value: Page.account) {
					label(for: .account)
				}
				#endif
			}
			.navigationTitle("RandoFacto")
#if os(iOS)
			.navigationBarTitleDisplayMode(.automatic)
#endif
		} detail: {
			switch viewModel.selectedPage {
				case .randomFact:
					FactView(viewModel: viewModel)
				case .favoriteFacts:
					FavoritesList(viewModel: viewModel)
				case .account:
					SettingsView(viewModel: viewModel)
				case .none:
					EmptyView()
			}
		}
		// Error alert
		.alert(isPresented: $viewModel.showingErrorAlert, error: viewModel.errorToShow, actions: {
			Button {
				viewModel.showingErrorAlert = false
				viewModel.errorToShow = nil
			} label: {
				Text("OK")
			}
		})
		// Nil selection catcher
		.onChange(of: viewModel.selectedPage) { value in
			if value == nil && horizontalSizeClass == .regular {
				viewModel.selectedPage = .randomFact
			}
		}
		// User login state change/user deletion
		.onChange(of: viewModel.userDeletionStage) { value in
			viewModel.dismissFavoriteFacts()
		}
		.onChange(of: viewModel.userLoggedIn) { value in
			viewModel.dismissFavoriteFacts()
		}
		// Error sound/haptics
		.onChange(of: viewModel.errorToShow) { value in
			if value != nil {
#if os(macOS)
				NSSound.beep()
#elseif os(iOS)
				haptics.notificationOccurred(.error)
#endif
			}
		}
	}

	func label(for tab: Page) -> some View {
		switch tab {
			case .randomFact:
				Label("Random Fact", systemImage: "questionmark")
			case .favoriteFacts:
				Label("Favorite Facts", systemImage: "heart")
			case .account:
				Label("Settings", systemImage: "gear")

		}
	}

}

#Preview {
	ContentView(viewModel: RandoFactoViewModel())
}
