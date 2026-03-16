//
//  FavoriteFactsDatabase.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import FirebaseFirestore

// The favorite facts Firestore database.
class FavoriteFactsDatabase: ObservableObject {

    // MARK: - Properties - Objects

    // Handles all Firestore database-related tasks.
    var firestore: Firestore

    var authenticationManager: AuthenticationManager? = nil

    var networkConnectionManager: NetworkConnectionManager

    // MARK: - Properties - Favorite Facts Array

    // The current user's favorite facts loaded from the Firestore database. Storing the data in this array makes getting favorite facts easier than getting the corresponding Firestore data each time, which could cause errors.
    // Early builds of the initial release, 2023.12, stored strings instead of favorite fact objects. This had to be changed to add a user field to each favorite fact.
    @Published var favoriteFacts: [FavoriteFact] = []

    // MARK: - Properties - Favorite Facts Listener

    // Listens for changes to the current user's favorite facts, whether it's from RandoFacto on this device, RandoFacto on another device, or RandoFacto's Firebase console. Changes are synced to the device.
    var favoriteFactsListener: ListenerRegistration? = nil

    // MARK: - Properties - Integers

    // Whether to display one of the user's favorite facts (1), show the favorite facts list (2), or generate a random fact (0) when the app launches. This setting resets to 0 (Random Fact) and is hidden when the user logs out or deletes their account.
    @AppStorage(UserDefaults.KeyNames.initialFact) var initialFact: Int = 0

    // MARK: - Properties - Errors

    // The error thrown when a favorite fact's reference can't be found.
    let favoriteFactReferenceError = NSError(domain: ErrorDomain.favoriteFactReferenceNotFound.rawValue, code: ErrorCode.favoriteFactReferenceNotFound.rawValue)

    // MARK: - Initialization

    init(firestore: Firestore, networkConnectionManager: NetworkConnectionManager) {
        self.firestore = firestore
        self.networkConnectionManager = networkConnectionManager
        setupListener()
    }

    func setupListener() {
        loadFavoriteFactsForCurrentUser { error in
            if let error = error {
                fatalError("Failed to load/update favorite facts: \(error)")
            }
        }
    }

    // MARK: - Loading

    // This method asynchronously loads all the favorite facts associated with the current user upon launch or authentication. Firestore doesn't yet have a way to associate data with the user that created it, so we have to add a "user" key to each favorite fact so only the user that created them can access them.
    func loadFavoriteFactsForCurrentUser(completionHandler: @escaping ((Error?) -> Void)) {
        DispatchQueue.main.async { [self] in
            // 1. Make sure we can get the current user.
            guard let authenticationManager = authenticationManager, authenticationManager.userLoggedIn, let user = authenticationManager.firebaseAuthentication.currentUser, let userEmail = user.email else {
                return
            }
            // 2. Get the Firestore collection containing favorite facts.
            // Just like with SwiftUI view modifiers, common convention is to have each Firebase method call on its own line.
            favoriteFactsListener = firestore.collection(Firestore.CollectionName.favoriteFacts)
            // 3. Filter the result to include only the current user's favorite facts.
                .whereField(Firestore.KeyName.user, isEqualTo: userEmail)
            // 4. Listen for any changes made to the favorite facts list, whether it's on this device, another device, or the Firebase console. The result of steps 2-4 is the value of favoriteFactsListener. It isn't necessary to assign the result of this method call to a QuerySnapshotListener object unless you want to be able to remove the listener later.
                .addSnapshotListener(includeMetadataChanges: true) {
                    [self] snapshot, error in
                    // 5. Log any errors.
                    if let error = error {
                        completionHandler(error)
                    } else {
                        // 6. If no data can be found, return.
                        guard let snapshot = snapshot else {
                            return
                        }
                        // 7. If a change was successfully detected, update the app's favorite facts array.
                        updateFavoriteFactsList(from: snapshot, completionHandler: completionHandler)
                    }
                }
        }
    }

    // This method updates the app's favorite facts list with snapshot's data.
    func updateFavoriteFactsList(from snapshot: QuerySnapshot, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Try to replace the data in favoriteFacts with snapshot's data by decoding each of its documents to FavoriteFact objects.
        do {
            // compactMap is marked throws so you can call throwing functions in its closure. Errors are then "rethrown" so the catch block of this do statement can handle them.
            // compactMap throws out any documents where the data couldn't be decoded to a FavoriteFact object (the result of the transformation is nil).
            favoriteFacts = try snapshot.documents.compactMap { document in
                let decodedFact = try decodeFavoriteFact(from: document)
                return decodedFact
            }
            completionHandler(nil)
        } catch {
            // 2. If that fails, log an error.
            completionHandler(error)
        }
    }

    // This method decodes document to a FavoriteFact object.
    func decodeFavoriteFact(from document: QueryDocumentSnapshot) throws -> FavoriteFact {
        // 1. Try to decode the document's data to a FavoriteFact object.
        // data(as:) handles the decoding of the data, so we don't need to use a Decoder object.
        let favoriteFact = try document.data(as: FavoriteFact.self)
        // 2. Return the decoded favorite fact.
        return favoriteFact
    }

    // MARK: - Saving/Deleting

    // This method creates a FavoriteFact from factText and saves it to the favorite facts database.
    func saveFactToFavorites(_ factText: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure the current user has an email (who would have an account but no email?!).
        guard let userEmail = authenticationManager?.firebaseAuthentication.currentUser?.email else { return }
        // 2. Create a FavoriteFact object with the fact text and the current user's email.
        let fact = FavoriteFact(text: factText, user: userEmail)
        // 3. Make sure the favorite fact doesn't already exist. This is done by checking its text, not its document ID.
        guard !favoriteFacts.contains(fact) else { return }
        // 4. Try to create a new document with that data in the favorite facts Firestore collection
        do {
            try firestore.collection(Firestore.CollectionName.favoriteFacts)
                .addDocument(from: fact)
            completionHandler(nil)
        } catch {
            // 5. If that fails, log an error.
            completionHandler(error)
        }
    }

    // This method finds a favorite fact in the database and deletes it if its text matches factText.
    func unfavoriteFact(_ factText: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure we can get the current user.
        guard let userEmail = authenticationManager?.firebaseAuthentication.currentUser?.email else { return }
        // 2. Get facts with text that matches the given fact text (there should only be 1).
        firestore.collection(Firestore.CollectionName.favoriteFacts)
            .whereField(Firestore.KeyName.user, isEqualTo: userEmail)
            .whereField(Firestore.KeyName.factText, isEqualTo: factText)
            .getDocuments(source: .cache) { [self] snapshot, error in
                // 3. If that fails, log an error.
                if let error = error {
                    completionHandler(error)
                } else {
                    // 4. Or if we're error-free, get the snapshot and delete.
                    getFavoriteFactSnapshotAndDelete(snapshot, completionHandler: completionHandler)
                }
            }
    }

    // This method gets the data from snapshot and deletes it.
    func getFavoriteFactSnapshotAndDelete(_ snapshot: QuerySnapshot?, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure the snapshot and the corresponding data are there.
        if let snapshot = snapshot, let document = snapshot.documents.first {
            // 2. Delete the corresponding document.
            document.reference.delete {
                error in
                // 3. Log an error if deletion fails.
                completionHandler(error)
            }
        } else {
            // 4. If we can't get the snapshot or corresponding data, log an error.
            completionHandler(favoriteFactReferenceError)
        }
    }

    // This method deletes all of the current user's favorite facts from the database.
    func deleteAllFavoriteFactsForCurrentUser(forUserDeletion deletingUser: Bool = false, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure we can get the current user.
        guard let userEmail = authenticationManager?.firebaseAuthentication.currentUser?.email else { return }
        var deletionError: Error?
        let factStorageSource: FirestoreSource = deletingUser ? .server : .cache
        // 2. Create a DispatchGroup.
        let group = DispatchGroup()
        // 3. Get all favorite facts associated with the current user. If deleting their account, get from the server instead of the cache to ensure the server data is wiped before deletion continues.
        firestore.collection(Firestore.CollectionName.favoriteFacts)
            .whereField(Firestore.KeyName.user, isEqualTo: userEmail)
            .getDocuments(source: factStorageSource) { [self] (snapshot, error) in
                // 4. If that fails, log an error.
                if let error = error {
                    deletionError = error
                } else {
                    // 5. Loop through each favorite fact and delete it.
                    let documents = snapshot?.documents
                    deletionError = performAllFavoriteFactDelete(documents: documents, with: group)
                }
                // 6. Notify the DispatchGroup on the main thread and call the completion handler with any errors that may have been encountered above.
                group.notify(queue: .main) {
                    completionHandler(deletionError)
                }
            }
    }

    // This method loops through each favorite fact and deletes it.
    func performAllFavoriteFactDelete(documents: [QueryDocumentSnapshot]?, with group: DispatchGroup) -> Error? {
        var deletionError: Error?
        if let documents = documents {
            for document in documents {
                // 1. Enter the DispatchGroup before attempting deletion.
                group.enter()
                // 2. Try to delete this favorite fact, leaving the DispatchGroup when done. If an error occurs, log it.
                document.reference.delete { error in
                    if let error = error {
                        deletionError = error
                    }
                    group.leave()
                }
                // 3. Get out of the loop and cancel deletion if deletion of this favorite fact fails.
                if deletionError != nil {
                    break
                }
            }
        }
        // 4. Return the error if any.
        return deletionError
    }

}
