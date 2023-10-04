//
//  ContentView.swift
//  RandoFacto
//
//  Created by TechWithTyler on 11/21/22.
//

import SwiftUI

struct ContentView: View, FactGeneratorDelegate, RandoFactoDatabaseDelegate {

	// MARK: - Properties - Objects

	private var factGenerator: FactGenerator {
		return FactGenerator(delegate: self)
	}

	@ObservedObject var randoFactoDatabase = RandoFactoDatabase()

	// MARK: - Properties - Strings

	private let generatingString = "Generating Fact…"

	private let errorString = "Fact contains profanity. Trying another…"

	private let factUnavailableString = "Fact unavailable"

	@State var factText: String = "Fact Text"

	@State private var credentialErrorText: String? = nil

	@State private var email: String = String()

	@State private var password: String = String()

	// MARK: - Properties - Network Error

	@State private var errorToShow: NetworkError?

	// MARK: - Properties - Booleans

	@State private var showingErrorAlert: Bool = false

	@State private var showingLogIn: Bool = false

	@State private var showingSignUp: Bool = false

	@State private var showingDeleteUser: Bool = false

	@State private var showingDeleteAllFavorites: Bool = false

	@State var showingFavoritesList: Bool = false

	// MARK: - View

	var body: some View {
		NavigationStack {
#if os(macOS)
			VisualEffectView {
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
		.padding(.top, 50)
		.padding(.bottom)
		.padding(.horizontal)
		.alert(isPresented: $showingErrorAlert, error: errorToShow, actions: {
			Button {
				showingErrorAlert = false
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
		.sheet(isPresented: $showingFavoritesList, onDismiss: {
			showingFavoritesList = false
		}, content: {
			FavoritesList(parent: self)
		})
		.sheet(isPresented: $showingSignUp, onDismiss: {
			dismissSignUp()
		}, content: {
			signUpForm
		})
		.sheet(isPresented: $showingLogIn, onDismiss: {
			dismissLogIn()
		}, content: {
			logInForm
		})
		.toolbar {
			toolbarContent
		}
		.onAppear {
			prepareView()
		}
	}

	var factView: some View {
		ScrollView {
			Text(factText)
				.font(.largeTitle)
				.textSelection(.enabled)
				.multilineTextAlignment(.center)
		}
	}

	var footer: some View {
		VStack {
			Text("Facts provided by [api-ninjas.com](https://api-ninjas.com)")
				.font(.footnote)
				.foregroundColor(.secondary)
		}
	}

	// MARK: - Buttons

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
						factGenerator.generateRandomFact()
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

	// MARK: - Toolbar

	@ToolbarContentBuilder
	var toolbarContent: some ToolbarContent {
			let userLoggedIn = randoFactoDatabase.firebaseAuth.currentUser != nil
			let notDisplayingFact = factText == generatingString || factText == errorString
			let displayingLoadingMessage = factText.last == "…"
			if displayingLoadingMessage {
				ToolbarItem(placement: .automatic) {
					ProgressView()
						.progressViewStyle(.circular)
#if os(macOS)
						.controlSize(.small)
#endif
				}
			}
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

	// MARK: - Account Menu

	var accountMenu: some View {
		let userLoggedIn = randoFactoDatabase.firebaseAuth.currentUser != nil
		let notDisplayingFact = factText == generatingString || factText == errorString
		return Menu {
			if !randoFactoDatabase.online && !userLoggedIn {
				Text("Offline")
			}
			if userLoggedIn {
				Section(header:
				Text((randoFactoDatabase.firebaseAuth.currentUser?.email)!)
				) {
					Menu("Favorites List") {
						Button {
							showingFavoritesList = true
						} label: {
							Text("View…")
						}
						Button {
							showingDeleteAllFavorites = true
						} label: {
							Text("Delete All…")
						}
					}
					Menu("Account") {
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

	// MARK: - Forms

	var signUpForm: some View {
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
			.formStyle(.grouped)
			.padding(.horizontal)
			.keyboardShortcut(.defaultAction)
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
	}

	var logInForm: some View {
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
			.formStyle(.grouped)
			.keyboardShortcut(.defaultAction)
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
	}

	// MARK: - Credential Fields

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

	// MARK: - UI Methods

	func prepareView() {
		email = String()
		password = String()
		Task {
			randoFactoDatabase.delegate = self
			await randoFactoDatabase.loadFavorites()
			factGenerator.generateRandomFact()
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

	// MARK: - Error Handling

	func showError(error: Error) {
		let nsError = error as NSError
		print("Error: \(nsError)")
		// Check the error code to choose which error to show.
		switch nsError.code {
				// Network errors
			case -1009:
				errorToShow = .noInternet
				// Fact data errors
			case 423:
				errorToShow = .noText
			case 523:
				errorToShow = .dataError
				// Database errors
			case 17014:
				showingLogIn = true
				errorToShow = .userDeletionFailed(reason: "It's been too long since you last logged in. Please log in and try deleting your account again.")
			case 17052:
				errorToShow = .quotaExceeded
				// Database errors
			case 17020:
				return
				// Other errors
			default:
				errorToShow = .unknown(reason: "\(nsError.userInfo[NSLocalizedDescriptionKey] ?? "Unknown error: Code \(nsError.code)")")
		}
		// Show the error in the log in/sign up dialog if they're open, otherwise show it as an alert.
		if showingLogIn || showingSignUp {
			credentialErrorText = errorToShow?.errorDescription
		} else {
			showingErrorAlert = true
		}
	}

}

extension ContentView {

	// MARK: - Fact Generator Delegate

	func factGeneratorWillGenerateFact(_ generator: FactGenerator) {
		factText = generatingString
	}

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String) {
		factText = fact
	}

	func factGeneratorDidFail(_ generator: FactGenerator, error: Error) {
		factText = factUnavailableString
		showError(error: error)
	}
}

extension ContentView {

	// MARK: - RandoFacto Database Delegate

	func randoFactoDatabaseNetworkEnableDidFail(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseNetworkDisableDidFail(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseLoadingDidFail(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToAddFavorite(_ database: RandoFactoDatabase, fact: String, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToDeleteFavorite(_ database: RandoFactoDatabase, fact: String, error: Error) {
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
