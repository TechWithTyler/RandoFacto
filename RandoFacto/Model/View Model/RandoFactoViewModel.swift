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

	// The text to display in the credential error label in the authentication dialogs.
	@Published var authenticationErrorText: String? = nil

	// MARK: - Properties - Integers

	// Whether to display one of the user's favorite facts or generate a random fact when the app launches. This setting resets to 0 (Random Fact) when the user logs out or deletes their account.
	@AppStorage("initialFact") var initialFact: Int = 0

	// MARK: - Properties - Pages

	// The page currently selected in the sidebar/top-level view. On macOS, the settings view is accessed by the Settings option in the app menu instead as a page.
	@Published var selectedPage: Page? = .randomFact

	// MARK: - Properties - Network Error

	// The error to show to the user as an alert or in the login/signup dialog.
	@Published var errorToShow: NetworkError?

	// MARK: - Properties - Authentication Form Type

	// The authentication form to display, or nil if neither are to be displayed.
	@Published var authenticationFormType: Authentication.FormType? = nil

	// MARK: - Properties - Account Deletion Stage

	@Published var userDeletionStage: User.DeletionStage? = nil

	// MARK: - Properties - Booleans

	@Published var showingErrorAlert: Bool = false

	@Published var showingDeleteAccount: Bool = false

	@Published var showingDeleteAllFavoriteFacts: Bool = false

	@Published var showingResetPasswordEmailSent: Bool = false

	// Whether the device is online.
	@Published var online: Bool = false

	// Whether an authentication request is in progress.
	@Published var isAuthenticating: Bool = false

	var notDisplayingFact: Bool {
		return factText.isEmpty || factText == generatingString
	}

	var userLoggedIn: Bool {
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
	private var firestore = Firestore.firestore()

	var userListener: ListenerRegistration? = nil

	var favoriteFactsListener: ListenerRegistration? = nil

	// Used to get the current user or to signup, login, logout, or delete a user.
	@Published var firebaseAuthentication = Authentication.auth()

	// MARK: - Properties - Errors

	// The error logged if the RandoFacto database is unable to get the document (data) from the corresponding favorite fact QuerySnapshot.
	private let favoriteFactReferenceError = NSError(domain: "Favorite fact reference not found", code: 144)

	// MARK: - Initialization

	init() {
		// 1. Configure the network path monitor.
		configureNetworkPathMonitor()
		// 2. Load all the favorite facts into the app.
		addRegisteredUsersHandler()
		loadFavoriteFactsForCurrentUser { [self] in
			guard notDisplayingFact else { return }
			// 3. Generate a random fact.
			if initialFact == 0 || favoriteFacts.isEmpty || !userLoggedIn {
				generateRandomFact()
			} else {
				DispatchQueue.main.async { [self] in
					factText = getRandomFavoriteFact()
				}
			}
		}
	}

	// MARK: - Network - Path Monitor Configuration

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

	// MARK: - Network - Online

	// This method enables online mode.
	func goOnline() {
		firestore.enableNetwork {
			[self] error in
			if let error = error {
				showError(error)
			} else {
				// Updating a published property must be done on the main thread, so we use DispatchQueue.main.async to run any code that sets such properties.
				DispatchQueue.main.async { [self] in
					online = true
				}
			}
		}
	}

	// MARK: - Network - Offline

	// This method enables offline mode.
	func goOffline() {
		firestore.disableNetwork {
			[self] error in
			if let error = error {
				showError(error)
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
				showError(error)
			}
		}
	}

}

extension RandoFactoViewModel {

	// MARK: - Favorite Facts - Loading

	// This method asynchronously loads all the favorite facts associated with the current user.
	func loadFavoriteFactsForCurrentUser(completionHandler: @escaping (() -> Void)) {
		DispatchQueue.main.async { [self] in
			guard userLoggedIn else {
				completionHandler()
				return
			}
			// 1. Make sure we can get the current user.
			guard let user = firebaseAuthentication.currentUser, let userEmail = user.email else {
				completionHandler()
				return }
			// 2. Get the Firestore collection containing favorite facts.
			favoriteFactsListener = firestore.collection(favoritesCollectionName)
			// 3. FIlter the result to include only the current user's favorite facts.
				.whereField(userKeyName, isEqualTo: userEmail)
			// 4. Listen for any changes made to the favorite facts list on the Firebase end, such as by RandoFacto on another device.
				.addSnapshotListener(includeMetadataChanges: true) { [self] snapshot, error in
					// 5. Log any errors.
					if let error = error {
						showError(error)
						completionHandler()
					} else {
						// 6. If no data can be found, return.
						guard let snapshot = snapshot else {
							completionHandler()
							return
						}
						// 7. If a change was successfully detected, update the app's favorite facts array.
						updateFavoriteFactsList(from: snapshot, completionHandler: completionHandler)
					}
				}
		}
	}

	// This method updates the app's favorite facts list with the given QuerySnapshot's data.
	func updateFavoriteFactsList(from snapshot: QuerySnapshot, completionHandler: @escaping (() -> Void)) {
		DispatchQueue.main.async { [self] in
			// 1. Clear the favorite facts list.
			favoriteFacts.removeAll()
			// 2. Go through each document (piece of data) in the snapshot.
			for favorite in snapshot.documents {
				// 3. If the data's "fact" key contains data, append it to the favorite facts list.
				if let fact = favorite.data()[factTextKeyName] as? String {
					favoriteFacts.append(fact)
				} else {
					// 4. Otherwise, log an error. RandoFacto only gives the user safe facts that contain text--this error is only logged if a previously-saved favorite fact had its data removed, or if it was manually added to RandoFacto's Firestore.
					let loadError = NSError(domain: "\(favorite) doesn't appear to contain fact text!", code: 423)
					showError(loadError)
				}
			}
			completionHandler()
		}
	}

	// MARK: - Favorite Facts - Get Random Favorite Fact

	// This method gets a random fact from the favorite facts list and returns it.
	func getRandomFavoriteFact() -> String {
		return favoriteFacts.randomElement()!
	}

	// MARK: - Favorite Facts - Unavailable Handler

	func dismissFavoriteFacts() {
		if (!userLoggedIn || userDeletionStage != nil) && selectedPage == .favoriteFacts {
			DispatchQueue.main.async { [self] in
				selectedPage = .randomFact
			}
		}
	}

	// MARK: - Favorite Facts - Saving/Deleting

	// This method saves the given fact to the RandoFacto database.
	func saveToFavorites(fact: String) {
		// 1. Make sure the fact doesn't already exist and that the current user has an email (who would have an account but no email?!).
		guard !favoriteFacts.contains(fact), let userEmail = firebaseAuthentication.currentUser?.email else {
			return }
		// 2. Create a dictionary containing the data that should be saved as a new document in the favorite facts Firestore collection.
		DispatchQueue.main.async { [self] in
			let data: [String : String] = [
				factTextKeyName : fact,
				userKeyName : userEmail
			]
			// 3. Add the favorite fact to the database.
			firestore.collection(favoritesCollectionName).addDocument(data: data) { [self] error in
				// 4. If that fails, log an error.
				if let error = error {
					showError(error)
				}
			}
		}
	}

	// This method finds the given fact in the database and deletes it.
	func deleteFromFavorites(fact: String) {
		// 1. Get facts that match the given fact (there should only be 1).
		DispatchQueue.main.async { [self] in
			firestore.collection(favoritesCollectionName)
				.whereField(factTextKeyName, isEqualTo: fact)
				.getDocuments(source: .cache) { [self] snapshot, error in
					// 2. If that fails, log an error.
					if let error = error {
						showError(error)
					} else {
						// 3. Or if we're error-free, get the snapshot and delete.
						getFavoriteFactSnapshotAndDelete(snapshot)
					}
				}
		}
	}

	// This method gets the data from the given snapshot and deletes it.
	func getFavoriteFactSnapshotAndDelete(_ snapshot: QuerySnapshot?) {
		DispatchQueue.main.async { [self] in
			// 1. Make sure the snapshot and the corresponding data is there.
			if let snapshot = snapshot, let ref = snapshot.documents.first {
				// 2. Delete the corresponding document.
				firestore.collection(favoritesCollectionName).document(ref.documentID).delete { [self]
					error in
					// 3. Log an error if deletion fails.
					if let error = error {
						showError(error)
					}
				}
			} else {
				// 4. If we can't get the snapshot or corresponding data, log an error.
				showError(favoriteFactReferenceError)
			}
		}
	}

	// This method deletes all favorite facts from the database.
	func deleteAllFavoriteFactsForCurrentUser(forUserDeletion deletingUser: Bool = false, completionHandler: @escaping ((Error?) -> Void)) {
		guard let userEmail = firebaseAuthentication.currentUser?.email else {
			return }
		let group = DispatchGroup()
		var deletionError: Error?
		group.enter()
		firestore.collection(favoritesCollectionName)
			.whereField(userKeyName, isEqualTo: userEmail)
			.getDocuments(source: deletingUser ? .server : .cache) { [self] (snapshot, error) in
				if let error = error {
					defer {
						group.leave()
					}
					deletionError = error
				} else {
					defer {
						group.leave()
					}
					for document in snapshot!.documents {
						firestore.collection(favoritesCollectionName).document(document.documentID).delete { error in
							if let error = error {
								defer {
									group.leave()
								}
								deletionError = error
							}
						}
					}
				}
			}
		group.notify(queue: .main) {
			completionHandler(deletionError)
		}
	}

}

extension RandoFactoViewModel {

	// MARK: - Authentication - Registered Users Handler

	func addRegisteredUsersHandler() {
		DispatchQueue.main.async { [self] in
			guard let currentUser = firebaseAuthentication.currentUser, let email = currentUser.email else {
				logoutMissingUser()
				return
			}
			userListener = firestore.collection(usersCollectionName)
				.whereField(userKeyName, isEqualTo: email)
				.addSnapshotListener(includeMetadataChanges: true) { [self] documentSnapshot, error in
					if let error = error {
						showError(error)
					} else {
						// Logout the user if they're deleted.
						if let snapshot = documentSnapshot, (snapshot.isEmpty || snapshot.documents.isEmpty) {
							logoutMissingUser()
						} else if documentSnapshot == nil {
							logoutMissingUser()
						}
					}
				}
		}
	}

	// MARK: - Authentication - Signup/Login Request Handler

	// This method loads the user's favorite facts if authentication is successful. Otherwise, it logs an error.
	func handleAuthenticationRequest(with result: AuthDataResult?, error: Error?, isSignup: Bool, successHandler: @escaping ((Bool) -> Void)) {
		let successBlock: (() -> Void) = { [self] in
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [self] in
				loadFavoriteFactsForCurrentUser { [self] in
					addRegisteredUsersHandler()
					successHandler(true)
				}
			}
		}
		if let error = error {
			showError(error)
			successHandler(false)
		} else {
			if isSignup {
				// Add the user reference
				if let email = result?.user.email, let id = result?.user.uid {
					addUserReference(email: email, id: id) { [self] error in
						if let error = error {
							showError(error)
							successHandler(false)
						} else {
							successBlock()
						}
					}
				} else {
					successHandler(false)
				}
			} else {
				// If a user exists but their reference doesn't, add it.
				if let email = result?.user.email, let id = result?.user.uid {
					addMissingUserReference(email: email, id: id) { [self] error in
						if let error = error {
							showError(error)
							successHandler(false)
						} else {
							successBlock()
						}
					}
				} else {
					successHandler(false)
				}
			}
		}
	}

	// MARK: - Authentication - User References

	// This method adds a reference for the current user once they signup or login and such reference is missing.
	func addUserReference(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
		let data: [String : String] = [
			userKeyName : email
		]
		firestore.collection(usersCollectionName)
			.document(id).setData(data) {
				error in
				if let error = error {
					completionHandler(error)
				} else {
					completionHandler(nil)
				}
			}
	}

	// This method checks for the current user's reference and adds it if it doesn't exist.
	func addMissingUserReference(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
		firestore.collection(usersCollectionName)
			.getDocuments(source: .server) { [self] snapshot, error in
				if let error = error {
					completionHandler(error)
				} else {
					if let snapshot = snapshot, (snapshot.isEmpty || snapshot.documents.isEmpty) {
						addUserReference(email: email, id: id) { error in
							if let error = error {
								completionHandler(error)
							} else {
								completionHandler(nil)
							}
						}
					} else {
						completionHandler(nil)
					}
				}
			}
	}

	// MARK: - Authentication - Signup

	// This method takes the user's credentials and tries to sign them up for a RandoFacto database account.
	func signup(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
		firebaseAuthentication.createUser(withEmail: email, password: password) { [self] result, error in
			self.handleAuthenticationRequest(with: result, error: error, isSignup: true, successHandler: successHandler)
		}
	}

	// MARK: - Authentication - Login

	// This method takes the user's credentials and tries to log them into their RandoFacto database account.
	func login(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
		firebaseAuthentication.signIn(withEmail: email, password: password) { [self] result, error in
			handleAuthenticationRequest(with: result, error: error, isSignup: false, successHandler: successHandler)
		}
	}

	// MARK: - Authentication - Password Reset/Update

	func sendPasswordReset(toEmail email: String) {
		firebaseAuthentication.sendPasswordReset(withEmail: email, actionCodeSettings: ActionCodeSettings(), completion: { [self] error in
			if let error = error {
				showError(error)
			} else {
				showingResetPasswordEmailSent = true
			}
		})
	}

	func updatePasswordForCurrentUser(to newPassword: String, completionHandler: @escaping ((Bool) -> Void)) {
		guard let user = firebaseAuthentication.currentUser else { return }
		user.updatePassword(to: newPassword) { [self] error in
			if let error = error {
				showError(error)
				completionHandler(false)
			} else {
				completionHandler(true)
			}
		}
	}

	// MARK: - Authentication - Logout

	// This method tries to logout the current user, clearing the app's favorite facts list if successful.
	func logoutCurrentUser() {
		do {
			try firebaseAuthentication.signOut()
			DispatchQueue.main.async { [self] in
				favoriteFacts.removeAll()
			}
			initialFact = 0
			userListener?.remove()
			userListener = nil
			favoriteFactsListener?.remove()
			favoriteFactsListener = nil
		} catch {
			showError(error)
		}
	}

	func logoutMissingUser() {
		deleteAllFavoriteFactsForCurrentUser(forUserDeletion: true) { [self] error in
			if let error = error {
				showError(error)
				return
			} else {
				logoutCurrentUser()
			}
		}
	}

	// MARK: - Authentication - Delete User

	// This method deletes the current user.
	func deleteCurrentUser(completionHandler: @escaping (Error?) -> Void) {
		guard let user = firebaseAuthentication.currentUser else {
			let userNotFoundError = NSError(domain: "User not found", code: 545)
			completionHandler(userNotFoundError)
			return
		}
		userDeletionStage = .data
		deleteAllFavoriteFactsForCurrentUser(forUserDeletion: true) { [self] error in
			if let error = error {
				userDeletionStage = nil
				completionHandler(error)
			} else {
				DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [self] in
					userListener?.remove()
					userListener = nil
					firestore.collection(usersCollectionName)
						.document(user.uid).delete { [self] error in
							if let error = error {
								addRegisteredUsersHandler()
								userDeletionStage = nil
								completionHandler(error)
							} else {
								userDeletionStage = .account
							}
						}
					DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [self] in
						user.delete { [self] error in
							userDeletionStage = nil
							if let error = error {
								logoutMissingUser()
								addRegisteredUsersHandler()
								completionHandler(error)
								return
							} else {
								completionHandler(nil)
							}
						}
					}
				}
			}
		}
	}

}

extension RandoFactoViewModel {

	// MARK: - Error Handling

	func showError(_ error: Error) {
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
				case 14:
					// Database errors
					errorToShow = .randoFactoDatabaseServerDataRetrievalError
				case 17014:
					logoutCurrentUser()
					authenticationFormType = .login
					errorToShow = .tooLongSinceLastLogin
				case 17052:
					errorToShow = .randoFactoDatabaseQuotaExceeded
					// Other errors
				default:
					errorToShow = .unknown(reason: nsError.localizedDescription)
			}
			// Show the error in the login/signup dialog if they're open, otherwise show it as an alert.
			if authenticationFormType != nil {
				authenticationErrorText = errorToShow?.errorDescription
			} else {
				showingErrorAlert = true
			}
		}
	}

}
