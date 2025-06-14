//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI
import Speech

struct ContentView: View {
    
    // MARK: - Properties - Objects

    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    @EnvironmentObject var favoriteFactSearcher: FavoriteFactsListDisplayManager
    
    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    // MARK: - Properties - Horizontal Size Class

    // The horizontal size class of the view (how wide it is).
	@Environment(\.horizontalSizeClass) var horizontalSizeClass

    // MARK: - Properties - iPhone Haptics
    
#if os(iOS)
    // Gives an iPhone user ultra-slick haptic taps when an error message appears.
	var haptics = UINotificationFeedbackGenerator()
#endif
    
    // MARK: - Body

	var body: some View {
		NavigationSplitView {
			sidebarContent
            #if os(macOS)
                .navigationSplitViewColumnWidth(250)
            #endif
        } detail: {
            mainContent
        }
		// Error alert
        .alert(isPresented: $errorManager.showingErrorAlert, error: errorManager.errorToShow) {
			Button {
				errorManager.showingErrorAlert = false
				errorManager.errorToShow = nil
			} label: {
				Text("OK")
			}
		}
		#if os(macOS)
		.dialogSeverity(.critical)
		#endif
        // Unfavorite this fact alert
        .alert("Unfavorite this fact?", isPresented: $favoriteFactsDatabase.showingDeleteFavoriteFact, presenting: $favoriteFactsDatabase.favoriteFactToDelete) { factText in
            Button("Unfavorite", role: .destructive) {
                favoriteFactsDatabase.unfavoriteFact(factText.wrappedValue!)
            }
            Button("Cancel", role: .cancel) {
                favoriteFactsDatabase.showingDeleteFavoriteFact = false
                favoriteFactsDatabase.favoriteFactToDelete = nil
            }
        } message: { factText in
            if appStateManager.selectedPage == .randomFact || appStateManager.factText == factText.wrappedValue {
                Text("Make sure to re-favorite this fact BEFORE generating a new one if you change your mind!")
            } else {
                Text("This can't be undone!")
            }
        }
        // Unfavorite all facts alert
        .alert("Are you sure you REALLY want to unfavorite all facts?", isPresented: $favoriteFactsDatabase.showingDeleteAllFavoriteFacts) {
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
        } message: {
            Text("This can't be undone!")
        }
#if os(macOS)
.dialogSeverity(.critical)
#endif
        // Onboarding sheet
        .sheet(isPresented: $appStateManager.showingOnboarding) {
            OnboardingView()
        }
        .onAppear {
            if appStateManager.shouldOnboard {
                appStateManager.showingOnboarding = true
            }
        }
		// Nil selection catcher
        .onChange(of: horizontalSizeClass) { sizeClass in
            if appStateManager.selectedPage == nil && sizeClass != .compact {
                appStateManager.selectedPage = .randomFact
            }
        }
		.onChange(of: appStateManager.selectedPage) { page in
			if page == nil && horizontalSizeClass == .regular {
				appStateManager.selectedPage = .randomFact
			}
		}
		// User login state change/user deletion
		.onChange(of: authenticationManager.accountDeletionStage) { deletionStage in
            if deletionStage != nil {
                favoriteFactsDatabase.showingDeleteFavoriteFact = false
                favoriteFactsDatabase.showingDeleteAllFavoriteFacts = false
                appStateManager.dismissFavoriteFacts()
            }
		}
		.onChange(of: authenticationManager.userLoggedIn) { loggedIn in
            if !loggedIn {
                favoriteFactsDatabase.showingDeleteFavoriteFact = false
                favoriteFactsDatabase.showingDeleteAllFavoriteFacts = false
                appStateManager.dismissFavoriteFacts()
            }
		}
		// Error sound (Mac) or haptics (iPhone)
		.onChange(of: errorManager.errorToShow) { error in
			if error != nil {
#if os(macOS)
				NSSound.beep()
#elseif os(iOS)
				haptics.notificationOccurred(.error)
#endif
			}
		}
	}
    
    // MARK: - Sidebar
    
    @ViewBuilder
    var sidebarContent: some View {
        List(selection: $appStateManager.selectedPage) {
            // We can't simply iterate through the AppPage enum's cases to create the navigation links, as one of them (Favorite Facts) only appears when a condition (user logged in and not being deleted) is true.
            NavigationLink(value: AppPage.randomFact) {
                label(for: .randomFact)
            }
            if authenticationManager.userLoggedIn && !authenticationManager.isDeletingAccount {
                NavigationLink(value: AppPage.favoriteFacts) {
                    label(for: .favoriteFacts)
                }
                .disabled(appStateManager.factText == generatingRandomFactString || favoriteFactsDatabase.randomizerRunning)
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
        .navigationTitle("\(appName!)")
#if os(iOS)
        .navigationBarTitleDisplayMode(.automatic)
#endif
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    var mainContent: some View {
        switch appStateManager.selectedPage {
            case .randomFact, nil:
                FactView()
            case .favoriteFacts:
                FavoriteFactsListView()
            #if !os(macOS)
            case .settings:
                SettingsView()
            #endif
        }
    }
    
    // MARK: - Sidebar Item Labels

    // This method applies a label to a navigation link based on page.
    @ViewBuilder
    func label(for page: AppPage) -> some View {
        switch page {
            case .randomFact:
                Label("Random Fact", systemImage: "dice")
                .symbolRenderingMode(.hierarchical)
            case .favoriteFacts:
                Label("Favorite Facts", systemImage: "list.star")
                .symbolRenderingMode(.hierarchical)
                // A numeric badge is only displayed if its count isn't 0.
                .badge(favoriteFactsDatabase.favoriteFacts.count)
            #if !os(macOS)
            case .settings:
                Label("Settings", systemImage: "gear")
            #endif
		}
	}

}

#Preview("Loading") {
    ContentView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            appStateManager.factText = loadingString
        }
    #endif
}

#Preview("Loaded") {
    ContentView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            appStateManager.factText = sampleFact
        }
    #endif
}

#Preview("Generating") {
    ContentView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            appStateManager.factText = generatingRandomFactString
        }
    #endif
}

