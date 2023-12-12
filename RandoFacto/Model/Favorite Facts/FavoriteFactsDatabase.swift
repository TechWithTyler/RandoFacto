//
//  FavoriteFactsDatabase.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/23.
//

import SwiftUI
import Firebase

// The favorite facts Firestore database.
class FavoriteFactsDatabase: ObservableObject {
    
    // MARK: - Properties - Objects
    
    var firestore: Firestore
    
    var authenticationManager: AuthenticationManager? = nil
    
    var networkManager: NetworkManager
    
    var errorManager: ErrorManager
    
    var favoriteFactSearcher: FavoriteFactSearcher
    
    // MARK: - Properties - Favorite Facts Array
    
    // The current user's favorite facts loaded from the Firestore database. Storing the data in this array makes getting favorite facts easier than getting the corresponding Firestore data each time, which could cause errors.
    @Published var favoriteFacts: [FavoriteFact] = []
    
    // MARK: - Properties - Favorite Facts Listener
    
    // Listens for changes to the current user's favorite facts.
    var favoriteFactsListener: ListenerRegistration? = nil
    
    // MARK: - Properties - Errors
    
    // The error logged if the favorite facts database is unable to get the document (data) from the corresponding favorite fact QuerySnapshot.
    private let favoriteFactReferenceError = NSError(domain: "Favorite fact reference not found", code: 144)
    
    // MARK: - Properties - Booleans
    
    // Whether the "delete this favorite fact" alert should be displayed.
    @Published var showingDeleteFavoriteFact: Bool = false
    
    // Whether the "delete all favorite facts" alert should be displayed.
    @Published var showingDeleteAllFavoriteFacts: Bool = false
    
    // MARK: - Properties - Strings
    
    // The favorite fact to be deleted when pressing "Delete" in the alert.
    var favoriteFactToDelete: String? = nil
    
    // MARK: - Properties - Integers
    
    // Whether to display one of the user's favorite facts or generate a random fact when the app launches. This setting resets to 0 (Random Fact), and is hidden, when the user logs out or deletes their account.
    @AppStorage("initialFact") var initialFact: Int = 0
    
    // MARK: - Initialization
    
    init(firestore: Firestore, networkManager: NetworkManager, errorManager: ErrorManager, favoriteFactSearcher: FavoriteFactSearcher) {
        self.firestore = firestore
        self.networkManager = networkManager
        self.errorManager = errorManager
        self.favoriteFactSearcher = favoriteFactSearcher
        loadFavoriteFactsForCurrentUser()
    }
    
    // MARK: - Loading
    
    // This method asynchronously loads all the favorite facts associated with the current user. Firestore doesn't have a way to associate data with the user that created it, so we have to add a "user" key to each favorite fact so when a user deletes their account, their favorite facts, but no one else's, are deleted.
    func loadFavoriteFactsForCurrentUser() {
        DispatchQueue.main.async { [self] in
            // 1. Make sure we can get the current user.
            guard (authenticationManager?.userLoggedIn)!, let user = authenticationManager?.firebaseAuthentication.currentUser, let userEmail = user.email else {
                return
            }
            // 2. Get the Firestore collection containing favorite facts.
            favoriteFactsListener = firestore.collection(favoriteFactsCollectionName)
            // 3. Filter the result to include only the current user's favorite facts.
                .whereField(userKeyName, isEqualTo: userEmail)
            // 4. Listen for any changes made to the favorite facts list on the Firebase end, such as by RandoFacto on another device.
                .addSnapshotListener(includeMetadataChanges: true) { [self] snapshot, error in
                    // 5. Log any errors.
                    if let error = error {
                        errorManager.showError(error)
                    } else {
                        // 6. If no data can be found, return.
                        guard let snapshot = snapshot else {
                            return
                        }
                        // 7. If a change was successfully detected, update the app's favorite facts array.
                        updateFavoriteFactsList(from: snapshot)
                    }
                }
        }
    }
    
    // This method updates the app's favorite facts list with snapshot's data.
    func updateFavoriteFactsList(from snapshot: QuerySnapshot) {
        // 1. Try to replace the data in favoriteFacts with snapshot's data by decoding it to a FavoriteFact object.
        do {
            // compactMap is marked throws so you can call throwing functions in its closure. Errors are then "rethrown" so the catch block of this do statement can handle them.
            favoriteFacts = try snapshot.documents.compactMap { document in
                // data(as:) handles the decoding of the data, so we don't need to use a Decoder object.
                return try document.data(as: FavoriteFact.self)
            }
            favoriteFactSearcher.favoriteFacts = favoriteFacts
        } catch {
            // 2. If that fails, log an error.
            errorManager.showError(error)
        }
    }
    
    // MARK: - Saving/Deleting
    
    // This method creates a FavoriteFact from factText and saves it to the favorite facts database.
    func saveFactToFavorites(_ factText: String) {
        // 1. Make sure the fact doesn't already exist and that the current user has an email (who would have an account but no email?!).
        guard let email = authenticationManager?.firebaseAuthentication.currentUser?.email else { return }
        let fact = FavoriteFact(text: factText, user: email)
        guard !favoriteFacts.contains(fact) else { return }
        // 2. Create a FavoriteFact object with the fact text and the current user's email, and try to create a new document with that data in the favorite facts Firestore collection.
        do {
            try firestore.collection(favoriteFactsCollectionName).addDocument(from: fact)
        } catch {
            DispatchQueue.main.async { [self] in
                errorManager.showError(error)
            }
        }
    }
    
    // This method finds a favorite fact in the database and deletes it if its text matches factText.
    func unfavoriteFact(_ factText: String) {
        // 1. Get facts with text that matches the given fact text (there should only be 1).
        DispatchQueue.main.async { [self] in
            firestore.collection(favoriteFactsCollectionName)
                .whereField(factTextKeyName, isEqualTo: factText)
                .getDocuments(source: .cache) { [self] snapshot, error in
                    // 2. If that fails, log an error.
                    if let error = error {
                        errorManager.showError(error)
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
            if let snapshot = snapshot, let document = snapshot.documents.first {
                // 2. Delete the corresponding document.
                document.reference.delete { [self]
                    error in
                    // 3. Log an error if deletion fails.
                    if let error = error {
                        errorManager.showError(error)
                    }
                }
            } else {
                // 4. If we can't get the snapshot or corresponding data, log an error.
                errorManager.showError(favoriteFactReferenceError)
            }
        }
    }
    
    // This method deletes all of the current user's favorite facts from the database.
    func deleteAllFavoriteFactsForCurrentUser(forUserDeletion deletingUser: Bool = false, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure we can get the current user.
        guard let userEmail = authenticationManager?.firebaseAuthentication.currentUser?.email else {
            return }
        var deletionError: Error?
        let factStorageSource: FirestoreSource = deletingUser ? .server : .cache
        // 2. Create a DispatchGroup.
        let group = DispatchGroup()
        // 3. Get all favorite facts associated with the current user. If deleting their account, get from the server instead of the cache to ensure the server data is wiped before deletion continues.
        firestore.collection(favoriteFactsCollectionName)
            .whereField(userKeyName, isEqualTo: userEmail)
            .getDocuments(source: factStorageSource) { (snapshot, error) in
                // 4. If that fails, log an error.
                if let error = error {
                    deletionError = error
                } else {
                    // 5. Loop through each favorite fact.
                    if let documents = snapshot?.documents {
                        for document in documents {
                            // 6. Enter the DispatchGroup before attempting deletion.
                            group.enter()
                            // 7. Try to delete this favorite fact, leaving the DispatchGroup when done. If an error occurs, log it.
                            document.reference.delete { error in
                                if let error = error {
                                    deletionError = error
                                }
                                group.leave()
                            }
                            // 8. Get out of the loop and cancel deletion if deletion of this favorite fact fails.
                            if deletionError != nil {
                                break
                            }
                        }
                    }
                }
                // 9. Notify the DispatchGroup on the main thread and call the completion handler.
                group.notify(queue: .main) {
                    completionHandler(deletionError)
                }
            }
    }
    
}
