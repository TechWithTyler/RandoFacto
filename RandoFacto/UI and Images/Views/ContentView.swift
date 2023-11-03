//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct ContentView: View, FactGeneratorDelegate, RandoFactoDatabaseDelegate {

	// MARK: - Properties - Objects

	private var factGenerator: FactGenerator {
		return FactGenerator(delegate: self)
	}

	@ObservedObject var randoFactoDatabase = RandoFactoDatabase()

	#if os(iOS)
	private var haptics = UINotificationFeedbackGenerator()
	#endif

	// MARK: - Properties - Strings

	private let generatingString = "Generating random fact…"

	private let screeningString = "Screening fact…"

	private let factUnavailableString = "Fact unavailable"

	@State var factText: String = String()

	@State private var credentialErrorText: String? = nil

	@State private var email: String = String()

	@State private var password: String = String()

	// MARK: - Properties - Network Error

	@State private var errorToShow: NetworkError?

	// MARK: - Properties - Authentication Form Type

	@State private var authFormType: AuthFormType? = nil

	// MARK: - Properties - Booleans

	@State private var showingErrorAlert: Bool = false

	@State private var showingDeleteAccount: Bool = false

	@State private var showingDeleteAllFavoriteFacts: Bool = false

	@State var showingFavoriteFactsList: Bool = false

	private var notDisplayingFact: Bool {
		return factText.isEmpty || factText == generatingString || factText == screeningString
	}

	private var userLoggedIn: Bool {
		return randoFactoDatabase.firebaseAuth.currentUser != nil
	}

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
		.alert("Unfavorite all facts?", isPresented: $showingDeleteAllFavoriteFacts, actions: {
			Button("Unfavorite", role: .destructive) {
				randoFactoDatabase.deleteAllFavoriteFactsForCurrentUser { error in
					if let error = error {
						showError(error: error)
					}
					showingDeleteAllFavoriteFacts = false
				}
			}
			Button("Cancel", role: .cancel) {
				showingDeleteAllFavoriteFacts = false
			}
		})
		.alert("Delete your account?", isPresented: $showingDeleteAccount, actions: {
			Button("Delete", role: .destructive) {
				randoFactoDatabase.deleteCurrentUser()
				showingDeleteAccount = false
			}
			Button("Cancel", role: .cancel) {
				showingDeleteAccount = false
			}
		}, message: {
			Text("You won't be able to save favorite facts to view offline!")
		})
		.sheet(isPresented: $showingFavoriteFactsList, onDismiss: {
			showingFavoriteFactsList = false
		}, content: {
			FavoritesList(parent: self)
		})
		.sheet(item: $authFormType, onDismiss: {
			dismissAuthForm()
		}, content: { _ in
			authForm
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
				.isTextSelectable(!(notDisplayingFact || factText == factUnavailableString))
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
			if randoFactoDatabase.firebaseAuth.currentUser != nil {
				if !(randoFactoDatabase.favoriteFacts.isEmpty) {
					Button {
						factText = randoFactoDatabase.getRandomFavoriteFact()
					} label: {
						Text("Get Random Favorite Fact")
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
		.disabled(notDisplayingFact)
	}

	// MARK: - Toolbar

	@ToolbarContentBuilder
	var toolbarContent: some ToolbarContent {
		let displayingLoadingMessage = factText.last == "…" || factText.isEmpty
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
					if randoFactoDatabase.favoriteFacts.contains(factText) {
						Button {
							randoFactoDatabase.deleteFromFavorites(fact: factText)
						} label: {
								Image(systemName: "heart.fill")
								.accessibilityLabel("Unfavorite")
						}.padding()
							.help("Unfavorite")
							.disabled(notDisplayingFact || factText == factUnavailableString)
					} else {
						Button {
							randoFactoDatabase.saveToFavorites(fact: factText)
						} label: {
							Image(systemName: "heart")
								.accessibilityLabel("Favorite")
						}.padding()
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
		Menu {
			if !randoFactoDatabase.online && !userLoggedIn {
				Text("Offline")
			}
			if userLoggedIn {
				Section(header:
				Text((randoFactoDatabase.firebaseAuth.currentUser?.email)!)
				) {
					Menu("Favorite Facts List") {
						Button {
							showingFavoriteFactsList = true
						} label: {
							Text("View…")
						}
						Button {
							showingDeleteAllFavoriteFacts = true
						} label: {
							Text("Unfavorite All…")
						}
					}
					Menu("Account") {
						Button {
							randoFactoDatabase.logOutCurrentUser()
						} label: {
							Text("Logout")
						}
						if randoFactoDatabase.online {
							Button {
								showingDeleteAccount = true
							} label: {
								Text("Delete Account…")
							}
						}
					}
				}
			} else {
				if randoFactoDatabase.online {
					Button {
						authFormType = .logIn
					} label: {
						Text("Login…")
					}
					Button {
						authFormType = .signUp
					} label: {
						Text("Sign Up…")
					}
				}
			}
		} label: {
			Image(systemName: "person.circle")
				.accessibilityLabel("Account")
		}
		.disabled(notDisplayingFact)
		.help("Account")
	}

	// MARK: - Forms

	var authForm: some View {
		NavigationStack {
			Form {
				credentialFields
				if let errorText = credentialErrorText {
					HStack {
						Image(systemName: "exclamationmark.triangle")
						Text(errorText)
							.font(.system(size: 18))
							.lineLimit(5)
							.multilineTextAlignment(.center)
							.padding()
					}
					.foregroundColor(.red)
				}
			}
			.formStyle(.grouped)
			.padding(.horizontal)
			.keyboardShortcut(.defaultAction)
			.navigationTitle(authFormType == .signUp ? "Sign Up" : "Login")
#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
#endif
			.frame(minWidth: 400, minHeight: 400)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismissAuthForm()
					} label: {
						Text("Cancel")
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button {
						if authFormType == .signUp {
							randoFactoDatabase.signUp(email: email, password: password) { error in
								if let error = error {
									showError(error: error)
								} else {
									dismissAuthForm()
								}
							}
						} else {
							randoFactoDatabase.logIn(email: email, password: password) { error in
								if let error = error {
									showError(error: error)
								} else {
									dismissAuthForm()
								}
							}
						}
					} label: {
						Text(authFormType == .signUp ? "Sign Up" : "Login")
					}
					.disabled(email.isEmpty || password.isEmpty)
				}
			}
		}
	}

	// MARK: - Credential Fields

	var credentialFields: some View {
		Section {
			HStack {
				TextField("Email", text: $email)
					.textContentType(.username)
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
			await randoFactoDatabase.loadFavoriteFactsForCurrentUser()
			factGenerator.generateRandomFact()
		}
	}

	func dismissAuthForm() {
		email = String()
		password = String()
		credentialErrorText = nil
		authFormType = nil
	}

	// MARK: - Error Handling

	func showError(error: Error) {
		#if os(macOS)
		NSSound.beep()
		#elseif os(iOS)
		haptics.notificationOccurred(.error)
		#endif
		let nsError = error as NSError
		print("Error: \(nsError)")
		// Check the error code to choose which error to show.
		switch nsError.code {
				// Network errors
			case -1009:
				errorToShow = .noInternet
				// Fact data errors
			case 33000...33999 /*HTTP response code + 33000 to add 33 (FD) to the beginning*/:
				errorToShow = .httpResponseError(domain: nsError.domain)
			case 423:
				errorToShow = .noFactText
			case 523:
				errorToShow = .factDataError
			case 17014:
				// Database errors
				authFormType = .logIn
				errorToShow = .userDeletionFailed(reason: "It's been too long since you last logged in. Please re-log in and try deleting your account again.")
			case 17052:
				errorToShow = .randoFactoDatabaseQuotaExceeded
				// Other errors
			default:
				errorToShow = .unknown(reason: nsError.localizedDescription)
		}
		// Show the error in the log in/sign up dialog if they're open, otherwise show it as an alert.
		if authFormType != nil {
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

	func factGeneratorWillCheckFactForInappropriateWords(_ generator: FactGenerator) {
		factText = screeningString
	}

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String) {
		factText = fact
	}

	func factGeneratorDidFailToGenerateFact(_ generator: FactGenerator, error: Error) {
		factText = factUnavailableString
		showError(error: error)
	}
}

extension ContentView {

	// MARK: - RandoFacto Database Delegate - Network Enable/Disable

	func randoFactoDatabaseNetworkEnableDidFail(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseNetworkDisableDidFail(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	// MARK: - RandoFacto Database Delegate - Favorites Loading

	func randoFactoDatabaseLoadingDidFail(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	// MARK: - RandoFacto Database Delegate - Favorites Management

	func randoFactoDatabaseDidFailToAddFavorite(_ database: RandoFactoDatabase, fact: String, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToDeleteFavorite(_ database: RandoFactoDatabase, fact: String, error: Error) {
		showError(error: error)
	}

	// MARK: - RandoFacto Database Delegate - Account

	func randoFactoDatabaseDidFailToDeleteUser(_ database: RandoFactoDatabase, error: Error) {
		showError(error: error)
	}

	func randoFactoDatabaseDidFailToLogOutUser(_ database: RandoFactoDatabase, userEmail: String, error: Error) {
		showError(error: error)
	}
}

#Preview {
	ContentView()
}
