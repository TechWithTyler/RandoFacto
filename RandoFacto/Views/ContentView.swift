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

	private let errorString = "Fact error. Trying another…"

	private let factUnavailableString = "Fact unavailable"

	@State private var factText: String = "Fact Text"

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
					}
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
							credentialFields
							Button {
								randoFactoDatabase.signUp(email: email, password: password) { error in
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
						if randoFactoDatabase.firebaseAuth.currentUser != nil {
							Text("For security, please log in again.")
						}
						Form {
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
						Menu {
							if userLoggedIn {
								Button {
									showingDeleteAllFavorites = true
								} label: {
									Text("Delete All Favorite Facts…")
								}
								//								Divider()
								Button {
									randoFactoDatabase.logOut()
								} label: {
									Text("Logout")
								}
								if randoFactoDatabase.online {
									Button {
										showingDeleteUser = true
									} label: {
										Text("Delete User")
									}
								}
							} else {
								if randoFactoDatabase.online {
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
								}
							}
						} label: {
							Image(systemName: "person.circle")
						}
						.disabled(notDisplayingFact)
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
			if randoFactoDatabase.online {
				Button {
					Task {
						await factGenerator.generateRandomFact()
					}
				} label: {
					Text("Generate Random Fact")
				}.padding()
			}
			if randoFactoDatabase.firebaseAuth.currentUser != nil {
				if !(randoFactoDatabase.favorites.isEmpty) {
					Button {
						factText = randoFactoDatabase.favorites.randomElement()!
					} label: {
						Text("Generate Random Favorite Fact")
					}.padding()
				}
			}
		}
		.disabled(factText == generatingString || factText == errorString)
	}

	var credentialFields: some View {
		Section {
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
			randoFactoDatabase.delegate = self
			await randoFactoDatabase.loadFavorites()
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
		let nsError = error as NSError
		print("\(nsError), \(nsError.code), \(nsError.userInfo)")
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
				showingLogIn = true
			default:
				errorToShow = .unknown(reason: "\(nsError.userInfo[NSLocalizedDescriptionKey] ?? "Unknown error")")
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
