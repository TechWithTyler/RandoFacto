//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//

import SwiftUI

struct ContentView: View, FactGeneratorDelegate, FavoritesDelegate {

	private var factGenerator: FactGenerator {
		return FactGenerator(delegate: self)
	}

	@ObservedObject private var favoritesDatabase = FavoritesDatabase()

	private let generatingString = "Generating Fact…"

	private let errorString = "Fact error. Trying another…"

	private let factUnavailableString = "Fact unavailable"

	@State private var factText: String = "Fact Text"

	@State private var errorToShow: NetworkError?

	@State private var showingError: Bool = false

	@State private var showingLogIn: Bool = false

	@State private var showingSignUp: Bool = false

	@State private var showingDeleteUser: Bool = false

	@State private var email: String = String()

	@State private var password: String = String()

	var body: some View {
		VStack {
			Text(factText)
				.font(.largeTitle)
			Spacer()
			buttons
		}
		.padding()
		.alert(isPresented: $showingError, error: errorToShow, actions: {
			Button {
				showingError = false
				errorToShow = nil
			} label: {
				Text("OK")
			}
		})
		.alert("Delete user?", isPresented: $showingDeleteUser, actions: {
			Button("Delete", role: .destructive) {
				favoritesDatabase.deleteUser()
				showingDeleteUser = false
			}
			Button("Cancel", role: .cancel) {
				showingDeleteUser = false
			}
		}, message: {
			Text("Delete this user?")
		})
		.sheet(isPresented: $showingSignUp, onDismiss: {
			dismissSignUp()
		}, content: {
			VStack {
				Form {
					Text("Register")
						.font(.largeTitle)
						.multilineTextAlignment(.center)
					credentialFields
					Button {
						favoritesDatabase.signUp(email: email, password: password) { error in
							if let error = error {
								showError(error: error)
							} else {
								dismissSignUp()
							}
						}
					} label: {
						Text("Register")
					}
				}
			}
			.frame(minWidth: 400, minHeight: 400)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismissSignUp()
					} label: {
						Text("Cancel")
					}
				}
			}
		})
		.sheet(isPresented: $showingLogIn, onDismiss: {
			dismissLogIn()
		}, content: {
			VStack {
				Form {
					Text("Login")
						.font(.largeTitle)
						.multilineTextAlignment(.center)
					credentialFields
					Button {
						favoritesDatabase.logIn(email: email, password: password) { error in
							if let error = error {
								showError(error: error)
							} else {
								dismissLogIn()
							}
						}
					} label: {
						Text("Login")
					}
				}
			}
			.frame(minWidth: 400, minHeight: 400)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismissLogIn()
					} label: {
						Text("Cancel")
					}
				}
			}
		})
		.toolbar {
			ToolbarItem(placement: .automatic) {
				Menu {
					if favoritesDatabase.firebaseAuth.currentUser == nil {
						Button {
							showingLogIn = true
						} label: {
							Text("Login")
						}
						Button {
							showingSignUp = true
						} label: {
							Text("Register")
						}
					} else {
						Button {
							favoritesDatabase.logOut()
						} label: {
							Text("Logout")
						}
						Button {
							showingDeleteUser = true
						} label: {
							Text("Delete User")
						}
					}
				} label: {
					Image(systemName: "person.circle")
				}
			}
		}
		.onAppear {
			prepareView()
		}
	}

	var buttons: some View {
		VStack {
			Button {
				Task {
					await factGenerator.generateRandomFact()
				}
			} label: {
				Text("Generate Random Fact")
			}
			if favoritesDatabase.firebaseAuth.currentUser != nil && factText != factUnavailableString {
				if !(favoritesDatabase.favorites.isEmpty) {
					Button {
						factText = favoritesDatabase.favorites.randomElement()!
					} label: {
						Text("Generate Random Favorite Fact")
					}
				}
				if favoritesDatabase.favorites.contains(factText) {
					Button {
						favoritesDatabase.deleteFromFavorites(fact: factText)
					} label: {
						Image(systemName: "heart")
						Text("Unfavorite")
					}
				} else {
					Button {
						favoritesDatabase.saveToFavorites(fact: factText)
					} label: {
						Image(systemName: "heart.fill")
						Text("Favorite")
					}
				}
			}
		}
		.disabled(factText == generatingString || factText == errorString)
	}

	var credentialFields: some View {
		VStack {
			HStack {
				TextField("Email", text: $email)
			}
			HStack {
				SecureField("Password", text: $password)
			}
		}
	}

	func prepareView() {
		email = String()
		password = String()
		Task {
			favoritesDatabase.delegate = self
			await favoritesDatabase.loadFavorites()
			await factGenerator.generateRandomFact()
		}
	}

	func dismissSignUp() {
		showingSignUp = false
		email = String()
		password = String()
	}

	func dismissLogIn() {
		showingLogIn = false
		email = String()
		password = String()
	}

	func showError(error: Error) {
		print(error)
		let nsError = error as NSError
		switch nsError.code {
			case -1009:
				errorToShow = .noInternet
			case 423:
				errorToShow = .noText
			case 523:
				errorToShow = .dataError
			case 524:
				errorToShow = .filteredDataError
			case 17014:
				errorToShow = .userDeletionFailed(reason: "This operation requires that you have logged in recently. Please log out and back in and try again.")
			default:
				errorToShow = .unknown
		}
		showingError = true
	}

}

extension ContentView {

	func factGeneratorWillGenerateFact(_ generator: FactGenerator) {
		factText = generatingString
	}

	func factGeneratorWillRetry(_ generator: FactGenerator) {
		factText = errorString
	}

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String) {
		factText = fact
	}

	func factGeneratorDidFail(_ generator: FactGenerator, error: Error) {
		print(error)
		factText = factUnavailableString
		showError(error: error)
	}
}

extension ContentView {

	func favoritesDatabaseLoadingDidFail(_ database: FavoritesDatabase, error: Error) {
		showError(error: error)
	}

	func favoritesDatabaseDidAddFavorite(_ database: FavoritesDatabase, fact: String) {

	}

	func favoritesDatabaseDidRemoveFavorite(_ database: FavoritesDatabase, fact: String) {

	}

	func favoritesDatabaseDidFailToAddFavorite(_ database: FavoritesDatabase, fact: String, error: Error) {
		showError(error: error)
	}

	func favoritesDatabaseDidFailToRemoveFavorite(_ database: FavoritesDatabase, fact: String, error: Error) {
		showError(error: error)
	}

	func favoritesDatabaseDidFailToDeleteUser(_ database: FavoritesDatabase, error: Error) {
		showError(error: error)
	}

	func favoritesDatabaseDidFailToLogOut(_ database: FavoritesDatabase, userEmail: String, error: Error) {
		showError(error: error)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
