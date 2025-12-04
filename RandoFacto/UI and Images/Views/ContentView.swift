//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI
import Speech

struct ContentView: View {

    // MARK: - Properties - Objects

    @EnvironmentObject var windowStateManager: WindowStateManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase

    @EnvironmentObject var favoriteFactsDisplayManager: FavoriteFactsDisplayManager

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
                .navigationSplitViewColumnWidth(250)
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
        .alert("Unfavorite this fact?", isPresented: $favoriteFactsDisplayManager.showingDeleteFavoriteFact, presenting: $favoriteFactsDisplayManager.favoriteFactToDelete) { factText in
            Button("Unfavorite", role: .destructive) {
                favoriteFactsDatabase.unfavoriteFact(factText.wrappedValue!)
            }
            Button("Cancel", role: .cancel) {
                favoriteFactsDisplayManager.showingDeleteFavoriteFact = false
                favoriteFactsDisplayManager.favoriteFactToDelete = nil
            }
        } message: { factText in
            if windowStateManager.selectedPage == .randomFact || windowStateManager.factText == factText.wrappedValue {
                Text("Make sure to re-favorite this fact BEFORE generating a new one if you change your mind!")
            } else {
                Text("This can't be undone!")
            }
        }
        // Unfavorite all facts alert
        .alert("Are you sure you REALLY want to unfavorite all facts?", isPresented: $favoriteFactsDisplayManager.showingDeleteAllFavoriteFacts) {
            Button("Unfavorite", role: .destructive) {
                favoriteFactsDatabase.deleteAllFavoriteFactsForCurrentUser { error in
                    if let error = error {
                        DispatchQueue.main.async { [self] in
                            errorManager.showError(error)
                        }
                    }
                    favoriteFactsDisplayManager.showingDeleteAllFavoriteFacts = false
                }
            }
            Button("Cancel", role: .cancel) {
                favoriteFactsDisplayManager.showingDeleteAllFavoriteFacts = false
            }
        } message: {
            Text("This can't be undone!")
        }
#if os(macOS)
        .dialogSeverity(.critical)
#endif
        // Onboarding sheet
        .sheet(isPresented: $windowStateManager.showingOnboarding) {
            OnboardingView()
        }
        .onAppear {
            if windowStateManager.shouldOnboard {
                windowStateManager.showingOnboarding = true
            }
        }
        // Nil selection catcher
        .onChange(of: horizontalSizeClass) { oldSizeClass, newSizeClass in
            if windowStateManager.selectedPage == nil && newSizeClass != .compact {
                windowStateManager.selectedPage = .randomFact
            }
        }
        .onChange(of: windowStateManager.selectedPage) { oldPage, newPage in
            if newPage == nil && horizontalSizeClass == .regular {
                windowStateManager.selectedPage = .randomFact
            }
        }
        // User login state change/user deletion
        .onChange(of: authenticationManager.accountDeletionStage) { oldDeletionStage, newDeletionStage in
            if newDeletionStage != nil {
                favoriteFactsDisplayManager.showingDeleteFavoriteFact = false
                favoriteFactsDisplayManager.showingDeleteAllFavoriteFacts = false
                windowStateManager.dismissFavoriteFacts()
            }
        }
        .onChange(of: authenticationManager.userLoggedIn) { wasLoggedIn, isLoggedIn in
            if !isLoggedIn {
                favoriteFactsDisplayManager.showingDeleteFavoriteFact = false
                favoriteFactsDisplayManager.showingDeleteAllFavoriteFacts = false
                windowStateManager.dismissFavoriteFacts()
            }
        }
        // Error sound (Mac) or haptics (iPhone)
        .onChange(of: errorManager.errorToShow) { oldError, newError in
            if newError != nil {
#if os(macOS)
                NSSound.beep()
#elseif os(iOS)
                haptics.notificationOccurred(.error)
#endif
            }
        }
        .focusedSceneObject(windowStateManager)
    }

    // MARK: - Sidebar

    @ViewBuilder
    var sidebarContent: some View {
        List(selection: $windowStateManager.selectedPage) {
            // We can't simply iterate through the AppPage enum's cases to create the navigation links, as one of them (Favorite Facts) only appears when a condition (user logged in and not being deleted) is true.
            NavigationLink(value: AppPage.randomFact) {
                label(for: .randomFact)
            }
            if authenticationManager.userLoggedIn && !authenticationManager.isDeletingAccount {
                NavigationLink(value: AppPage.favoriteFacts) {
                    label(for: .favoriteFacts)
                }
                .disabled(windowStateManager.factText == generatingRandomFactString || favoriteFactsDisplayManager.randomizerRunning)
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
        switch windowStateManager.selectedPage {
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

// MARK: - Preview

#Preview("Loading") {
    ContentView()
#if DEBUG
        .withPreviewData { windowStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsDisplayManager in
            windowStateManager.factText = loadingString
        }
#endif
}

#Preview("Loaded") {
    ContentView()
#if DEBUG
        .withPreviewData { windowStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsDisplayManager in
            windowStateManager.factText = sampleFact
        }
#endif
}

#Preview("Generating") {
    ContentView()
#if DEBUG
        .withPreviewData { windowStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsDisplayManager in
            windowStateManager.factText = generatingRandomFactString
        }
#endif
}

