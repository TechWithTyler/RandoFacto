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

    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    @EnvironmentObject var favoriteFactSearcher: FavoriteFactSearcher
    
    @EnvironmentObject var networkManager: NetworkManager
    
    @EnvironmentObject var errorManager: ErrorManager

	@Environment(\.horizontalSizeClass) var horizontalSizeClass

#if os(iOS)
	var haptics = UINotificationFeedbackGenerator()
#endif

	var body: some View {
		NavigationSplitView {
			List(selection: $appStateManager.selectedPage) {
				NavigationLink(value: AppPage.randomFact) {
					label(for: .randomFact)
				}
				if authenticationManager.userLoggedIn && authenticationManager.userDeletionStage == nil {
					NavigationLink(value: AppPage.favoriteFacts) {
						label(for: .favoriteFacts)
							.badge(favoriteFactsDatabase.favoriteFacts.count)
					}
                    .contextMenu {
                        UnfavoriteAllButton()
                            .environmentObject(favoriteFactsDatabase)
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
			switch appStateManager.selectedPage {
				case .randomFact, nil:
					FactView()
                    .environmentObject(appStateManager)
                    .environmentObject(networkManager)
                    .environmentObject(errorManager)
                    .environmentObject(favoriteFactsDatabase)
                    .environmentObject(authenticationManager)
				case .favoriteFacts:
					FavoriteFactsList()
                    .environmentObject(appStateManager)
                    .environmentObject(networkManager)
                    .environmentObject(errorManager)
                    .environmentObject(favoriteFactsDatabase)
                    .environmentObject(favoriteFactSearcher)
                #if !os(macOS)
				case .settings:
					SettingsView()
                    .environmentObject(appStateManager)
                    .environmentObject(networkManager)
                    .environmentObject(errorManager)
                    .environmentObject(authenticationManager)
                    .environmentObject(favoriteFactsDatabase)
                #endif
			}
		}
		// Error alert
        .alert(isPresented: $errorManager.showingErrorAlert, error: errorManager.errorToShow, actions: {
			Button {
				errorManager.showingErrorAlert = false
				errorManager.errorToShow = nil
			} label: {
				Text("OK")
			}
		})
		#if os(macOS)
		.dialogSeverity(.critical)
		#endif
        .alert("Unfavorite this fact?", isPresented: $favoriteFactsDatabase.showingDeleteFavoriteFact, presenting: $favoriteFactsDatabase.favoriteFactToDelete, actions: { factText in
            Button("Unfavorite", role: .destructive) {
                favoriteFactsDatabase.deleteFromFavorites(factText: factText.wrappedValue!)
            }
            Button("Cancel", role: .cancel) {
                favoriteFactsDatabase.showingDeleteFavoriteFact = false
                favoriteFactsDatabase.favoriteFactToDelete = nil
            }
            
        })
        // Unfavorite all facts alert
        .alert("Unfavorite all facts?", isPresented: $favoriteFactsDatabase.showingDeleteAllFavoriteFacts, actions: {
            Button("Unfavorite", role: .destructive) {
                favoriteFactsDatabase.deleteAllFavoriteFactsForCurrentUser { error in
                    if let error = error {
                        DispatchQueue.main.async { [self] in
                            errorManager.showError(error)
                        }
                    }
                    favoriteFactsDatabase.showingDeleteAllFavoriteFacts = false
                }
            }
            Button("Cancel", role: .cancel) {
                favoriteFactsDatabase.showingDeleteAllFavoriteFacts = false
            }
        })
		// Nil selection catcher
		.onChange(of: appStateManager.selectedPage) { value in
			if value == nil && horizontalSizeClass == .regular {
				appStateManager.selectedPage = .randomFact
			}
		}
		// User login state change/user deletion
		.onChange(of: authenticationManager.userDeletionStage) { value in
            if value != nil {
                appStateManager.dismissFavoriteFacts()
            }
		}
		.onChange(of: authenticationManager.userLoggedIn) { value in
            if value == false {
                appStateManager.dismissFavoriteFacts()
            }
		}
		// Error sound/haptics
		.onChange(of: errorManager.errorToShow) { value in
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
	ContentView()
}
