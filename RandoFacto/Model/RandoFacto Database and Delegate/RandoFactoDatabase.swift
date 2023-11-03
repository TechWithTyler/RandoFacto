//
//  RandoFactoDatabase.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase
import Network

class RandoFactoDatabase: ObservableObject {

	// MARK: - Properties - Favorite Facts Array

	// The favorite facts loaded from the current user's Firestore database.
	@Published var favoriteFacts: [String] = []

	// MARK: - Properties - Error Delegate

	var errorDelegate: RandoFactoDatabaseErrorDelegate?

	// MARK: - Properties - Network Monitor

	// Observes changes to the device's network connection to tell the app whether it should run in online or offline mode.
	private var networkPathMonitor = NWPathMonitor()

	// Whether the device is online.
	@Published var online = false

	// MARK: - Properties - Firebase

	// The current user's Firestore database.
	private let firestore = Firestore.firestore()

	// Used to get the current user or to signup, login, logout, or delete a user.
	@Published var firebaseAuthentication = Auth.auth()

	// MARK: - Properties - Strings

	// The collection name of the favorite facts collection in a user's Firestore database.
	private let favoritesCollectionName = "favoriteFacts"

	// The key name of a fact's text.
	private let factTextKeyName = "fact"

	// The key name of a fact's associated user.
	private let userKeyName = "user"

	// MARK: - Properties - Errors

	// The error logged if the RandoFacto database is unable to get the document (data) from the corresponding QuerySnapshot.
	private let refError = NSError(domain: "Favorite fact reference not found", code: 144)

	// MARK: - Initialization

	init(errorDelegate: RandoFactoDatabaseErrorDelegate? = nil) {
		self.errorDelegate = errorDelegate
		configureNetworkPathMonitor()
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
		firestore.enableNetwork {
			[self] error in
			if let error = error {
				errorDelegate?.randoFactoDatabaseNetworkEnableDidFail(self, error: error)
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
		firestore.disableNetwork {
			[self] error in
			if let error = error {
				errorDelegate?.randoFactoDatabaseNetworkDisableDidFail(self, error: error)
			} else {
				DispatchQueue.main.async { [self] in
					online = false
				}
			}
		}
	}

	// MARK: - Authentication

	// This method loads the user's favorite facts if authentication is successful. Otherwise, it logs an error.
	func handleAuthenticationRequest(error: Error?, completionHandler: @escaping ((Error?) -> Void)) {
		if let error = error {
			completionHandler(error)
		} else {
			Task {
				await self.loadFavoriteFactsForCurrentUser()
			}
			completionHandler(nil)
		}
	}

	// This method takes the user's credentials and tries to log them into their RandoFacto database account.
	func login(email: String, password: String, completionHandler: @escaping ((Error?) -> Void)) {
		DispatchQueue.main.async { [self] in
			firebaseAuthentication.signIn(withEmail: email, password: password) { [self] result, error in
				handleAuthenticationRequest(error: error, completionHandler: completionHandler)
			}
		}
	}

	// This method takes the user's credentials and tries to sign them up for a RandoFacto database account.
	func signUp(email: String, password: String, completionHandler: @escaping ((Error?) -> Void)) {
		DispatchQueue.main.async { [self] in
			firebaseAuthentication.createUser(withEmail: email, password: password) { result, error in
				self.handleAuthenticationRequest(error: error, completionHandler: completionHandler)
			}
		}
	}

	// This method tries to logout the current user, clearing the app's favorite facts list if successful.
	func logoutCurrentUser() {
		DispatchQueue.main.async { [self] in
			if let userEmail = firebaseAuthentication.currentUser?.email {
				do {
					try firebaseAuthentication.signOut()
					favoriteFacts.removeAll()
				} catch {
					errorDelegate?.randoFactoDatabaseDidFailToLogoutUser(self, userEmail: userEmail, error: error)
				}
			}
		}
	}

	// This method logs out a user that has had their account deleted but is still logged into the app on its end.
	func logoutMissingUser() {
		firebaseAuthentication.currentUser?.getIDTokenForcingRefresh(true) { [self] token, error in
			if let error = error {
				errorDelegate?.randoFactoDatabaseLoadingDidFail(self, error: error)
			} else {
				if token == nil {
					logoutCurrentUser()
				}
			}
		}
	}

	// MARK: - Delete User

	// This method deletes the current user.
	func deleteCurrentUser() {
		// 1. Make sure we can get the current user.
		guard let user = firebaseAuthentication.currentUser else { return }
		// 2. Delete all their favorite facts.
		deleteAllFavoriteFactsForCurrentUser { [self] error in
			// 3. If that fails, log an error and don't continue deletion.
			if let error = error {
				errorDelegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
			} else {
				// 4. Or if it succeeds, delete the current user.
				user.delete { [self] error in
					// 5. If that fails, log an error.
					if let error = error {
						errorDelegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
					} else {
						// 6. If the user and all their favorite facts were successfully deleted, clear the favorite facts list and log the user out.
						favoriteFacts.removeAll()
						logoutCurrentUser()
					}
				}
			}
		}
	}

	// MARK: - Favorite Facts Loading

	// This method asynchronously loads all the favorite facts associated with the current user.
	func loadFavoriteFactsForCurrentUser() async {
		// 1. Make sure we can get the current user.
		guard let user = firebaseAuthentication.currentUser else { return }
		// 2. Get the Firestore collection containing favorite facts.
			DispatchQueue.main.async { [self] in
				firestore.collection(favoritesCollectionName)
				// 3. FIlter the result to include only the current user's favorite facts.
					.whereField(userKeyName, isEqualTo: (user.email)!)
				// 4. Listen for any changes made to the favorite facts list on the Firebase end, such as by RandoFacto on another device.
					.addSnapshotListener(includeMetadataChanges: true) { [self] snapshot, error in
						// 5. Log any errors.
						if let error = error {
							errorDelegate?.randoFactoDatabaseLoadingDidFail(self, error: error)
						} else {
							// 6. If no data can be found, it's most likely due to a missing user, so log them out and return.
							guard let snapshot = snapshot else {
								logoutMissingUser()
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
		// 1. Clear the favorite facts list.
		favoriteFacts.removeAll()
		// 2. Go through each document (piece of data) in the snapshot.
		for favorite in snapshot.documents {
			// 3. If the data's "fact" key contains data, append it to the favorite facts list.
			if let fact = favorite.data()[factTextKeyName] as? String {
				favoriteFacts.append(fact)
			} else {
				// 4. Otherwise, log an error. RandoFacto only gives the user safe facts that contain text--this error is only logged if a previously-saved favorite fact had its data removed, or it was manually added to RandoFacto's Firestore.
				let loadError = NSError(domain: "\(favorite) doesn't appear to contain fact text!", code: 423)
				errorDelegate?.randoFactoDatabaseLoadingDidFail(self, error: loadError)
			}
		}
	}

	// MARK: - Get Random Favorite Fact

	// This method gets a random fact from the favorite facts list and returns it.
	func getRandomFavoriteFact() -> String {
		return favoriteFacts.randomElement()!
	}

	// MARK: - Favorites Management - Saving/Deleting

	// This method saves the given fact to the RandoFacto database.
	func saveToFavorites(fact: String) {
		// 1. Make sure the fact doesn't already exist and that the current user has an email (who would have an account but no email?!).
		guard !favoriteFacts.contains(fact), let userEmail = firebaseAuthentication.currentUser?.email else { return }
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
					errorDelegate?.randoFactoDatabaseDidFailToAddFavorite(self, fact: fact, error: error)
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
					errorDelegate?.randoFactoDatabaseDidFailToDeleteFavorite(self, fact: fact, error: error)
				} else {
					// 3. Or if we're error-free, get the snapshot and delete.
					getFavoriteFactSnapshotAndDelete(snapshot, fact: fact)
				}
			}
		}
	}

	// This method gets the data from the given snapshot and deletes it.
	func getFavoriteFactSnapshotAndDelete(_ snapshot: QuerySnapshot?, fact: String) {
		// 1. Make sure the snapshot and the corresponding data is there.
		if let snapshot = snapshot, let ref = snapshot.documents.first {
			// 2. Delete the corresponding document.
			firestore.collection(favoritesCollectionName).document(ref.documentID).delete { [self]
				error in
				// 3. Log an error if deletion fails.
				if let error = error {
					errorDelegate?.randoFactoDatabaseDidFailToDeleteFavorite(self, fact: fact, error: error)
				}
			}
		} else {
			// 4. If we can't get the snapshot or corresponding data, log an error.
			errorDelegate?.randoFactoDatabaseDidFailToDeleteFavorite(self, fact: fact, error: refError)
		}
	}

	// This method deletes all favorite facts from the database.
	func deleteAllFavoriteFactsForCurrentUser(completionHandler: @escaping ((Error?) -> Void)) {
		// 1. Go through all favorite facts.
		let group = DispatchGroup()
		for fact in favoriteFacts {
			group.enter()
			// 2. Get the document corresponding to the fact.
			firestore.collection(favoritesCollectionName).whereField(factTextKeyName, isEqualTo: fact).getDocuments(source: .cache) { [self] snapshot, error in
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
				firestore.collection(favoritesCollectionName).document(ref.documentID).delete { error in
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

}
