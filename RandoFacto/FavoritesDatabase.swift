//
//  FavoritesDatabase.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//

import SwiftUI
import Firebase

protocol FavoritesDelegate {

	func favoritesDatabaseDidFailToAddFavorite(_ database: FavoritesDatabase, fact: String, error: Error)

	func favoritesDatabaseDidFailToRemoveFavorite(_ database: FavoritesDatabase, fact: String, error: Error)

	func favoritesDatabaseLoadingDidFail(_ database: FavoritesDatabase, error: Error)

	func favoritesDatabaseDidFailToLogOut(_ database: FavoritesDatabase, userEmail: String, error: Error)

	func favoritesDatabaseDidFailToDeleteUser(_ database: FavoritesDatabase, error: Error)

}

class FavoritesDatabase: ObservableObject {

	@Published var favorites: [String] = []

	var delegate: FavoritesDelegate?

	private let firestore = Firestore.firestore()

	@Published var firebaseAuth = Auth.auth()

	private let favoritesCollectionName = "favoriteFacts"

	private let factTextKeyName = "fact"

	init(delegate: FavoritesDelegate? = nil) {
		self.delegate = delegate
	}

	// MARK: - Authentication

	func logIn(email: String, password: String, completionHandler: @escaping ((Error?) -> Void)) {
		DispatchQueue.main.async { [self] in
			firebaseAuth.signIn(withEmail: email, password: password) { result, error in
				if let error = error {
					completionHandler(error)
				} else {
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
					delegate?.favoritesDatabaseDidFailToLogOut(self, userEmail: userEmail, error: error)
				}
			}
		}
	}

	func deleteUser() {
		DispatchQueue.main.async { [self] in
			if let user = firebaseAuth.currentUser, let userEmail = user.email {
				user.delete { [self]
					error in
					if let error = error {
						delegate?.favoritesDatabaseDidFailToDeleteUser(self, error: error)
					} else {
						favorites.removeAll()
					}
				}
			}
		}
	}

	// MARK: - Favorites Management

	func loadFavorites() async {
		DispatchQueue.main.async { [self] in
			favorites = []
			firestore.collection(favoritesCollectionName).addSnapshotListener { [self] snapshot, error in
				if let error = error {
					delegate?.favoritesDatabaseLoadingDidFail(self, error: error)
				} else {
					for favorite in (snapshot?.documents)! {
						if let fact = favorite.data()[factTextKeyName] as? String {
							self.favorites.append(fact)
							print(self.favorites)
						} else {
							let loadError = NSError(domain: "\(favorite) doesn't appear to contain fact text!", code: 423)
							delegate?.favoritesDatabaseLoadingDidFail(self, error: loadError)
						}
					}
				}
			}
		}
	}

	func saveToFavorites(fact: String) {
		DispatchQueue.main.async { [self] in
			let data: [String : Any] = [factTextKeyName : fact]
			firestore.collection(favoritesCollectionName).addDocument(data: data) { [self] error in
				if let error = error {
					delegate?.favoritesDatabaseDidFailToAddFavorite(self, fact: fact, error: error)
				}
			}
		}
	}

	func deleteFromFavorites(fact: String) {
		DispatchQueue.main.async { [self] in
			firestore.collection(favoritesCollectionName).whereField(factTextKeyName, isEqualTo: fact).getDocuments { [self] snapshot, error in
				if let error = error {
					delegate?.favoritesDatabaseDidFailToRemoveFavorite(self, fact: fact, error: error)
				} else {
					if let ref = snapshot?.documents.first {
						firestore.collection(favoritesCollectionName).document(ref.documentID).delete { [self]
							error in
							if let error = error {
								delegate?.favoritesDatabaseDidFailToRemoveFavorite(self, fact: fact, error: error)
							} else {
								self.favorites.removeAll { favorite in
									return favorite == fact
								}
							}
						}
					}
				}
			}
		}
	}

}
