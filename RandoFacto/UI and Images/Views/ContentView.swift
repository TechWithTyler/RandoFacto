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
			List(selection: $viewModel.selectedTab) {
				NavigationLink(value: Tab.randomFact) {
					label(for: .randomFact)
				}
				if viewModel.userLoggedIn && !viewModel.isDeletingUser {
					NavigationLink(value: Tab.favoriteFacts) {
						label(for: .favoriteFacts)
							.badge(viewModel.favoriteFacts.count)
					}
				}
				#if !os(macOS)
				NavigationLink(value: Tab.account) {
					label(for: .account)
				}
				#endif
			}
			.navigationTitle("RandoFacto")
#if os(iOS)
			.navigationBarTitleDisplayMode(.automatic)
#endif
		} detail: {
			switch viewModel.selectedTab {
				case .randomFact:
					FactView(viewModel: viewModel)
				case .favoriteFacts:
					FavoritesList(viewModel: viewModel)
				case .account:
					AccountView(viewModel: viewModel)
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
		.onChange(of: viewModel.selectedTab) { value in
			if value == nil && horizontalSizeClass == .regular {
				viewModel.selectedTab = .randomFact
			}
		}
		// User login state change/user deletion
		.onChange(of: viewModel.isDeletingUser) { value in
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

	func label(for tab: Tab) -> some View {
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
