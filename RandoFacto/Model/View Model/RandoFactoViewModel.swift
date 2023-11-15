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

	// The fact generator.
	var factGenerator = FactGenerator()

	// MARK: - Properties - Strings

	// The text to display in the fact text view.
	@Published var factText: String = String()

	// The text to display in the authentication error label in the authentication (login/signup/password change) dialogs.
	@Published var authenticationErrorText: String? = nil

	// MARK: - Properties - Integers

	// Whether to display one of the user's favorite facts or generate a random fact when the app launches. This setting resets to 0 (Random Fact), and is hidden, when the user logs out or deletes their account.
	@AppStorage("initialFact") var initialFact: Int = 0

	// MARK: - Properties - Pages

	// The page currently selected in the sidebar/top-level view. On macOS, the settings view is accessed by the Settings option in the app menu instead of as a page.
	@Published var selectedPage: Page? = .randomFact

	// MARK: - Properties - Authentication Form Type

	// The authentication form to display, or nil if none are to be displayed.
	@Published var authenticationFormType: Authentication.FormType? = nil

	// MARK: - Properties - Network Error

	// The error to show to the user as an alert or in the authentication dialog.
	@Published var errorToShow: NetworkError?

	// MARK: - Properties - Account Deletion Stage

	// The current stage of user deletion. Deleting a user deletes their favorite facts and reference first, then their actual account. If the data deletion is successful but deletion of the account itself fails, the user's reference is put back.
	@Published var userDeletionStage: User.AccountDeletionStage? = nil

	// MARK: - Properties - Booleans

	// Whether an error alert is displayed.
	@Published var showingErrorAlert: Bool = false

	// Whether the "delete account" alert is displayed.
	@Published var showingDeleteAccount: Bool = false

	// Whether the "delete all favorite facts" alert is displayed.
	@Published var showingDeleteAllFavoriteFacts: Bool = false

	// Whether the AuthenticationFormView should show a confirmation that a password reset email has been sent to the entered email address.
	@Published var showingResetPasswordEmailSent: Bool = false

	// Whether the device is online.
	@Published var online: Bool = false

	// Whether an authentication request is in progress.
	@Published var isAuthenticating: Bool = false

	// Whether the fact text view is displaying something other than a fact (i.e., a loading or error message).
	var notDisplayingFact: Bool {
		return factText.isEmpty || factText == generatingString
	}

	// Whether the displayed fact is saved as a favorite.
	var displayedFactIsSaved: Bool {
		return !favoriteFacts.filter({$0.text == factText}).isEmpty
	}

	// Whether a user is logged in.
	var userLoggedIn: Bool {
		return firebaseAuthentication.currentUser != nil
	}

	// MARK: - Properties - Favorite Facts Array

	// The favorite facts loaded from the current user's Firestore database. Storing the data in this array makes getting favorite facts easier than getting the corresponding Firestore data each time, which could cause errors.
	@Published var favoriteFacts: [FavoriteFact] = []

	// MARK: - Properties - Network Monitor

	// Observes changes to the device's network connection to tell the app whether it should run in online or offline mode.
	private var networkPathMonitor = NWPathMonitor()

	// MARK: - Properties - Firebase

	// The current user's Firestore database.
	private var firestore = Firestore.firestore()

	// Listens for changes to the references for registrered users.
	var userListener: ListenerRegistration? = nil

	// Listens for changes to the current user's favorite facts.
	var favoriteFactsListener: ListenerRegistration? = nil

	// Used to get the current user or to perform authentication tasks, such as to login, logout, or delete an account.
	@Published var firebaseAuthentication = Authentication.auth()

	// MARK: - Properties - Errors

	// The error logged if the RandoFacto database is unable to get the document (data) from the corresponding favorite fact QuerySnapshot.
	private let favoriteFactReferenceError = NSError(domain: "Favorite fact reference not found", code: 144)

	// MARK: - Initialization

	// This initializer sets up the network path monitor and Firestore listeners, and displays a fact to the user.
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

	// This method configures the network path monitor's path update handler, which tells the app to enable or disable online mode, which shows or hides internet-connection-required UI based on network connection.
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

	// This method tries to access a random facts API URL and parse JSON data it gives back. It then feeds the fact through another API URL to check if it contains inappropriate words. We do it this way so we don't have to include inappropriate words in the app/code itself. If everything is successful, the fact is displayed to the user, or if an error occurs, it's logged.
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

	// This method asynchronously loads all the favorite facts associated with the current user. Firestore doesn't have a way to associate data with the user that created it, so we have to add a "user" key to each favorite fact so when a user deletes their account, their favorite facts, but no one else's, are also deleted.
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

	// This method updates the app's favorite facts list with snapshot's data.
	func updateFavoriteFactsList(from snapshot: QuerySnapshot, completionHandler: @escaping (() -> Void)) {
		DispatchQueue.main.async { [self] in
			// 1. Try to replace the data in favoriteFacts with snapshot's data by decoding it to a FavoriteFact object.
			do {
				// compactMap is marked throws so you can call throwing functions in its closure. Errors are then "rethrown" so the catch block of this do statement can handle them.
				favoriteFacts = try snapshot.documents.compactMap { document in
					// data(as:) handles the decoding of the data, so we don't need to use a Decoder object.
					return try document.data(as: FavoriteFact.self)
				}
			} catch {
				// 2. If that fails, log an error.
				showError(error)
			}
			completionHandler()
		}
	}

	// MARK: - Favorite Facts - Get Random Favorite Fact

	// This method gets a random fact from the favorite facts list and returns it.
	func getRandomFavoriteFact() -> String {
		return favoriteFacts.randomElement()?.text ?? factUnavailableString
	}

	// MARK: - Favorite Facts - Unavailable Handler

	// This method switches the current page from favoriteFacts to randomFact if a user logs out or is being deleted.
	func dismissFavoriteFacts() {
		if (!userLoggedIn || userDeletionStage != nil) && selectedPage == .favoriteFacts {
			DispatchQueue.main.async { [self] in
				selectedPage = .randomFact
			}
		}
	}

	// MARK: - Favorite Facts - Saving/Deleting

	// This method saves fact to the RandoFacto database.
	func saveToFavorites(factText: String) {
		// 1. Make sure the fact doesn't already exist and that the current user has an email (who would have an account but no email?!).
		guard let email = firebaseAuthentication.currentUser?.email else { return }
		let fact = FavoriteFact(text: factText, user: email)
		guard !favoriteFacts.contains(fact) else { return }
		// 2. Create a FavoriteFact object with the fact text and the current user's email, and try to create a new document with that data in the favorite facts Firestore collection.
		do {
			try firestore.collection(favoritesCollectionName).addDocument(from: fact)
		} catch {
			showError(error)
		}
	}

	// This method finds fact in the database and deletes it.
	func deleteFromFavorites(factText: String) {
		// 1. Get facts that match the given fact (there should only be 1).
		DispatchQueue.main.async { [self] in
			firestore.collection(favoritesCollectionName)
				.whereField(factTextKeyName, isEqualTo: factText)
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

	// This method gets the data from snapshot and deletes it.
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

	// This method sets up the app to listen for changes to registered user references. The email addresses and IDs of registered users get added to a Firestore collection called "users" when they signup, because Firebase doesn't have an ability to immediately notify the app of creations/deletions of accounts.
	func addRegisteredUsersHandler() {
		DispatchQueue.main.async { [self] in
			guard let currentUser = firebaseAuthentication.currentUser, let email = currentUser.email else {
				logoutMissingUser()
				return
			}
			userListener = firestore.collection(usersCollectionName)
				.whereField(emailKeyName, isEqualTo: email)
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
		let userReference = User.Reference(email: email)
		do {
			try firestore.collection(usersCollectionName).document(id).setData(from: userReference)
			completionHandler(nil)
		} catch {
			completionHandler(error)
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

	// This method sends a password reset email to email. The message body is customized in RandoFacto's Firebase console.
	func sendPasswordReset(toEmail email: String) {
		firebaseAuthentication.sendPasswordReset(withEmail: email, actionCodeSettings: ActionCodeSettings(), completion: { [self] error in
			if let error = error {
				showError(error)
			} else {
				showingResetPasswordEmailSent = true
			}
		})
	}

	// This method updates the current user's password to newPassword.
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

	// This method logs out the current user after deletion or if their reference goes missing. If the account itself still exists, logging in will put the missing reference back.
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

	// This method deletes the current user's favorite facts, their reference, and then their account.
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

	// This method shows error's localizedDescription as an alert or in the authentication form.
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
