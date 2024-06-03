//
//  AuthenticationManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase

// Handles authentication and user accounts.
class AuthenticationManager: ObservableObject {
    
    // MARK: - Properties - Objects
    
    @Published var firebaseAuthentication: Authentication
    
    var favoriteFactsDatabase: FavoriteFactsDatabase? = nil
    
    var networkConnectionManager: NetworkConnectionManager
    
    var errorManager: ErrorManager
    
    // MARK: - Properties - Strings
    
    // The email text field's text.
    @Published var emailFieldText: String = String()
    
    // The password text field's text.
    @Published var passwordFieldText: String = String()
    
    // The text to display in the authentication error label in the authentication (login/signup/password change) dialogs.
    @Published var formErrorText: String? = nil
    
    // MARK: - Properties - Integers
    
    // the credential field pertaining to an authentication error.
    var invalidCredentialField: Authentication.FormField? {
        if let errorText = formErrorText {
            let emailError = errorText.lowercased().contains("email")
            let passwordError = errorText.lowercased().contains("password")
            if emailError {
                return .email
            } else if passwordError {
                return .password
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - Properties - Authentication Form Type
    
    // The authentication form to display, or nil if none are to be displayed.
    @Published var formType: Authentication.FormType? = nil
    
    // MARK: - Properties - Account Deletion Stage
    
    // The current stage of user deletion. Deleting a user deletes their favorite facts and reference first, then their actual account. If the user is still able to login after deletion, the actual account failed to be deleted, so the user reference will be put back.
    @Published var accountDeletionStage: User.AccountDeletionStage? = nil
    
    // MARK: - Properties - Booleans
    
    // Whether the "logout" alert should be displayed.
    @Published var showingLogout: Bool = false
    
    // Whether the "delete account" alert should be displayed.
    @Published var showingDeleteAccount: Bool = false

    // Whether the "send reset password request" alert should be displayed.
    @Published var showingResetPasswordAlert: Bool = false

    // Whether the AuthenticationFormView should show a confirmation that a password reset email has been sent to the entered email address.
    @Published var showingResetPasswordEmailSent: Bool = false
    
    // Whether an authentication request is in progress.
    @Published var isAuthenticating: Bool = false
    
    // Whether a user is logged in.
    var userLoggedIn: Bool {
        return firebaseAuthentication.currentUser != nil
    }
    
    // Whether the authentication form is invalid (i.e. not completely filled out).
    var formInvalid: Bool {
        return formType == .passwordChange ? passwordFieldText.isEmpty : emailFieldText.isEmpty || passwordFieldText.isEmpty
    }

    // Whether user account deletion is in progress (accountDeletionStage is not nil).
    var isDeletingAccount: Bool {
        return accountDeletionStage != nil
    }

    // MARK: - Properties - Registered Users Listener
    
    // Listens for changes to the references for registered users.
    var registeredUsersListener: ListenerRegistration? = nil
    
    // MARK: - Initialization
    
    init(firebaseAuthentication: Authentication, networkConnectionManager: NetworkConnectionManager, errorManager: ErrorManager) {
        self.firebaseAuthentication = firebaseAuthentication
        self.networkConnectionManager = networkConnectionManager
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
            registeredUsersListener = favoriteFactsDatabase?.firestore.collection(Firestore.CollectionName.users)
            // 3. Filter the results to include only the current user.
                .whereField(Firestore.KeyName.email, isEqualTo: email)
            // 4. Listen for any changes made to the "users" collection.
                .addSnapshotListener(includeMetadataChanges: true) { [self] documentSnapshot, error in
                    if let error = error {
                        // 5. If that fails, log an error.
                        if formType != nil {
                            errorManager.showError(error) { [self] randoFactoError in
                                formErrorText = randoFactoError.localizedDescription
                            }
                        } else {
                            errorManager.showError(error)
                        }
                    } else {
                        // 6. Logout the user if they've been deleted from another device. We need to make sure the snapshot is from the server, not the cache, to prevent the detection of a missing user reference when logging in on a new device for the first time. We also need to make sure a user isn't currently being logged in or deleted on this device, otherwise a missing user would be detected and logged out, causing the operation to never complete.
                        guard !isDeletingAccount && !isAuthenticating else { return }
                        /*
                         A user reference is considered "missing"/the user is considered "deleted" if any of the following are true:
                         * The snapshot or its documents collection is empty.
                         * The snapshot's documents collection doesn't contain the current user's ID.
                         * The snapshot is nil.
                         */
                        if let snapshot = documentSnapshot, !snapshot.metadata.isFromCache, (snapshot.isEmpty || snapshot.documents.isEmpty), !snapshot.documents.contains(where: { document in
                            return document.documentID == currentUser.uid
                        }) {
                            logoutCurrentUser()
                        } else if documentSnapshot == nil {
                            logoutCurrentUser()
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
                addRegisteredUsersHandler()
                favoriteFactsDatabase?.loadFavoriteFactsForCurrentUser()
                isAuthenticating = false
                successHandler(true)
            }
        }
        // 2. Log an error if unsuccessful.
        if let error = error {
            errorManager.showError(error) { [self] randoFactoError in
                formErrorText = randoFactoError.localizedDescription
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
                                formErrorText = randoFactoError.localizedDescription
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
                    addMissingUserReferenceForLogin(email: email, id: id) { [self] error in
                        if let error = error {
                            errorManager.showError(error) { [self] randoFactoError in
                                formErrorText = randoFactoError.localizedDescription
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
    func addMissingUserReferenceForLogin(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
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
        favoriteFactsDatabase?.firestore.collection(Firestore.CollectionName.users)
            .whereField(Firestore.KeyName.email, isEqualTo: email)
            .getDocuments(source: .server) { snapshot, error in
                // 3. If that fails, log an error.
                if let error = error {
                    completionHandler(error)
                } else {
                    // 4. If the reference doesn't exist, call the add reference block, which will call the completion handler.
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

    // This method clears all authentication messages when the credential field values are changed.
    func credentialFieldsChanged() {
        DispatchQueue.main.async { [self] in
            errorManager.errorToShow = nil
            formErrorText = nil
            showingResetPasswordEmailSent = false
        }
    }
    
    // MARK: - Dismiss Form
    
    // This method clears the authentication form for dismissal.
    func dismissForm() {
        DispatchQueue.main.async { [self] in
            emailFieldText.removeAll()
            passwordFieldText.removeAll()
            formErrorText = nil
            showingResetPasswordEmailSent = false
        }
    }
    
    // MARK: - Perform Action
    
    // This method performs the authentication request when pressing the default button in the toolbar or keyboard.
    func performAuthenticationAction(completionHandler: @escaping ((Bool) -> Void)) {
        // 1. Make sure the authentication form is being displayed. This method will never be called unless it's displayed, so we can simply return in the else block.
        guard let formType = formType else {
            completionHandler(false)
            return }
        // 2. Make sure the password doesn't contain emoji. Emoji can only be entered when the password is visible, so we don't allow emojis at all.
        guard !passwordFieldText.containsEmoji else {
            formErrorText = "Passwords can't contain emoji."
            completionHandler(false)
            return
        }
        // 3. Clear all authentication messages.
        showingResetPasswordEmailSent = false
        errorManager.errorToShow = nil
        formErrorText = nil
        // 4. Make the email lowercase before performing the authentication request. Emails are case-insensitive, but this just makes sure the email is always displayed and passed around in the traditional all-lowercase format.
        emailFieldText = emailFieldText.lowercased()
        // 5. Perform the desired authentication request (signup/login/password change) based on formType. The guard-let above is used so the switch statement doesn't need an unused nil case.
        // The delay between when a Firebase method and its completion handler are called is an actual network-based delay, compared to the app's initial loading delay, which is mostly artificial. If there's no internet connection, the completion handler is called immediately with an error. Completion handlers are passed up the call hierarchy until it reaches this method.
        switch formType {
        case .signup:
            signup(successHandler: completionHandler)
        case .login:
            login(successHandler: completionHandler)
        case .passwordChange:
            updatePasswordForCurrentUser(completionHandler: completionHandler)
        }
    }
    
    // MARK: - Signup

    // This method takes the user's credentials and tries to sign them up for a RandoFacto account.
    func signup(successHandler: @escaping ((Bool) -> Void)) {
        DispatchQueue.main.async { [self] in
            // 1. Try to sign the user up for an account with the given credentials.
            isAuthenticating = true
            firebaseAuthentication.createUser(withEmail: emailFieldText, password: passwordFieldText) { [self] result, error in
                // 2. Handle the success or error.
                self.handleAuthenticationRequest(with: result, error: error, isSignup: true, successHandler: successHandler)
            }
        }
    }
    
    // MARK: - Login
    
    // This method takes the user's credentials and tries to log them into their RandoFacto account.
    func login(successHandler: @escaping ((Bool) -> Void)) {
        DispatchQueue.main.async { [self] in
            // 1. Try to log the user in with the given credentials.
            isAuthenticating = true
            firebaseAuthentication.signIn(withEmail: emailFieldText, password: passwordFieldText) { [self] result, error in
                // 2. Handle the success or error.
                handleAuthenticationRequest(with: result, error: error, isSignup: false, successHandler: successHandler)
            }
        }
    }
    
    // MARK: - Logout
    
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
            favoriteFactsDatabase?.favoriteFactsRandomizerEffect = false
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
    
    // MARK: - Password Reset/Update
    
    // This method sends a password reset email to the entered email address. The message body is customized in RandoFacto's Firebase console. The recipient has to click the link in the email to begin the reset process--the email is customized in Firebase to tell the user to ignore it if they didn't send the request.
    func sendPasswordResetLinkToEnteredEmailAddress() {
        DispatchQueue.main.async { [self] in
            // 1. Ask Firebase to send the password reset email to the entered email address.
            isAuthenticating = true
            errorManager.errorToShow = nil
            showingResetPasswordEmailSent = false
            showingResetPasswordAlert = false
            formErrorText = nil
            firebaseAuthentication.sendPasswordReset(withEmail: emailFieldText, actionCodeSettings: ActionCodeSettings(), completion: { [self] error in
                // 2. If an error occurs (e.g., the entered email address doesn't correspond to an account), log it.
                isAuthenticating = false
                if let error = error {
                    errorManager.showError(error) { [self] randoFactoError in
                        formErrorText = randoFactoError.localizedDescription
                    }
                } else {
                    // 3. If successful, show the "reset password email sent" message.
                    showingResetPasswordEmailSent = true
                }
            })
        }
    }
    
    // This method updates the current user's password to the password field's text.
    func updatePasswordForCurrentUser(completionHandler: @escaping ((Bool) -> Void)) {
        // 1. Make sure we can get the current user.
        guard let user = firebaseAuthentication.currentUser else { return }
        DispatchQueue.main.async { [self] in
            // 2. Update user's password to the new password. If unsuccessful, show an error.
            isAuthenticating = true
            user.updatePassword(to: passwordFieldText) { [self] error in
                isAuthenticating = false
                if let error = error {
                    errorManager.showError(error) { [self] randoFactoError in
                        if randoFactoError == .tooLongSinceLastLogin {
                            dismissForm()
                            logoutCurrentUser()
                            errorManager.showingErrorAlert = true
                        }
                        formErrorText = randoFactoError.localizedDescription
                        completionHandler(false)
                    }
                } else {
                    completionHandler(true)
                }
            }
        }
    }
    
    // MARK: - Delete User
    
    // This method deletes the current user's favorite facts, their reference, and then their account.
    func deleteCurrentUser(completionHandler: @escaping (Error?) -> Void) {
        // 1. Make sure we can get the current user.
        guard let user = firebaseAuthentication.currentUser else {
            let userNotFoundError = NSError(domain: ErrorDomain.userAccountNotFound.rawValue, code: ErrorCode.userAccountNotFound.rawValue)
            completionHandler(userNotFoundError)
            return
        }
        // 2. Delete all their favorite facts, getting data from the server instead of the cache.
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
                        // 6. If successful, all user data has been deleted, so the account can be safely deleted.
                        user.delete { [self] error in
                            if error == nil {
                                // 7. If account deletion is successful, log the now-deleted user out of this device and reset all login-required settings to their defaults.
                                logoutCurrentUser()
                            }
                            accountDeletionStage = nil
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
        let userReferenceError = NSError(domain: ErrorDomain.userReferenceNotFound.rawValue, code: ErrorCode.userReferenceNotFound.rawValue)
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
                        self.errorManager.showError(userReferenceError)
                    }
                }
                group.notify(queue: .main) {
                    completionHandler(deletionError)
                }
            }
    }
    
}
