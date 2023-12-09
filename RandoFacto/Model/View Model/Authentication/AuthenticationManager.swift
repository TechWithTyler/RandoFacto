//
//  AuthenticationManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/23.
//

import SwiftUI
import Firebase

// Handles authentication and user accounts.
class AuthenticationManager: ObservableObject {
    
    // MARK: - Properties - Objects
    
    @Published var firebaseAuthentication: Authentication
    
    var favoriteFactsDatabase: FavoriteFactsDatabase? = nil
    
    var networkManager: NetworkManager
    
    var errorManager: ErrorManager
    
    // MARK: - Properties - Strings
    
    // The text to display in the authentication error label in the authentication (login/signup/password change) dialogs.
    @Published var authenticationErrorText: String? = nil
    
    // MARK: - Properties - Integers
    
    // the credential field pertaining to an authentication error.
    var invalidCredentialField: Int? {
        if let errorText = authenticationErrorText {
            let emailError = errorText.lowercased().contains("email")
            let passwordError = errorText.lowercased().contains("password")
            if emailError {
                return 0
            } else if passwordError {
                return 1
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - Properties - Authentication Form Type
    
    // The authentication form to display, or nil if none are to be displayed.
    @Published var authenticationFormType: Authentication.FormType? = nil
    
    // MARK: - Properties - Account Deletion Stage
    
    // The current stage of user deletion. Deleting a user deletes their favorite facts and reference first, then their actual account. If the user is still able to login after deletion, the actual account failed to be deleted, so the user reference will be put back.
    @Published var userDeletionStage: User.AccountDeletionStage? = nil
    
    // MARK: - Properties - Booleans
    
    // Whether the "logout" alert should be displayed.
    @Published var showingLogout: Bool = false
    
    // Whether the "delete account" alert should be displayed.
    @Published var showingDeleteAccount: Bool = false
    
    // Whether the AuthenticationFormView should show a confirmation that a password reset email has been sent to the entered email address.
    @Published var showingResetPasswordEmailSent: Bool = false
    
    // Whether an authentication request is in progress.
    @Published var isAuthenticating: Bool = false
    
    // Whether a user is logged in.
    var userLoggedIn: Bool {
        return firebaseAuthentication.currentUser != nil
    }
    
    // MARK: - Properties - Registered Users Listener
    
    // Listens for changes to the references for registered users.
    var registeredUsersListener: ListenerRegistration? = nil
    
    // MARK: - Initialization
    
    init(firebaseAuthentication: Authentication, networkManager: NetworkManager, errorManager: ErrorManager) {
        self.firebaseAuthentication = firebaseAuthentication
        self.networkManager = networkManager
        self.errorManager = errorManager
        addRegisteredUsersHandler()
    }
    
    // MARK: - Registered Users Handler
    
    // This method sets up the app to listen for changes to registered user references. The email addresses and IDs of registered users get added to a Firestore collection called "users" when they signup, because Firebase doesn't yet have an ability to immediately notify the app of creations/deletions of accounts or checking whether they exist.
    func addRegisteredUsersHandler() {
        DispatchQueue.main.async { [self] in
            // 1. Make sure the current user is logged in.
            guard let currentUser = firebaseAuthentication.currentUser, let email = currentUser.email else {
                logoutCurrentUser()
                return
            }
            // 2. Get all registered users.
            registeredUsersListener = favoriteFactsDatabase?.firestore.collection(usersCollectionName)
            // 3. Filter the results to include only the current user.
                .whereField(emailKeyName, isEqualTo: email)
            // 4. Listen for any changes made to the "users" collection.
                .addSnapshotListener(includeMetadataChanges: true) { [self] documentSnapshot, error in
                    if let error = error {
                        // 5. If that fails, log an error.
                        if authenticationFormType != nil {
                        errorManager.showError(error) { [self] randoFactoError in
                                authenticationErrorText = randoFactoError.localizedDescription
                            }
                        } else {
                            errorManager.showError(error)
                        }
                    } else {
                        // 6. Logout the user if they've been deleted from another device. We need to make sure the snapshot is from the server, not the cache, to prevent the detection of a missing user reference when logging in on a new device for the first time. We also need to make sure a user isn't currently being logged in or deleted on this device, otherwise a missing user would be detected and logged out, causing the operation to never complete.
                        guard userDeletionStage == nil && !isAuthenticating else { return }
                        /*
                         A user reference is considered "missing"/the user is considered "deleted" if any of the following are true:
                         * The snapshot or its documents collection is empty.
                         * The snapshot's documents collection doesn't contain the current user's ID.
                         * The snapshot is nil.
                         */
                        if let snapshot = documentSnapshot, !snapshot.metadata.isFromCache, (snapshot.isEmpty || snapshot.documents.isEmpty), !snapshot.documents.contains(where: { document in
                            return document.documentID == currentUser.uid
                        }) {
                            logoutMissingUser()
                        } else if documentSnapshot == nil {
                            logoutMissingUser()
                        }
                    }
                }
        }
    }
    
    // MARK: - Post-Signup/Login Request Handler
    
    // This method loads the user's favorite facts if authentication is successful. Otherwise, it logs an error.
    func handleAuthenticationRequest(with result: AuthDataResult?, error: Error?, isSignup: Bool, successHandler: @escaping ((Bool) -> Void)) {
        // 1. Create the block which will be performed if authentication is successful. This block loads the user's favorite facts, adds the registered users handler, and calls the completion handler.
        let successBlock: (() -> Void) = { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [self] in
                favoriteFactsDatabase?.loadFavoriteFactsForCurrentUser()
                addRegisteredUsersHandler()
                isAuthenticating = false
                successHandler(true)
            }
        }
        // 2. Log an error if unsuccessful.
        if let error = error {
            errorManager.showError(error) { [self] randoFactoError in
                authenticationErrorText = randoFactoError.localizedDescription
            isAuthenticating = false
            successHandler(false)
            }
        } else {
            // 3. If successful, add the user reference if signing up, or check for the user reference when logging in, adding it if it doesn't exist. If that's successful, call the success block.
            if isSignup {
                if let email = result?.user.email, let id = result?.user.uid {
                    addUserReference(email: email, id: id) { [self] error in
                        if let error = error {
                            errorManager.showError(error) { [self] randoFactoError in
                                authenticationErrorText = randoFactoError.localizedDescription
                                successHandler(false)
                            }
                        } else {
                            successBlock()
                        }
                    }
                } else {
                    isAuthenticating = false
                    successHandler(false)
                }
            } else {
                if let email = result?.user.email, let id = result?.user.uid {
                    addMissingUserReference(email: email, id: id) { [self] error in
                        if let error = error {
                            errorManager.showError(error) { [self] randoFactoError in
                                authenticationErrorText = randoFactoError.localizedDescription
                                isAuthenticating = false
                                successHandler(false)
                            }
                        } else {
                            successBlock()
                        }
                    }
                } else {
                    isAuthenticating = false
                    successHandler(false)
                }
            }
        }
    }
    
    // MARK: - User References
    
    // This method adds a reference for the current user once they signup or login and such reference is missing.
    func addUserReference(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Create a User.Reference object.
        let userReference = User.Reference(email: email)
        // 2. Try to add the data from this object as a new document whose document ID is that of the user. Matching the document ID with the user ID makes deleting it easier.
        do {
            try favoriteFactsDatabase?.firestore.collection(usersCollectionName).document(id).setData(from: userReference)
            completionHandler(nil)
        } catch {
            // 3. If that fails, log an error.
            completionHandler(error)
        }
    }
    
    // This method checks for the current user's reference and adds it if it doesn't exist.
    func addMissingUserReference(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Create the block which will add the missing user reference if needed.
        let addReferenceBlock: ((() -> Void)) = { [self] in
            addUserReference(email: email, id: id) { error in
                if let error = error {
                    completionHandler(error)
                } else {
                    completionHandler(nil)
                }
            }
        }
        // 2. Check if the current user has a reference.
        favoriteFactsDatabase?.firestore.collection(usersCollectionName)
            .whereField(emailKeyName, isEqualTo: email)
            .getDocuments(source: .server) { snapshot, error in
                // 3. If that fails, log an error.
                if let error = error {
                    completionHandler(error)
                } else {
                    // 4. If the reference doesn't exist, call the add reference block.
                    if let snapshot = snapshot, (snapshot.isEmpty || snapshot.documents.isEmpty) {
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
    
    // MARK: - Credential Field Change Handler
    
    func credentialFieldsChanged() {
        DispatchQueue.main.async { [self] in
            errorManager.errorToShow = nil
            authenticationErrorText = nil
        }
    }
    
    // MARK: - Authentication - Signup
    
    // This method takes the user's credentials and tries to sign them up for a RandoFacto database account.
    func signup(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
        DispatchQueue.main.async { [self] in
            isAuthenticating = true
            firebaseAuthentication.createUser(withEmail: email, password: password) { [self] result, error in
                self.handleAuthenticationRequest(with: result, error: error, isSignup: true, successHandler: successHandler)
            }
        }
    }
    
    // MARK: - Authentication - Login
    
    // This method takes the user's credentials and tries to log them into their RandoFacto database account.
    func login(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
        DispatchQueue.main.async { [self] in
            isAuthenticating = true
            firebaseAuthentication.signIn(withEmail: email, password: password) { [self] result, error in
                handleAuthenticationRequest(with: result, error: error, isSignup: false, successHandler: successHandler)
            }
        }
    }
    
    // MARK: - Authentication - Logout
    
    // This method tries to logout the current user, clearing the app's favorite facts list if successful.
    func logoutCurrentUser() {
        do {
            // 1. Try to logout the current user.
            try firebaseAuthentication.signOut()
            // 2. If successful, clear the favorite facts list, remove the user listener and favorite facts listener, and reset the Fact on Launch setting to "Random Fact".
            DispatchQueue.main.async { [self] in
                favoriteFactsDatabase?.favoriteFacts.removeAll()
            }
            favoriteFactsDatabase?.initialFact = 0
            registeredUsersListener?.remove()
            registeredUsersListener = nil
            favoriteFactsDatabase?.favoriteFactsListener?.remove()
            favoriteFactsDatabase?.favoriteFactsListener = nil
        } catch {
            // 3. If unsuccessful, log an error.
            DispatchQueue.main.async { [self] in
                errorManager.showError(error)
            }
        }
    }
    
    // This method logs out the current user after deletion or if their reference goes missing. If the account itself still exists, logging in will put the missing reference back.
    func logoutMissingUser() {
        // 1. Delete all the missing user's favorite facts, getting the data from the server instead of the cache.
        DispatchQueue.main.async { [self] in
            favoriteFactsDatabase?.deleteAllFavoriteFactsForCurrentUser(forUserDeletion: true) { [self] error in
                if let error = error {
                    // 2. If that fails, log an error.
                    errorManager.showError(error)
                    return
                } else {
                    // 3. If successful, log the user out.
                    logoutCurrentUser()
                }
            }
        }
    }
    
    // MARK: - Account Management - Password Reset/Update
    
    // This method sends a password reset email to email. The message body is customized in RandoFacto's Firebase console.
    func sendPasswordResetLink(toEmail email: String) {
        DispatchQueue.main.async { [self] in
            isAuthenticating = true
            firebaseAuthentication.sendPasswordReset(withEmail: email, actionCodeSettings: ActionCodeSettings(), completion: { [self] error in
                isAuthenticating = false
                if let error = error {
                    errorManager.showError(error) { [self] randoFactoError in
                        authenticationErrorText = randoFactoError.localizedDescription
                    }
                } else {
                    showingResetPasswordEmailSent = true
                }
            })
        }
    }
    
    // This method updates the current user's password to newPassword.
    func updatePasswordForCurrentUser(to newPassword: String, completionHandler: @escaping ((Bool) -> Void)) {
        guard let user = firebaseAuthentication.currentUser else { return }
        DispatchQueue.main.async { [self] in
            isAuthenticating = true
            user.updatePassword(to: newPassword) { [self] error in
                isAuthenticating = false
                if let error = error {
                    errorManager.showError(error) { [self] randoFactoError in
                        if randoFactoError == .tooLongSinceLastLogin {
                            authenticationFormType = nil
                            logoutCurrentUser()
                            errorManager.showingErrorAlert = true
                        }
                        authenticationErrorText = randoFactoError.localizedDescription
                        completionHandler(false)
                    }
                } else {
                    completionHandler(true)
                }
            }
        }
    }
    
    // MARK: - Account Management - Delete User
    
    // This method deletes the current user's favorite facts, their reference, and then their account.
    func deleteCurrentUser(completionHandler: @escaping (Error?) -> Void) {
        // 1. Make sure we can get the current user.
        guard let user = firebaseAuthentication.currentUser else {
            let userNotFoundError = NSError(domain: "User not found", code: 545)
            completionHandler(userNotFoundError)
            return
        }
        // 2. Delete all their favorite facts, getting data from the server instead of the cache.
        userDeletionStage = .data
        favoriteFactsDatabase?.deleteAllFavoriteFactsForCurrentUser(forUserDeletion: true) { [self] error in
            // 3. If that fails, log an error and cancel deletion.
            if let error = error {
                userDeletionStage = nil
                completionHandler(error)
            } else {
                // 4. If successful, delete the user reference.
                deleteUserReference(forUser: user) { [self] error in
                    // 5. If that fails, log an error and cancel deletion.
                    if let error = error {
                        userDeletionStage = nil
                        completionHandler(error)
                    } else {
                        // 6. If successful, all user data has been deleted, so the account can be safely deleted.
                        user.delete { [self] error in
                            if error == nil {
                                logoutMissingUser()
                            }
                            userDeletionStage = nil
                            completionHandler(error)
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
        favoriteFactsDatabase?.firestore.collection(usersCollectionName)
            .whereField(emailKeyName, isEqualTo: userEmail)
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
                    }
                }
                group.notify(queue: .main) {
                    completionHandler(deletionError)
                }
            }
    }
    
}
