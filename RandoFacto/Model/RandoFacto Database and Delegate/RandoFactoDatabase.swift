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

	@Published var favorites: [String] = []

	// MARK: - Properties - Delegate

	var delegate: RandoFactoDatabaseDelegate?

	// MARK: - Properties - Network Monitor

	private var networkPathMonitor = NWPathMonitor()

	@Published var online = false

	// MARK: - Properties - Firebase

	private let firestore = Firestore.firestore()

	@Published var firebaseAuth = Auth.auth()

	// MARK: - Properties - Strings

	private let favoritesCollectionName = "favoriteFacts"

	private let userKeyName = "user"

	private let factTextKeyName = "fact"

	// MARK: - Properties - Errors

	private let refError = NSError(domain: "Favorite reference not found", code: 144)

	// MARK: - Initialization

	init(delegate: RandoFactoDatabaseDelegate? = nil) {
		self.delegate = delegate
		configureNetworkPathMonitor()
	}

	// MARK: - Network Monitor Configuration

	func configureNetworkPathMonitor() {
		networkPathMonitor.pathUpdateHandler = {
			[self] path in
			if path.status == .satisfied {
				firestore.enableNetwork {
					[self] error in
					if let error = error {
						delegate?.randoFactoDatabaseNetworkEnableDidFail(self, error: error)
					} else {
						DispatchQueue.main.async { [self] in
							online = true
						}
					}
				}
			} else {
				firestore.disableNetwork {
					[self] error in
					if let error = error {
						delegate?.randoFactoDatabaseNetworkDisableDidFail(self, error: error)
					} else {
						DispatchQueue.main.async { [self] in
							online = false
						}
					}
				}
			}
		}
		let dispatchQueue = DispatchQueue(label: "Network Monitor")
		networkPathMonitor.start(queue: dispatchQueue)
	}

	// MARK: - Authentication

	func logIn(email: String, password: String, completionHandler: @escaping ((Error?) -> Void)) {
		DispatchQueue.main.async { [self] in
			firebaseAuth.signIn(withEmail: email, password: password) { result, error in
				if let error = error {
					completionHandler(error)
				} else {
					Task {
						await self.loadFavorites()
					}
					completionHandler(nil)
				}
			}
		}
	}

	func signUp(email: String, password: String, completionHandler: @escaping ((Error?) -> Void)) {
		DispatchQueue.main.async { [self] in
			firebaseAuth.createUser(withEmail: email, password: password) { result, error in
				if let error = error {
					completionHandler(error)
				} else {
					Task {
						await self.loadFavorites()
					}
					completionHandler(nil)
				}
			}
		}
	}

	func logOut() {
		DispatchQueue.main.async { [self] in
			if let userEmail = firebaseAuth.currentUser?.email {
				do {
					try firebaseAuth.signOut()
					favorites.removeAll()
				} catch {
					delegate?.randoFactoDatabaseDidFailToLogOut(self, userEmail: userEmail, error: error)
				}
			}
		}
	}

	func logOutMissingUser() {
		firebaseAuth.currentUser?.getIDTokenForcingRefresh(true) { [self] token, error in
			if let error = error {
				delegate?.randoFactoDatabaseLoadingDidFail(self, error: error)
			} else {
				if token == nil {
					logOut()
				}
			}
		}
	}

	// MARK: - Delete User

	func deleteUser() {
		guard let user = firebaseAuth.currentUser else { return }
		firestore.collection(favoritesCollectionName)
			.whereField(userKeyName, isEqualTo: user.email!)
			.getDocuments { [self] snapshot, error in
				if let error = error {
					delegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
					return
				}
				guard let snapshot = snapshot else { return }
				for ref in snapshot.documents {
					firestore.collection(favoritesCollectionName)
						.document(ref.documentID)
						.delete { [self] error in
							if let error = error {
								delegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
								return
							} else {
								user.delete { [self] error in
									if let error = error {
										delegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
									} else {
										favorites.removeAll()
										logOut()
									}
								}
							}
						}
				}
			}
	}

	// MARK: - Favorites Management - Loading

	func loadFavorites() async {
		if firebaseAuth.currentUser != nil {
			DispatchQueue.main.async { [self] in
				firestore.collection(favoritesCollectionName)
					.whereField(userKeyName, isEqualTo: (firebaseAuth.currentUser?.email)!)
					.addSnapshotListener(includeMetadataChanges: true) { [self] snapshot, error in
						if let error = error {
							delegate?.randoFactoDatabaseLoadingDidFail(self, error: error)
						} else {
							guard let snapshot = snapshot else {
								logOutMissingUser()
								return
							}
							favorites = []
							for favorite in snapshot.documents {
								if let fact = favorite.data()[factTextKeyName] as? String {
									self.favorites.append(fact)
								} else {
									let loadError = NSError(domain: "\(favorite) doesn't appear to contain fact text!", code: 423)
									delegate?.randoFactoDatabaseLoadingDidFail(self, error: loadError)
								}
							}
						}
					}
			}
		}
	}

	// MARK: - Favorites Management - Saving/Deleting

	func saveToFavorites(fact: String) {
		guard !favorites.contains(fact) else { return }
		DispatchQueue.main.async { [self] in
			let data: [String : Any] = [
				factTextKeyName : fact,
				userKeyName : (firebaseAuth.currentUser?.email)!
			]
			firestore.collection(favoritesCollectionName).addDocument(data: data) { [self] error in
				if let error = error {
					delegate?.randoFactoDatabaseDidFailToAddFavorite(self, fact: fact, error: error)
				}
			}
		}
	}

	func deleteFromFavorites(fact: String) {
		DispatchQueue.main.async { [self] in
			firestore.collection(favoritesCollectionName).whereField(factTextKeyName, isEqualTo: fact).getDocuments(source: .cache) { [self] snapshot, error in
				if let error = error {
					delegate?.randoFactoDatabaseDidFailToDeleteFavorite(self, fact: fact, error: error)
				} else {
					if let snapshot = snapshot, let ref = snapshot.documents.first {
						firestore.collection(favoritesCollectionName).document(ref.documentID).delete { [self]
							error in
							if let error = error {
								delegate?.randoFactoDatabaseDidFailToDeleteFavorite(self, fact: fact, error: error)
							}
						}
					} else {
						delegate?.randoFactoDatabaseDidFailToDeleteFavorite(self, fact: fact, error: refError)
					}
				}
			}
		}
	}

	func deleteAllFavorites(completionHandler: @escaping ((Error?) -> Void)) {
		let group = DispatchGroup()
		for fact in favorites {
			group.enter()
			firestore.collection(favoritesCollectionName).whereField(factTextKeyName, isEqualTo: fact).getDocuments(source: .cache) { [self] snapshot, error in
				defer {
					group.leave()
				}
				if let error = error {
					completionHandler(error)
					return
				}
				guard let snapshot = snapshot, let ref = snapshot.documents.first else {
					completionHandler(refError)
					return
				}
				firestore.collection(favoritesCollectionName).document(ref.documentID).delete { error in
					if let error = error {
						completionHandler(error)
					}
				}
			}
		}
		group.notify(queue: DispatchQueue.main) {
			completionHandler(nil)
		}
	}

}
