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

	@ObservedObject var viewModel: RandoFactoManager

	@Environment(\.horizontalSizeClass) var horizontalSizeClass

#if os(iOS)
	var haptics = UINotificationFeedbackGenerator()
#endif

	var body: some View {
		NavigationSplitView {
			List(selection: $viewModel.selectedPage) {
				NavigationLink(value: AppPage.randomFact) {
					label(for: .randomFact)
				}
				if viewModel.userLoggedIn && viewModel.userDeletionStage == nil {
					NavigationLink(value: AppPage.favoriteFacts) {
						label(for: .favoriteFacts)
							.badge(viewModel.favoriteFacts.count)
					}
                    .contextMenu {
                        UnfavoriteAllButton(viewModel: viewModel)
                    }
				}
				#if !os(macOS)
				NavigationLink(value: AppPage.settings) {
					label(for: .settings)
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
                #if !os(macOS)
				case .settings:
					SettingsView(viewModel: viewModel)
                #endif
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
		#if os(macOS)
		.dialogSeverity(.critical)
		#endif
        // Unfavorite all facts alert
        .alert("Unfavorite all facts?", isPresented: $viewModel.showingDeleteAllFavoriteFacts, actions: {
            Button("Unfavorite", role: .destructive) {
                viewModel.deleteAllFavoriteFactsForCurrentUser { error in
                    if let error = error {
                        viewModel.showError(error)
                    }
                    viewModel.showingDeleteAllFavoriteFacts = false
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.showingDeleteAllFavoriteFacts = false
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

	func label(for tab: AppPage) -> some View {
		switch tab {
			case .randomFact:
				Label("Random Fact", systemImage: "questionmark")
			case .favoriteFacts:
				Label("Favorite Facts", systemImage: "star")
            #if !os(macOS)
			case .settings:
				Label("Settings", systemImage: "gear")
            #endif
		}
	}

}

#Preview {
	ContentView(viewModel: RandoFactoManager())
}
