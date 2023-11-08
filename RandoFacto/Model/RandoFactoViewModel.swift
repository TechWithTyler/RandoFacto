//
//  RandoFactoViewModel.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase
import Network

class RandoFactoViewModel: ObservableObject {

	// MARK: - Properties - Fact Generator

	var factGenerator = FactGenerator()

	// MARK: - Properties - Strings

	// The text to display in the fact text label.
	@Published var factText: String = String()

	// Displayed when generating a random fact.
	let generatingString = "Generating random fact…"

	// Displayed when a FactGenerator error occurs.
	let factUnavailableString = "Fact unavailable"

	// The text to display in the credential error label in the login/signup dialogs.
	@Published var credentialErrorText: String? = nil

	// The collection name of the favorite facts collection in a user's Firestore database.
	private let favoritesCollectionName = "favoriteFacts"

	// The key name of a fact's text.
	private let factTextKeyName = "fact"

	// The key name of a fact's associated user.
	private let userKeyName = "user"

	// MARK: - Properties - Integers

	@Published var selectedTab: Tab? = .randomFact

	// MARK: - Properties - Network Error

	// The error to show to the user as an alert or in the login/signup dialog.
	@Published var errorToShow: NetworkError?

	// MARK: - Properties - Authentication Form Type

	// The authentication form to display, or nil if neither are to be displayed.
	@Published var authenticationFormType: AuthenticationFormType? = nil

	// MARK: - Properties - Booleans

	@Published var showingErrorAlert: Bool = false

	@Published var showingDeleteAccount: Bool = false

	@Published var showingDeleteAllFavoriteFacts: Bool = false

	@Published var showingResetPasswordEmailSent: Bool = false

	// Whether the device is online.
	@Published var online = false

	var notDisplayingFact: Bool {
		return factText.isEmpty || factText == generatingString
	}

	var userLoggedIn: Bool {
		guard let firebaseAuthentication = firebaseAuthentication else { return false }
		return firebaseAuthentication.currentUser != nil
	}

	// MARK: - Properties - Favorite Facts Array

	// The favorite facts loaded from the current user's Firestore database.
	@Published var favoriteFacts: [String] = []

	// MARK: - Properties - Network Monitor

	// Observes changes to the device's network connection to tell the app whether it should run in online or offline mode.
	private var networkPathMonitor = NWPathMonitor()

	// MARK: - Properties - Firebase

	// The current user's Firestore database.
	private var firestore: Firestore?

	// Used to get the current user or to signup, login, logout, or delete a user.
	@Published var firebaseAuthentication: Auth?

	// MARK: - Properties - Errors

	// The error logged if the RandoFacto database is unable to get the document (data) from the corresponding QuerySnapshot.
	private let refError = NSError(domain: "Favorite fact reference not found", code: 144)

	// MARK: - Initialization

	init() {
		// 1. Configure Firebase.
		configureFirebase()
		// 2. Configure the network path monitor.
		configureNetworkPathMonitor()
		// 3. Load all the favorite facts into the app.
		Task {
			await loadFavoriteFactsForCurrentUser()
		}
		// 4. Generate a random fact.
		generateRandomFact()
	}

	func configureFirebase() {
		// 1. Make sure the GoogleService-Info.plist file is present in the app bundle.
		guard let googleServicePlist = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") else {
			fatalError("Firebase configuration file not found")
		}
		// 2. Create a FirebaseAppOptions object with the API key.
		guard let options = FirebaseOptions(contentsOfFile: googleServicePlist.path) else {
			fatalError("Failed to load options from configuration file")
		}
		options.apiKey = firebaseApiKey
		// 3. Initialize Firebase with the custom options.
		FirebaseApp.configure(options: options)
		firestore = Firestore.firestore()
		firebaseAuthentication = Auth.auth()
		guard let firestore = firestore else {
			fatalError("Couldn't initialize Firestore")
		}
		let settings = FirestoreSettings()
		settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
		firestore.settings = settings
	}

	// MARK: - Network Path Monitor Configuration

	// This method configures the network path monitor's path update handler, which tells the app to enable or disable online mode based on network connection.
	func configureNetworkPathMonitor() {
		networkPathMonitor.pathUpdateHandler = {
			[self] path in
			if path.status == .satisfied {
				goOnline()
			} else {
				goOffline()
			}
		}
		let dispatchQueue = DispatchQueue(label: "Network Monitor")
		networkPathMonitor.start(queue: dispatchQueue)
	}

	// This method enables online mode.
	func goOnline() {
		guard let firestore = firestore else { return }
		firestore.enableNetwork {
			[self] error in
			if let error = error {
				showError(error: error)
			} else {
				// Updating a published property must be done on the main thread, so we use DispatchQueue.main.async to run any code that sets such properties.
				DispatchQueue.main.async { [self] in
					online = true
				}
			}
		}
	}

	// This method enables offline mode.
	func goOffline() {
		guard let firestore = firestore else { return }
		firestore.disableNetwork {
			[self] error in
			if let error = error {
				showError(error: error)
			} else {
				DispatchQueue.main.async { [self] in
					online = false
				}
			}
		}
	}

	// MARK: - Fact Generation

	func generateRandomFact() {
		// Asks the fact generator to perform its URL requests to generate a random fact.
		factGenerator.generateRandomFact {
			DispatchQueue.main.async { [self] in
				factText = generatingString
			}
		} completionHandler: { [self]
			fact, error in
			if let fact = fact {
				DispatchQueue.main.async { [self] in
					factText = fact
				}
			} else if let error = error {
				DispatchQueue.main.async { [self] in
					factText = factUnavailableString
				}
				showError(error: error)
			}
		}
	}

	// MARK: - Authentication

	// This method loads the user's favorite facts if authentication is successful. Otherwise, it logs an error.
	func handleAuthenticationRequest(error: Error?, successHandler: @escaping ((Bool) -> Void)) {
		DispatchQueue.main.async { [self] in
			if let error = error {
				showError(error: error)
				successHandler(false)
			} else {
				Task {
					await self.loadFavoriteFactsForCurrentUser()
				}
				successHandler(true)
			}
		}
	}

	// This method takes the user's credentials and tries to log them into their RandoFacto database account.
	func login(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
		DispatchQueue.main.async { [self] in
			firebaseAuthentication?.signIn(withEmail: email, password: password) { [self] result, error in
				handleAuthenticationRequest(error: error, successHandler: successHandler)
			}
		}
	}

	// This method takes the user's credentials and tries to sign them up for a RandoFacto database account.
	func signup(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
		DispatchQueue.main.async { [self] in
			firebaseAuthentication?.createUser(withEmail: email, password: password) { result, error in
				self.handleAuthenticationRequest(error: error, successHandler: successHandler)
			}
		}
	}

	func resetPassword(email: String) {
		DispatchQueue.main.async { [self] in
			firebaseAuthentication?.sendPasswordReset(withEmail: email, actionCodeSettings: ActionCodeSettings()) { [self] error in
				if let error = error {
					showError(error: error)
				} else {
					showingResetPasswordEmailSent = true
				}
			}
		}
	}

	func updatePasswordForCurrentUser(newPassword: String) {
		guard let user = firebaseAuthentication?.currentUser else { return }
		DispatchQueue.main.async { [self] in
			user.updatePassword(to: newPassword) { [self] error in
				if let error = error {
					showError(error: error)
				}
			}
		}
	}

	// This method tries to logout the current user, clearing the app's favorite facts list if successful.
	func logoutCurrentUser() {
				do {
					DispatchQueue.main.async { [self] in
						favoriteFacts.removeAll()
					}
					try firebaseAuthentication?.signOut()
				} catch {
					showError(error: error)
				}
	}

	// This method logs out a user that has had their account deleted but is still logged into the app on its end.
	func logoutMissingUser() {
		DispatchQueue.main.async { [self] in
			firebaseAuthentication?.currentUser?.getIDTokenForcingRefresh(true) { [self] token, error in
				if let error = error {
					showError(error: error)
				} else {
					if token == nil {
						logoutCurrentUser()
						selectedTab = .randomFact
					}
				}
			}
		}
	}

	// MARK: - Delete User

	// This method deletes the current user.
	func deleteCurrentUser() {
		// 1. Make sure we can get the current user.
		guard let user = firebaseAuthentication?.currentUser else { return }
		// 2. Delete all their favorite facts.
		DispatchQueue.main.async { [self] in
			deleteAllFavoriteFactsForCurrentUser { [self] error in
				// 3. If that fails, log an error and don't continue deletion.
				if let error = error {
					showError(error: error)
				} else {
					// 4. Or if it succeeds, delete the current user.
					user.delete { [self] error in
						// 5. If that fails, log an error.
						if let error = error {
							showError(error: error)
						} else {
							// 6. If the user and all their favorite facts were successfully deleted, clear the favorite facts list and log the user out.
							DispatchQueue.main.async { [self] in
								favoriteFacts.removeAll()
							}
							logoutCurrentUser()
						}
					}
				}
			}
		}
	}

	// MARK: - Favorite Facts Loading

	// This method asynchronously loads all the favorite facts associated with the current user.
	func loadFavoriteFactsForCurrentUser() async {
		// 1. Make sure we can get the current user.
		guard let userEmail = firebaseAuthentication?.currentUser?.email else { return }
		DispatchQueue.main.async { [self] in
			// 2. Get the Firestore collection containing favorite facts.
			logoutMissingUser()
			firestore?.collection(favoritesCollectionName)
			// 3. FIlter the result to include only the current user's favorite facts.
				.whereField(userKeyName, isEqualTo: userEmail)
			// 4. Listen for any changes made to the favorite facts list on the Firebase end, such as by RandoFacto on another device.
				.addSnapshotListener(includeMetadataChanges: true) { [self] snapshot, error in
					// 5. Log any errors.
					if let error = error {
						showError(error: error)
					} else {
						// 6. If no data can be found, it's most likely due to a missing user, so log them out and return.
						guard let snapshot = snapshot else {
							return
						}
						// 7. If a change was successfully detected, update the app's favorite facts array.
						updateFavoriteFactsList(from: snapshot)
					}
				}
		}
	}

	// This method updates the app's favorite facts list with the given QuerySnapshot's data.
	func updateFavoriteFactsList(from snapshot: QuerySnapshot) {
		DispatchQueue.main.async { [self] in
			// 1. Clear the favorite facts list.
			favoriteFacts.removeAll()
		// 2. Go through each document (piece of data) in the snapshot.
			for favorite in snapshot.documents {
				// 3. If the data's "fact" key contains data, append it to the favorite facts list.
				if let fact = favorite.data()[factTextKeyName] as? String {
					DispatchQueue.main.async { [self] in
						favoriteFacts.append(fact)
					}
				} else {
					// 4. Otherwise, log an error. RandoFacto only gives the user safe facts that contain text--this error is only logged if a previously-saved favorite fact had its data removed, or if it was manually added to RandoFacto's Firestore.
					let loadError = NSError(domain: "\(favorite) doesn't appear to contain fact text!", code: 423)
					showError(error: loadError)
				}
			}
		}
	}

	// MARK: - Get Random Favorite Fact

	// This method gets a random fact from the favorite facts list and returns it.
	func getRandomFavoriteFact() -> String {
		logoutMissingUser()
		return favoriteFacts.randomElement()!
	}

	// MARK: - Favorites Management - Saving/Deleting

	// This method saves the given fact to the RandoFacto database.
	func saveToFavorites(fact: String) {
		// 1. Make sure the fact doesn't already exist and that the current user has an email (who would have an account but no email?!).
		guard !favoriteFacts.contains(fact), let userEmail = firebaseAuthentication?.currentUser?.email else { return }
		// 2. Create a dictionary containing the data that should be saved as a new document in the favorite facts Firestore collection.
		DispatchQueue.main.async { [self] in
			logoutMissingUser()
			let data: [String : String] = [
				factTextKeyName : fact,
				userKeyName : userEmail
			]
			// 3. Add the favorite fact to the database.
			firestore?.collection(favoritesCollectionName).addDocument(data: data) { [self] error in
				// 4. If that fails, log an error.
				if let error = error {
					showError(error: error)
				}
			}
		}
	}

	// This method finds the given fact in the database and deletes it.
	func deleteFromFavorites(fact: String) {
		// 1. Get facts that match the given fact (there should only be 1).
		DispatchQueue.main.async { [self] in
			logoutMissingUser()
			firestore?.collection(favoritesCollectionName)
				.whereField(factTextKeyName, isEqualTo: fact)
				.getDocuments(source: .cache) { [self] snapshot, error in
					// 2. If that fails, log an error.
				if let error = error {
					showError(error: error)
				} else {
					// 3. Or if we're error-free, get the snapshot and delete.
					getFavoriteFactSnapshotAndDelete(snapshot, fact: fact)
				}
			}
		}
	}

	// This method gets the data from the given snapshot and deletes it.
	func getFavoriteFactSnapshotAndDelete(_ snapshot: QuerySnapshot?, fact: String) {
		DispatchQueue.main.async { [self] in
		// 1. Make sure the snapshot and the corresponding data is there.
		if let snapshot = snapshot, let ref = snapshot.documents.first {
			// 2. Delete the corresponding document.
			firestore?.collection(favoritesCollectionName).document(ref.documentID).delete { [self]
				error in
				// 3. Log an error if deletion fails.
				if let error = error {
					showError(error: error)
				}
			}
		} else {
			// 4. If we can't get the snapshot or corresponding data, log an error.
			showError(error: refError)
		}
		}
	}

	// This method deletes all favorite facts from the database.
	func deleteAllFavoriteFactsForCurrentUser(completionHandler: @escaping ((Error?) -> Void)) {
		// 1. Go through all favorite facts.
		let group = DispatchGroup()
		logoutMissingUser()
		for fact in favoriteFacts {
			group.enter()
			// 2. Get the document corresponding to the fact.
			firestore?.collection(favoritesCollectionName).whereField(factTextKeyName, isEqualTo: fact).getDocuments(source: .cache) { [self] snapshot, error in
				defer {
					group.leave()
				}
				// 3. If an error occurs, log it and cancel deletion.
				if let error = error {
					completionHandler(error)
					return
				}
				// 4. If we can't get the snapshot or corresponding data, log an error and cancel deletion.
				guard let snapshot = snapshot, let ref = snapshot.documents.first else {
					completionHandler(refError)
					return
				}
				// 5. Try to delete the fact, logging an error if it fails.
				firestore?.collection(favoritesCollectionName).document(ref.documentID).delete { error in
					if let error = error {
						completionHandler(error)
					}
				}
			}
		}
		// 6. Leave the dispatch group.
		group.notify(queue: DispatchQueue.main) {
			completionHandler(nil)
		}
	}

	// MARK: - Error Handling

	func showError(error: Error) {
		DispatchQueue.main.async { [self] in
			let nsError = error as NSError
			print("Error: \(nsError)")
			// Check the error code to choose which error to show.
			switch nsError.code {
					// Network errors
				case -1009:
					errorToShow = .noInternet
					// Fact data errors
				case 33000...33999 /*HTTP response code + 33000 to add 33 (FD) to the beginning*/:
					errorToShow = .badHTTPResponse(domain: nsError.domain)
				case 423:
					errorToShow = .noFactText
				case 523:
					errorToShow = .factDataError
				case 17014:
					// Database errors
					authenticationFormType = .login
					errorToShow = .userDeletionFailed(reason: "It's been too long since you last logged in. Please re-login and try deleting your account again.")
				case 17052:
					errorToShow = .randoFactoDatabaseQuotaExceeded
					// Other errors
				default:
					errorToShow = .unknown(reason: nsError.localizedDescription)
			}
			// Show the error in the login/signup dialog if they're open, otherwise show it as an alert.
			if authenticationFormType != nil {
				credentialErrorText = errorToShow?.errorDescription
			} else {
				showingErrorAlert = true
			}
		}
	}


}
