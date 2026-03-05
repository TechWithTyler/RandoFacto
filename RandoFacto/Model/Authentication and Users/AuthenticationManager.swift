//
//  AuthenticationManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Handles authentication and user accounts.
class AuthenticationManager: ObservableObject {

    // MARK: - Properties - Objects

    @Published var firebaseAuthentication: Authentication

    var favoriteFactsDatabase: FavoriteFactsDatabase? = nil

    var networkConnectionManager: NetworkConnectionManager

    // MARK: - Properties - Strings

    // The email address that password reset requests come from. It's in the format noreply@project-id.firebaseapp.com, where project-id is the Firebase app's project ID. In this case, the project ID is randofacto-2b730, so the email address is noreply@randofacto-2b730.firebaseapp.com.
    var passwordResetEmailAddress: String {
        guard let app = FirebaseApp.app(), let projectID = app.options.projectID else {
            fatalError("Can't get project ID")
        }
        let address = "noreply@\(projectID).firebaseapp.com"
        return address
    }

    // MARK: - Properties - Booleans

    // Whether an authentication request (login, signup, password change, password reset email send) is in progress.
    @Published var isAuthenticating: Bool = false

    // Whether a user is logged in.
    var userLoggedIn: Bool {
        return firebaseAuthentication.currentUser != nil
    }

    // Whether user account deletion is in progress (accountDeletionStage isn't nil).
    var isDeletingAccount: Bool {
        return accountDeletionStage != nil
    }

    @AppStorage(UserDefaults.KeyNames.favoriteFactsRandomizerEffect) var favoriteFactsRandomizerEffect: Bool = false

    @AppStorage(UserDefaults.KeyNames.skipFavoritesOnFactGeneration) var skipFavoritesOnFactGeneration: Bool = false

    // MARK: - Properties - Integers

    @AppStorage(UserDefaults.KeyNames.initialFact) var initialFact: Int = 0

    // MARK: - Properties - Account Deletion Stage

    // The current stage of user deletion. Deleting a user deletes their favorite facts and reference first, then their actual account. If the user is still able to login after deletion, the actual account failed to be deleted, so the user reference will be put back.
    @Published var accountDeletionStage: User.AccountDeletionStage? = nil

    // MARK: - Properties - User Reference Listener

    // Listens for changes to the references for the logged in user.
    var userReferenceListener: ListenerRegistration? = nil

    // MARK: - Initialization

    init(firebaseAuthentication: Authentication, networkConnectionManager: NetworkConnectionManager) {
        self.firebaseAuthentication = firebaseAuthentication
        self.networkConnectionManager = networkConnectionManager
        addUserReferenceHandler { error in
            if let error = error {
                fatalError("Failed to load registered user references: \(error)")
            }
        }
    }

    // MARK: - User Reference Handler

    // This method sets up the app to listen for changes to the current user's reference (i.e. if it goes missing). The email addresses and IDs of registered users get added to a Firestore collection called "users" when they signup, because Firebase doesn't yet have an ability to immediately notify the app of creations/deletions of accounts or checking whether they exist.
    func addUserReferenceHandler(completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure the current user is logged in.
        guard let currentUser = firebaseAuthentication.currentUser, let email = currentUser.email else {
            logoutCurrentUser(completionHandler: completionHandler)
            return
        }
        // 2. Get all registered users.
        userReferenceListener = favoriteFactsDatabase?.firestore.collection(Firestore.CollectionName.users)
        // 3. Filter the results to include only the current user.
            .whereField(Firestore.KeyName.email, isEqualTo: email)
        // 4. Listen for any changes made to the current user.
            .addSnapshotListener(includeMetadataChanges: true) { [self] documentSnapshot, error in
                if let error = error {
                    // 5. If that fails, log an error.
                    completionHandler(error)
                } else {
                    // 6. Logout the user if they've been deleted from another device. We need to make sure the snapshot is from the server, not the cache, to prevent the detection of a missing user reference when logging in on a new device for the first time. We also need to make sure a user isn't currently being logged in or deleted on this device, otherwise a missing user would be detected and logged out, causing the operation to never complete, or a new user might be logged out immediately after signup. This was one of the big bugs during development of the initial release (2023.12).
                    checkForUserReference(currentUser, from: documentSnapshot, completionHandler: completionHandler)
                }
            }
    }

    // This method logs out the current user if their user reference is missing.
    func checkForUserReference(_ currentUser: User, from snapshot: QuerySnapshot?, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Return if the account is being deleted or authentication is in progress. These are cases where a missing user reference on the device can be falsely detected.
        guard !isDeletingAccount && !isAuthenticating else { return }
        // 2. If the user reference or snapshot are nil, logout the current user.
        /*
         A user reference is considered "missing"/the user is considered "deleted" if any of the following are true:
         * The snapshot or its documents collection is empty.
         * The snapshot's documents collection doesn't contain the current user's ID.
         * The snapshot is nil.
         */
        if let snapshot = snapshot, !snapshot.metadata.isFromCache, snapshotIsEmpty(snapshot), !snapshot.documents.contains(where: { document in
            return document.documentID == currentUser.uid
        }) {
            logoutCurrentUser(completionHandler: completionHandler)
        } else if snapshot == nil {
            logoutCurrentUser(completionHandler: completionHandler)
        } else {
            // 3. Otherwise, the user is present and can be safely considered logged in.
            completionHandler(nil)
        }
    }

    // MARK: - Check For Empty Snapshot

    // This method returns whether snapshot is empty or has no documents.
    func snapshotIsEmpty(_ snapshot: QuerySnapshot) -> Bool {
        return snapshot.isEmpty || snapshot.documents.isEmpty
    }

    // MARK: - Signup

    // This method takes the user's credentials and tries to sign them up for a RandoFacto account.
    func signup(email: String, password: String, completionHandler: @escaping ((Error?) -> Void)) {
        DispatchQueue.main.async { [self] in
            // 1. Tell the app that an authentication request is in progress.
            isAuthenticating = true
            // 2. Convert the email to lowercase.
            let lowercaseEmail = email.lowercased()
            // 3. Try to sign the user up for an account with the given credentials.
            firebaseAuthentication.createUser(withEmail: lowercaseEmail, password: password) { [self] result, error in
                // 4. Handle the success or error.
                self.handleAuthenticationRequestResult(result, error: error, isSignup: true, completionHandler: completionHandler)
            }
        }
    }

    // MARK: - Login

    // This method takes the user's credentials and tries to log them into their RandoFacto account.
    func login(email: String, password: String, completionHandler: @escaping ((Error?) -> Void)) {
        DispatchQueue.main.async { [self] in
            // 1. Tell the app that an authentication request is in progress.
            isAuthenticating = true
            // 2. Convert the email to lowercase.
            let lowercaseEmail = email.lowercased()
            // 3. Try to log the user in with the given credentials.
            firebaseAuthentication.signIn(withEmail: lowercaseEmail, password: password) { [self] result, error in
                // 4. Handle the success or error.
                handleAuthenticationRequestResult(result, error: error, isSignup: false, completionHandler: completionHandler)
            }
        }
    }

    // MARK: - Password Reset/Update

    // This method changes the current user's password to the given new password.
    func changePasswordForCurrentUser(newPassword: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure we can get the current user.
        guard let user = firebaseAuthentication.currentUser else { return }
        DispatchQueue.main.async { [self] in
            // 2. Tell the app that an authentication request is in progress.
            isAuthenticating = true
            // 3. Update user's password to the new password. If unsuccessful, show an error.
            user.updatePassword(to: newPassword) { [self] error in
                isAuthenticating = false
                completionHandler(error)
            }
        }
    }

    // This method sends a password reset email to the specified email address.
    func sendPasswordResetLink(to email: String, completionHandler: @escaping ((Error?) -> Void)) {
        DispatchQueue.main.async { [self] in
            // 1. Tell the app that an authentication request is in progress.
            isAuthenticating = true
            // 2. Convert the email to lowercase.
            let lowercaseEmail = email.lowercased()
            // 3. Send a password reset link.
            firebaseAuthentication.sendPasswordReset(withEmail: lowercaseEmail, actionCodeSettings: ActionCodeSettings(), completion: { [self] error in
                // 4. Handle the success or error.
                isAuthenticating = false
                completionHandler(error)
            })
        }
    }

    // MARK: - Post-Signup/Login Request Handler

    // This method loads the user's favorite facts if authentication is successful. Otherwise, it logs an error.
    func handleAuthenticationRequestResult(_ result: AuthDataResult?, error: Error?, isSignup: Bool, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Create the block which will be performed if authentication is successful. This block adds the registered users handler, loads the user's favorite facts, and calls the completion handler.
        let successBlock: (() -> Void) = { [self] in
            isAuthenticating = false
            addUserReferenceHandler { [self] error in
                if let error = error {
                    handleLoginFailure(error: error, errorHandler: completionHandler)
                } else {
                    favoriteFactsDatabase?.loadFavoriteFactsForCurrentUser(completionHandler: completionHandler)
                }
            }
        }
        // 2. Log an error if unsuccessful.
        if let error = error {
            isAuthenticating = false
            completionHandler(error)
        } else {
            // 3. If successful, add the user reference if signing up, or check for the user reference when logging in, adding it if it doesn't exist. If that's successful, call the success block.
            if isSignup {
                if let email = result?.user.email, let id = result?.user.uid {
                    addUserReference(email: email, id: id) { [self] error in
                        if let error = error {
                            handleLoginFailure(error: error, errorHandler: completionHandler)
                        } else {
                            successBlock()
                        }
                    }
                } else {
                    isAuthenticating = false
                    logoutCurrentUser(completionHandler: completionHandler)
                }
            } else {
                if let email = result?.user.email, let id = result?.user.uid {
                    checkForUserReference(email: email, id: id) { [self] error in
                        if let error = error {
                            isAuthenticating = false
                            handleLoginFailure(error: error, errorHandler: completionHandler)
                        } else {
                            successBlock()
                        }
                    }
                } else {
                    isAuthenticating = false
                    logoutCurrentUser(completionHandler: completionHandler)
                }
            }
        }
    }

    // MARK: - Login Failure Handler

    // This method tries to log the user out if login fails.
    func handleLoginFailure(error: Error, errorHandler: @escaping ((Error) -> Void)) {
        logoutCurrentUser { logoutError in
            if let logoutError = logoutError {
                errorHandler(logoutError)
            } else {
                errorHandler(error)
            }
        }
    }

    // MARK: - New/Missing User References

    // This method adds a reference for the current user once they signup, or if they login and such reference is missing.
    func addUserReference(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Create a User.Reference object.
        let userReference = User.Reference(email: email)
        // 2. Try to add the data from this object as a new document whose ID is that of the user. Matching the document ID with the user ID makes deleting it easier.
        do {
            try favoriteFactsDatabase?.firestore.collection(Firestore.CollectionName.users)
                .document(id)
                .setData(from: userReference)
            completionHandler(nil)
        } catch {
            // 3. If that fails, log an error.
            completionHandler(error)
        }
    }

    // This method checks for the current user's reference upon logging in and adds it if it doesn't exist.
    func checkForUserReference(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Create the block which will add the missing user reference if needed.
        let addReferenceBlock: ((() -> Void)) = { [self] in
            addUserReference(email: email, id: id) { error in
                completionHandler(error)
            }
        }
        // 2. Check if the current user has a reference.
        favoriteFactsDatabase?.firestore.collection(Firestore.CollectionName.users)
            .whereField(Firestore.KeyName.email, isEqualTo: email)
            .getDocuments(source: .server) { [self] snapshot, error in
                // 3. If that fails, log an error.
                if let error = error {
                    completionHandler(error)
                } else {
                    // 4. If the reference doesn't exist, call the add reference block, which will call the completion handler.
                    if let snapshot = snapshot, snapshotIsEmpty(snapshot) {
                        addReferenceBlock()
                    } else if snapshot == nil {
                        addReferenceBlock()
                    } else {
                        // 5. If it exists, call the completion handler.
                        completionHandler(nil)
                    }
                }
            }
    }

    // MARK: - Logout

    // This method tries to logout the current user, clearing the app's favorite facts list if successful.
    func logoutCurrentUser(completionHandler: @escaping ((Error?) -> Void)) {
        do {
            // 1. Try to logout the current user.
            try firebaseAuthentication.signOut()
            // 2. If successful, reset the app's local Firestore data and related settings.
            resetLocalFirestoreData()
            completionHandler(nil)
        } catch {
            // 3. If unsuccessful, log an error.
            completionHandler(error)
        }
    }

    // MARK: - Reset Local Firestore Data

    // This method deletes all local (cached) Firestore data when a user logs out of/deletes their account.
    func resetLocalFirestoreData() {
        // 1. Clear the favorite facts list.
        DispatchQueue.main.async { [self] in
            favoriteFactsDatabase?.favoriteFacts.removeAll()
        }
        // 2. Reset all favorite fact-related settings as the favorite facts database (and its related settings) don't apply when logged out.
        resetFavoriteFactSettings()
        // 3. Remove and nil-out the user listener and favorite facts listener.
        removeFirestoreListeners()
    }

    // This method resets all settings pertaining to favorite facts, which don't apply when logged out and you can't access the favorite facts database.
    func resetFavoriteFactSettings() {
        // 1. Reset the Initial Display setting to "Generate Random Fact".
        initialFact = 0
        // 2. Reset the Skip Favorites On Fact Generation setting to off.
        skipFavoritesOnFactGeneration = false
        // 3. Reset the Favorite Fact Randomizer Effect setting to off.
        favoriteFactsRandomizerEffect = false
    }

    // This method removes all Firestore listeners from the app when logging out.
    func removeFirestoreListeners() {
        userReferenceListener?.remove()
        userReferenceListener = nil
        favoriteFactsDatabase?.favoriteFactsListener?.remove()
        favoriteFactsDatabase?.favoriteFactsListener = nil
    }

    // MARK: - Delete User

    // This method deletes the current user's favorite facts, their reference, and then their account.
    func deleteCurrentUser(completionHandler: @escaping (Error?) -> Void) {
        // 1. Make sure we can get the current user.
        guard let user = firebaseAuthentication.currentUser else {
            completionHandler(User.Errors.accountNotFound)
            return
        }
        // 2. Delete all their favorite facts, getting data from the server instead of the cache to ensure proper deletion.
        accountDeletionStage = .data
        favoriteFactsDatabase?.deleteAllFavoriteFactsForCurrentUser(forUserDeletion: true) { [self] error in
            // 3. If that fails, log an error and cancel deletion.
            if let error = error {
                accountDeletionStage = nil
                completionHandler(error)
            } else {
                // 4. If successful, delete the user reference.
                deleteUserReference(forUser: user) { [self] error in
                    // 5. If that fails, log an error and cancel deletion.
                    if let error = error {
                        accountDeletionStage = nil
                        completionHandler(error)
                    } else {
                        // 6. If favorite fact deletion and user reference deletion are successful, all user data has been deleted, so the account can be safely deleted.
                        accountDeletionStage = .account
                        user.delete { [self] error in
                            handleAccountDeletion(for: user, error: error, completionHandler: completionHandler)
                        }
                    }
                }
            }
        }
    }

    // This method deletes user's reference from the database.
    func deleteUserReference(forUser user: User, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure we can get the user's email.
        guard let userEmail = user.email else { return }
        var deletionError: Error?
        // 2. Create a DispatchGroup and delete the user reference the same way we delete all favorite facts.
        let group = DispatchGroup()
        favoriteFactsDatabase?.firestore.collection(Firestore.CollectionName.users)
            .whereField(Firestore.KeyName.email, isEqualTo: userEmail)
            .getDocuments(source: .server) { (snapshot, error) in
                if let error = error {
                    deletionError = error
                } else {
                    if let documents = snapshot?.documents, let document = documents.first {
                        group.enter()
                        document.reference.delete { error in
                            if let error = error {
                                deletionError = error
                            }
                            group.leave()
                        }
                    } else {
                        deletionError = User.Errors.referenceNotFound
                    }
                }
                group.notify(queue: .main) {
                    completionHandler(deletionError)
                }
            }
    }

    func handleAccountDeletion(for user: User, error: Error?, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Set accountDeletionStage to nil after deletion.
        accountDeletionStage = nil
        if error == nil {
            // 2. If account deletion is successful, log the now-deleted user out of this device and reset all login-required settings to their defaults. Other devices will be logged out automatically, either immediately or within an hour after account deletion.
            logoutCurrentUser(completionHandler: completionHandler)
        } else {
            // 3. If an error occurs, the user was unable to be deleted, so try to put back their user reference.
            if let email = user.email {
                addUserReference(email: email, id: user.uid) { addReferenceError in
                    if let addReferenceError = addReferenceError {
                        completionHandler(addReferenceError)
                    } else {
                        completionHandler(error)
                    }
                }
            } else {
                completionHandler(error)
            }
        }
    }

}
