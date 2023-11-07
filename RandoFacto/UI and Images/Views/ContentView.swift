//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct ContentView: View {

	// MARK: - Properties - Objects

	@ObservedObject var viewModel: RandoFactoViewModel

#if os(iOS)
	private var haptics = UINotificationFeedbackGenerator()
#endif

	// MARK: - View

	var body: some View {
		NavigationStack {
#if os(macOS)
			SAMVisualEffectViewSwiftUIRepresentable {
				content
			}
#else
			content
#endif
		}
	}

	var content: some View {
		VStack {
			factView
			Spacer()
			buttons
			Divider()
			footer
		}
		.navigationDestination(isPresented: $viewModel.showingFavoriteFactsList) {
			FavoritesList(viewModel: viewModel)
		}
		.padding(.top, 50)
		.padding(.bottom)
		.padding(.horizontal)
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
		// Error alert
		.alert(isPresented: $viewModel.showingErrorAlert, error: viewModel.errorToShow, actions: {
			Button {
				viewModel.showingErrorAlert = false
				viewModel.errorToShow = nil
			} label: {
				Text("OK")
			}
		})
		// Unfavorite all facts alert
		.alert("Unfavorite all facts?", isPresented: $viewModel.showingDeleteAllFavoriteFacts, actions: {
			Button("Unfavorite", role: .destructive) {
				viewModel.deleteAllFavoriteFactsForCurrentUser { error in
					if let error = error {
						viewModel.showError(error: error)
					}
					viewModel.showingDeleteAllFavoriteFacts = false
				}
			}
			Button("Cancel", role: .cancel) {
				viewModel.showingDeleteAllFavoriteFacts = false
			}
		})
		// Delete account alert
		.alert("Delete your account?", isPresented: $viewModel.showingDeleteAccount, actions: {
			Button("Delete", role: .destructive) {
				viewModel.deleteCurrentUser()
				viewModel.showingDeleteAccount = false
			}
			Button("Cancel", role: .cancel) {
				viewModel.showingDeleteAccount = false
			}
		}, message: {
			Text("You won't be able to save favorite facts to view offline!")
		})
		// Authentication form
		.sheet(item: $viewModel.authenticationFormType, onDismiss: {
			viewModel.authenticationFormType = nil
		}, content: { _ in
			AuthenticationFormView(viewModel: viewModel)
		})
		// Toolbar
		.toolbar {
			toolbarContent
		}
	}

	var factView: some View {
		ScrollView {
			Text(viewModel.factText)
				.font(.largeTitle)
				.isTextSelectable(!(viewModel.notDisplayingFact || viewModel.factText == viewModel.factUnavailableString))
				.multilineTextAlignment(.center)
		}
	}

	var footer: some View {
		VStack {
			Text("Facts provided by [uselessfacts.jsph.pl](https://uselessfacts.jsph.pl).")
			Text("Favorite facts database powered by Google Firebase.")
		}
		.font(.footnote)
		.foregroundColor(.secondary)
	}

	// MARK: - Buttons

	var buttons: some View {
		ConditionalHVStack {
			if viewModel.userLoggedIn {
				if !(viewModel.favoriteFacts.isEmpty) {
					Button {
						DispatchQueue.main.async {
							// Sets factText to a random fact from the favorite facts list.
							viewModel.factText = viewModel.getRandomFavoriteFact()
						}
					} label: {
						Text("Get Random Favorite Fact")
					}
#if os(iOS)
					.padding()
#endif
				}
			}
			if viewModel.online {
				Button {
					viewModel.generateRandomFact()
				} label: {
					Text("Generate Random Fact")
				}
#if os(iOS)
				.padding()
#endif
			}
		}
		.disabled(viewModel.notDisplayingFact)
	}

	// MARK: - Toolbar

	@ToolbarContentBuilder
	var toolbarContent: some ToolbarContent {
		let displayingLoadingMessage = viewModel.factText.last == "…" || viewModel.factText.isEmpty
		if displayingLoadingMessage {
			ToolbarItem(placement: .automatic) {
				LoadingIndicator()
			}
		} else {
			if viewModel.factText != viewModel.factUnavailableString && viewModel.userLoggedIn {
				ToolbarItem(placement: .automatic) {
					if viewModel.favoriteFacts.contains(viewModel.factText) {
						Button {
							DispatchQueue.main.async {
								viewModel.deleteFromFavorites(fact: viewModel.factText)
							}
						} label: {
							Image(systemName: "heart.fill")
								.symbolRenderingMode(.multicolor)
								.accessibilityLabel("Unfavorite")
						}.padding()
							.help("Unfavorite")
							.disabled(viewModel.notDisplayingFact || viewModel.factText == viewModel.factUnavailableString)
					} else {
						Button {
							DispatchQueue.main.async {
								viewModel.saveToFavorites(fact: viewModel.factText)
							}
						} label: {
							Image(systemName: "heart")
								.accessibilityLabel("Favorite")
						}.padding()
							.help("Favorite")
							.disabled(viewModel.notDisplayingFact || viewModel.factText == viewModel.factUnavailableString)
					}
				}
			}
			ToolbarItem(placement: .automatic) {
				accountMenu
			}
		}
	}

	// MARK: - Account Menu

	var accountMenu: some View {
		Menu {
			if !viewModel.online && !viewModel.userLoggedIn {
				// Text = disabled menu item
				Text("Offline")
			}
			if viewModel.userLoggedIn {
				Section(header:
							Text((viewModel.firebaseAuthentication.currentUser?.email)!)
				) {
					Menu("Favorite Facts List") {
						// Buttom = enabled menu item
						Button {
							DispatchQueue.main.async {
								viewModel.showingFavoriteFactsList = true
							}
						} label: {
							Text("View…")
						}
						Button {
							DispatchQueue.main.async {
								viewModel.showingDeleteAllFavoriteFacts = true
							}
						} label: {
							Text("Unfavorite All…")
						}
					}
					Menu("Account") {
						Button {
							viewModel.logoutCurrentUser()
						} label: {
							Text("Logout")
						}
						if viewModel.online {
							Button {
								DispatchQueue.main.async {
									viewModel.showingDeleteAccount = true
								}
							} label: {
								Text("Delete Account…")
							}
						}
					}
				}
			} else {
				if viewModel.online {
					Button {
						DispatchQueue.main.async {
							viewModel.authenticationFormType = .login
						}
					} label: {
						Text("Login…")
					}
					Button {
						DispatchQueue.main.async {
							viewModel.authenticationFormType = .signup
						}

					} label: {
						Text("Signup…")
					}
				}
			}
		} label: {
			Image(systemName: "person.circle")
				.accessibilityLabel("Account")
		}
		.disabled(viewModel.notDisplayingFact)
		.help("Account")
	}

}

#Preview {
	ContentView(viewModel: RandoFactoViewModel())
}
