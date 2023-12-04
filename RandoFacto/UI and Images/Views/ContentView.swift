//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
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
				NavigationLink(value: AppPage.randomFact) {
					label(for: .randomFact)
				}
                if viewModel.authenticationManager.userLoggedIn && viewModel.authenticationManager.userDeletionStage == nil {
					NavigationLink(value: AppPage.favoriteFacts) {
						label(for: .favoriteFacts)
                            .badge(viewModel.favoriteFactsDatabase.favoriteFacts.count)
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
				case .randomFact, nil:
					FactView(viewModel: viewModel)
				case .favoriteFacts:
					FavoriteFactsList(viewModel: viewModel)
                #if !os(macOS)
				case .settings:
					SettingsView(viewModel: viewModel)
                #endif
			}
		}
		// Error alert
        .alert(isPresented: $viewModel.errorManager.showingErrorAlert, error: viewModel.errorManager.errorToShow, actions: {
			Button {
                viewModel.errorManager.showingErrorAlert = false
                viewModel.errorManager.errorToShow = nil
			} label: {
				Text("OK")
			}
		})
		#if os(macOS)
		.dialogSeverity(.critical)
		#endif
        // Unfavorite all facts alert
        .alert("Unfavorite all facts?", isPresented: $viewModel.favoriteFactsDatabase.showingDeleteAllFavoriteFacts, actions: {
            Button("Unfavorite", role: .destructive) {
                viewModel.favoriteFactsDatabase.deleteAllFavoriteFactsForCurrentUser { error in
                    if let error = error {
                        viewModel.errorManager.showError(error)
                    }
                    viewModel.favoriteFactsDatabase.showingDeleteAllFavoriteFacts = false
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.favoriteFactsDatabase.showingDeleteAllFavoriteFacts = false
            }
        })
		// Nil selection catcher
		.onChange(of: viewModel.selectedPage) { value in
			if value == nil && horizontalSizeClass == .regular {
				viewModel.selectedPage = .randomFact
			}
		}
		// User login state change/user deletion
        .onChange(of: viewModel.authenticationManager.userDeletionStage) { value in
            if value != nil {
                viewModel.dismissFavoriteFacts()
            }
		}
        .onChange(of: viewModel.authenticationManager.userLoggedIn) { value in
            if value == false {
                viewModel.dismissFavoriteFacts()
            }
		}
		// Error sound/haptics
        .onChange(of: viewModel.errorManager.errorToShow) { value in
			if value != nil {
#if os(macOS)
				NSSound.beep()
#elseif os(iOS)
				haptics.notificationOccurred(.error)
#endif
			}
		}
	}

    @ViewBuilder
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
	ContentView(viewModel: RandoFactoViewModel())
}
