//
//  FavoriteFactsDatabase.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase

// The favorite facts Firestore database.
class FavoriteFactsDatabase: ObservableObject {
    
    // MARK: - Properties - Objects
    
    var firestore: Firestore
    
    var authenticationManager: AuthenticationManager? = nil
    
    var networkConnectionManager: NetworkConnectionManager
    
    var errorManager: ErrorManager
    
    // MARK: - Properties - Favorite Facts Array
    
    // The current user's favorite facts loaded from the Firestore database. Storing the data in this array makes getting favorite facts easier than getting the corresponding Firestore data each time, which could cause errors.
    @Published var favoriteFacts: [FavoriteFact] = []
    
    // MARK: - Properties - Favorite Facts Listener
    
    // Listens for changes to the current user's favorite facts.
    var favoriteFactsListener: ListenerRegistration? = nil

    // MARK: - Properties - Booleans

    // Whether RandoFacto should "spin through" a user's favorite facts when getting a random favorite fact.
    @AppStorage("favoriteFactsRandomizerEffect") var favoriteFactsRandomizerEffect: Bool = false

    // Whether the "delete this favorite fact" alert should be/is being displayed.
    @Published var showingDeleteFavoriteFact: Bool = false
    
    // Whether the "delete all favorite facts" alert should be/is being displayed.
    @Published var showingDeleteAllFavoriteFacts: Bool = false
    
    // MARK: - Properties - Strings
    
    // The favorite fact to be deleted when pressing "Delete" in the alert.
    var favoriteFactToDelete: String? = nil
    
    // MARK: - Properties - Integers
    
    // Whether to display one of the user's favorite facts (1) or generate a random fact (0) when the app launches. This setting resets to 0 (Random Fact), and is hidden, when the user logs out or deletes their account.
    @AppStorage("initialFact") var initialFact: Int = 0

    // The maximum number of iterations for the randomizer effect. The randomizer effect starts out fast and gradually slows down, by using the equation randomizerIterations divided by (maxRandomizerIterations times 4).
    let maxRandomizerIterations: Int = 20

    // The number of iterations the randomizer effect has gone through. The randomizer stops after this property reaches maxRandomizerIterations.
    var randomizerIterations: Int = 0

    // MARK: - Properties - Randomizer Timer

    // The timer used for the randomizer effect.
    var randomizerTimer: Timer? = nil

    // MARK: - Initialization
    
    init(firestore: Firestore, networkConnectionManager: NetworkConnectionManager, errorManager: ErrorManager) {
        self.firestore = firestore
        self.networkConnectionManager = networkConnectionManager
        self.errorManager = errorManager
        loadFavoriteFactsForCurrentUser()
    }
    
    // MARK: - Loading
    
    // This method asynchronously loads all the favorite facts associated with the current user upon launch or authentication. Firestore doesn't yet have a way to associate data with the user that created it, so we have to add a "user" key to each favorite fact so when a user deletes their account, their favorite facts, but no one else's, are deleted.
    func loadFavoriteFactsForCurrentUser() {
        DispatchQueue.main.async { [self] in
            // 1. Make sure we can get the current user.
            guard (authenticationManager?.userLoggedIn)!, let user = authenticationManager?.firebaseAuthentication.currentUser, let userEmail = user.email else {
                return
            }
            // 2. Get the Firestore collection containing favorite facts.
            // Just like with SwiftUI view modifiers, common convention is to have each Firebase method call on its own line.
            favoriteFactsListener = firestore.collection(Firestore.CollectionName.favoriteFacts)
            // 3. Filter the result to include only the current user's favorite facts.
                .whereField(Firestore.KeyName.user, isEqualTo: userEmail)
            // 4. Listen for any changes made to the favorite facts list, whether it's on this device, another device, or the Firebase console. The result of steps 2-4 is the value of favoriteFactsListener.
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
            // compactMap throws out any documents where the data couldn't be decoded to a FavoriteFact object (the result of the transformation is nil).
            favoriteFacts = try snapshot.documents.compactMap { document in
                // data(as:) handles the decoding of the data, so we don't need to use a Decoder object.
                let documentData = try document.data(as: FavoriteFact.self)
                return documentData
            }
        } catch {
            // 2. If that fails, log an error.
            errorManager.showError(error)
        }
    }

    // MARK: - Randomizer Timer

    // This method sets up the randomizer timer.
    func setupRandomizerTimer(block: @escaping (() -> Void)) {
        // 1. Start the randomizerTimer without repeat, since the timer's interval increases as randomizerIterations increases and the time interval of running Timers can't be changed directly.
        randomizerTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(Double(randomizerIterations)/Double(maxRandomizerIterations*4)), repeats: false, block: { [self] timer in
            // 2. If randomizerIterations equals maxRandomizerIterations, stop the timer and reset the count.
            if randomizerIterations == maxRandomizerIterations {
                timer.invalidate()
                randomizerTimer = nil
                randomizerIterations = 0
            } else {
                // 3. Otherwise, increase the count and restart the timer.
                randomizerIterations += 1
                timer.invalidate()
                setupRandomizerTimer {
                    block()
                }
            }
            block()
        })
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
            try firestore.collection(Firestore.CollectionName.favoriteFacts)
                .addDocument(from: fact)
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
            firestore.collection(Firestore.CollectionName.favoriteFacts)
                .whereField(Firestore.KeyName.factText, isEqualTo: factText)
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
        let favoriteFactReferenceError = NSError(domain: ErrorDomain.favoriteFactReferenceNotFound.rawValue, code: ErrorCode.favoriteFactReferenceNotFound.rawValue)
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
        firestore.collection(Firestore.CollectionName.favoriteFacts)
            .whereField(Firestore.KeyName.user, isEqualTo: userEmail)
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
