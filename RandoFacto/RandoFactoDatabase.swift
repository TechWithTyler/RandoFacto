//
//  RandoFactoDatabase.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//

import SwiftUI
import Firebase
import Network

protocol RandoFactoDatabaseDelegate {

	func randoFactoDatabaseDidFailToAddFavorite(_ database: RandoFactoDatabase, fact: String, error: Error)

	func randoFactoDatabaseDidFailToRemoveFavorite(_ database: RandoFactoDatabase, fact: String, error: Error)

	func randoFactoDatabaseLoadingDidFail(_ database: RandoFactoDatabase, error: Error)

	func randoFactoDatabaseDidFailToLogOut(_ database: RandoFactoDatabase, userEmail: String, error: Error)

	func randoFactoDatabaseDidFailToDeleteUser(_ database: RandoFactoDatabase, error: Error)

}

class RandoFactoDatabase: ObservableObject {

	@Published var favorites: [String] = []

	var delegate: RandoFactoDatabaseDelegate?

	private var networkPathMonitor = NWPathMonitor()

	private let firestore = Firestore.firestore()

	@Published var firebaseAuth = Auth.auth()

	@Published var online = false

	private let favoritesCollectionName = "favoriteFacts"

	private let userKeyName = "user"

	private let factTextKeyName = "fact"

	private let refError = NSError(domain: "Favorite reference not found", code: 144)

	init(delegate: RandoFactoDatabaseDelegate? = nil) {
		self.delegate = delegate
		configureNetworkPathMonitor()
	}

	func configureNetworkPathMonitor() {
		networkPathMonitor.pathUpdateHandler = {
			[self] path in
			if path.status == .satisfied {
				print("Online")
				DispatchQueue.main.async { [self] in
					online = true
				}
				firestore.enableNetwork {
					error in
					if let error = error {
						print("Error enabling network: \(error)")
					}
				}
			} else {
				print("Offline")
				DispatchQueue.main.async { [self] in
					online = false
				}
				firestore.disableNetwork {
					error in
					if let error = error {
						print("Error disabling network: \(error)")
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

	func deleteUser() {
		DispatchQueue.main.async { [self] in
			if let user = firebaseAuth.currentUser {
				DispatchQueue.main.async { [self] in
					firestore.collection(favoritesCollectionName).whereField(userKeyName, isEqualTo: user.email!).getDocuments { [self] snapshot, error in
						if let error = error {
							delegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
						} else {
							for ref in (snapshot?.documents)! {
									firestore.collection(favoritesCollectionName).document(ref.documentID).delete { [self]
										error in
										if let error = error {
											delegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
											return
										}
								}
							}
						}
					}
				}
				user.delete { [self]
					error in
					if let error = error {
						delegate?.randoFactoDatabaseDidFailToDeleteUser(self, error: error)
					} else {
						favorites.removeAll()
					}
				}
			}
		}
	}

	// MARK: - Favorites Management

	func loadFavorites() async {
		if firebaseAuth.currentUser != nil {
			DispatchQueue.main.async { [self] in
				firestore.collection(favoritesCollectionName)
					.whereField(userKeyName, isEqualTo: (firebaseAuth.currentUser?.email)!)
					.addSnapshotListener(includeMetadataChanges: true) { [self] snapshot, error in
						if let error = error {
							delegate?.randoFactoDatabaseLoadingDidFail(self, error: error)
						} else {
							favorites = []
							for favorite in (snapshot?.documents)! {
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

	func saveToFavorites(fact: String) {
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
					delegate?.randoFactoDatabaseDidFailToRemoveFavorite(self, fact: fact, error: error)
				} else {
					if let ref = snapshot?.documents.first {
						firestore.collection(favoritesCollectionName).document(ref.documentID).delete { [self]
							error in
							if let error = error {
								delegate?.randoFactoDatabaseDidFailToRemoveFavorite(self, fact: fact, error: error)
							}
						}
					} else {
						delegate?.randoFactoDatabaseDidFailToRemoveFavorite(self, fact: fact, error: refError)
					}
				}
			}
		}
	}

	func deleteAllFavorites(completionHandler: @escaping ((Error?) -> Void)) {
		Task {
		for fact in favorites {
				DispatchQueue.main.async { [self] in
					firestore.collection(favoritesCollectionName).whereField(factTextKeyName, isEqualTo: fact).getDocuments(source: .cache) { [self] snapshot, error in
						if let error = error {
							completionHandler(error)
							return
						} else {
							if let ref = snapshot?.documents.first {
								firestore.collection(favoritesCollectionName).document(ref.documentID).delete {
									error in
									if let error = error {
										completionHandler(error)
										return
									}
								}
							} else {
								completionHandler(refError)
								return
							}
						}
					}
				}
			}
		}
	}

}
