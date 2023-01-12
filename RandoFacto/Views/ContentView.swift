//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//

import SwiftUI

struct ContentView: View, FactGeneratorDelegate, RandoFactoDatabaseDelegate {

	private var factGenerator: FactGenerator {
		return FactGenerator(delegate: self)
	}

	@ObservedObject private var randoFactoDatabase = RandoFactoDatabase()

	private let generatingString = "Generating Fact…"

	private let errorString = "Fact contains profanity. Trying another…"

	private let factUnavailableString = "Fact unavailable"

	@State private var factText: String = "Fact Text"

	@State private var credentialErrorText: String? = nil

	@State private var errorToShow: NetworkError?

	@State private var showingError: Bool = false

	@State private var showingLogIn: Bool = false

	@State private var showingSignUp: Bool = false

	@State private var showingDeleteUser: Bool = false

	@State private var showingDeleteAllFavorites: Bool = false

	@State private var email: String = String()

	@State private var password: String = String()

	var body: some View {
		NavigationStack {
			ZStack {
				#if os(macOS)
				VisualEffectView()
				#endif
				VStack {
					ScrollView {
						Text(factText)
							.font(.largeTitle)
							.textSelection(.enabled)
					}
					Spacer()
					buttons
					Divider()
					Text("Facts provided by [uselessfacts.jsph.pl](https://uselessfacts.jsph.pl)")
						.font(.footnote)
						.foregroundColor(.secondary)
					Text("Facts checked for profanity by [purgomalum.com](https://www.purgomalum.com)")
						.font(.footnote)
						.foregroundColor(.secondary)
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
				.alert("Delete all favorite facts?", isPresented: $showingDeleteAllFavorites, actions: {
					Button("Delete", role: .destructive) {
						randoFactoDatabase.deleteAllFavorites { error in
							if let error = error {
								showError(error: error)
							} else {
								print("All favorites deletion successful")
							}
							showingDeleteAllFavorites = false
						}
					}
					Button("Cancel", role: .cancel) {
						showingDeleteAllFavorites = false
					}
				})
				.alert("Delete user?", isPresented: $showingDeleteUser, actions: {
					Button("Delete", role: .destructive) {
						randoFactoDatabase.deleteUser()
						showingDeleteUser = false
					}
					Button("Cancel", role: .cancel) {
						showingDeleteUser = false
					}
				})
				.sheet(isPresented: $showingSignUp, onDismiss: {
					dismissSignUp()
				}, content: {
					NavigationStack {
						Form {
							if let errorText = credentialErrorText {
								HStack {
									Image(systemName: "exclamationmark.triangle")
									Text(errorText)
										.font(.system(size: 18))
										.lineLimit(2)
										.multilineTextAlignment(.center)
										.padding()
								}
									.foregroundColor(.red)
							}
							credentialFields
							Button {
								randoFactoDatabase.logIn(email: email, password: password) { error in
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
						.padding(.horizontal)
						.navigationTitle("Register")
#if os(iOS)
						.navigationBarTitleDisplayMode(.inline)
#endif
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
					}
				})
				.sheet(isPresented: $showingLogIn, onDismiss: {
					dismissLogIn()
				}, content: {
					NavigationStack {
						Form {
							if let errorText = credentialErrorText {
								HStack {
									Image(systemName: "exclamationmark.triangle")
									Text(errorText)
										.font(.system(size: 18))
										.lineLimit(2)
										.multilineTextAlignment(.center)
										.padding()
								}
								.foregroundColor(.red)
							}
							credentialFields
							Button {
								randoFactoDatabase.logIn(email: email, password: password) { error in
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
						.padding(.horizontal)
						.navigationTitle("Login")
#if os(iOS)
						.navigationBarTitleDisplayMode(.inline)
#endif
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
					}
				})
				.toolbar {
					let userLoggedIn = randoFactoDatabase.firebaseAuth.currentUser != nil
					let notDisplayingFact = factText == generatingString || factText == errorString
					if factText != factUnavailableString && userLoggedIn {
						ToolbarItem(placement: .automatic) {
							if randoFactoDatabase.favorites.contains(factText) {
								Button {
									randoFactoDatabase.deleteFromFavorites(fact: factText)
								} label: {
									Label {
										Text("\(randoFactoDatabase.favorites.count)")
									} icon: {
										Image(systemName: "heart.fill")
									}
								}.padding()
									.labelStyle(.titleAndIcon)
									.help("Unfavorite")
									.disabled(notDisplayingFact || factText == factUnavailableString)
							} else {
								Button {
									randoFactoDatabase.saveToFavorites(fact: factText)
								} label: {
									Label {
										Text("\(randoFactoDatabase.favorites.count)")
									} icon: {
										Image(systemName: "heart")
									}
								}.padding()
									.labelStyle(.titleAndIcon)
									.help("Favorite")
									.disabled(notDisplayingFact || factText == factUnavailableString)
							}
						}
					}
					ToolbarItem(placement: .automatic) {
						accountMenu
					}
				}
				.onAppear {
					prepareView()
				}
			}
		}
	}

	var buttons: some View {
		VStack {
			if randoFactoDatabase.firebaseAuth.currentUser != nil {
				if !(randoFactoDatabase.favorites.isEmpty) {
					Button {
						factText = randoFactoDatabase.favorites.randomElement()!
					} label: {
						Text("Generate Random Favorite Fact")
					}
#if os(iOS)
					.padding()
#endif
				}
			}
			if randoFactoDatabase.online {
				Button {
					Task {
						await factGenerator.generateRandomFact()
					}
				} label: {
					Text("Generate Random Fact")
				}
				#if os(iOS)
				.padding()
				#endif
			}
		}
		.disabled(factText == generatingString || factText == errorString)
	}

	var accountMenu: some View {
		let userLoggedIn = randoFactoDatabase.firebaseAuth.currentUser != nil
		let notDisplayingFact = factText == generatingString || factText == errorString
		return Menu {
			if userLoggedIn {
				Button {
					showingDeleteAllFavorites = true
				} label: {
					Text("Delete All Favorite Facts…")
				}
				Divider()
				Button {
					randoFactoDatabase.logOut()
				} label: {
					Text("Logout")
				}
				if randoFactoDatabase.online {
					Button {
						showingDeleteUser = true
					} label: {
						Text("Delete User…")
					}
				}
			} else {
				if randoFactoDatabase.online {
					Button {
						showingLogIn = true
					} label: {
						Text("Login…")
					}
					Button {
						showingSignUp = true
					} label: {
						Text("Register…")
					}
				}
			}
		} label: {
			Image(systemName: "person.circle")
		}
		.disabled(notDisplayingFact)
	}

	var credentialFields: some View {
		Section {
			HStack {
				TextField("Email", text: $email)
				#if os(iOS)
					.keyboardType(.emailAddress)
				#endif
			}
			HStack {
				SecureField("Password", text: $password)
					.textContentType(.password)
			}
		}
	}

	func prepareView() {
		email = String()
		password = String()
		Task {
			randoFactoDatabase.delegate = self
			await randoFactoDatabase.loadFavorites()
			await factGenerator.generateRandomFact()
		}
	}

	func dismissSignUp() {
		showingSignUp = false
		email = String()
		password = String()
		credentialErrorText = nil
	}

	func dismissLogIn() {
		showingLogIn = false
		email = String()
		password = String()
		credentialErrorText = nil
	}

	func showError(error: Error) {
		let nsError = error as NSError
		print("\(nsError), \(nsError.code), \(nsError.userInfo)")
		switch nsError.code {
				// Network errors
			case -1009:
				errorToShow = .noInternet
				// Fact data errors
			case 423:
				errorToShow = .noText
			case 523:
				errorToShow = .dataError
			case 524:
				errorToShow = .filteredDataError
				// Database errors
			case 17014:
				showingLogIn = true
				errorToShow = .userDeletionFailed(reason: "It's been too long since you last logged in. Please log in and try deleting your account again.")
			case 17020:
				return
				// Other errors
			default:
				errorToShow = .unknown(reason: "\(nsError.userInfo[NSLocalizedDescriptionKey] ?? "Unknown error: Code \(nsError.code)")")
		}
		if showingLogIn || showingSignUp {
			credentialErrorText = errorToShow?.errorDescription
		} else {
			showingError = true
		}
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

	func randoFactoDatabaseLoadingDidFail(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToAddFavorite(_ database: RandoFactoDatabase, fact: String, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToRemoveFavorite(_ database: RandoFactoDatabase, fact: String, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToDeleteUser(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToLogOut(_ database: RandoFactoDatabase, userEmail: String, error: Error) {
		showError(error: error)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
