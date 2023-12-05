//
//  RandoFactoManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase
import Network

// This object manages the data storage and authentication in this app.
class RandoFactoManager: ObservableObject {
    
    // MARK: - Properties - Fact Generator
    
    // The fact generator.
    var factGenerator = FactGenerator()
    
    @Published var favoriteFactSearchManager: FavoriteFactSearchManager
    
    // MARK: - Properties - Strings
    
    // The text to display in the fact text view.
    // Properties with the @Published property wrapper will trigger updates to SwiftUI views when they're changed.
    @Published var factText: String = loadingString
    
    // The text to display in the authentication error label in the authentication (login/signup/password change) dialogs.
    @Published var authenticationErrorText: String? = nil
    
    // MARK: - Properties - Integers
    
    // The current fact text size as an Int.
    var fontSizeValue: Int {
        return Int(factTextSize)
    }
    
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
    
    // Whether to display one of the user's favorite facts or generate a random fact when the app launches. This setting resets to 0 (Random Fact), and is hidden, when the user logs out or deletes their account.
    // The @AppStorage property wrapper binds a property to the given UserDefaults key name. Such properties behave the same as UserDefaults get/set properties such as the "5- or 10-frame" setting in SkippyNums, but with the added benefit of automatic UI refreshing.
    @AppStorage("initialFact") var initialFact: Int = 0
    
    // The text size for facts.
    @AppStorage("factTextSize") var factTextSize: Double = minFontSize
    
    // MARK: - Properties - Pages
    
    // The page currently selected in the sidebar/top-level view. On macOS, the settings view is accessed by the Settings menu item in the app menu instead of as a page.
    @Published var selectedPage: AppPage? = .randomFact
    
    #if os(macOS)
    // THe page currently selected in the Settings window on macOS.
    @AppStorage("selectedSettingsPage") var selectedSettingsPage: SettingsPage = .display
    #endif
    
    // MARK: - Properties - Authentication Form Type
    
    // The authentication form to display, or nil if none are to be displayed.
    @Published var authenticationFormType: Authentication.FormType? = nil
    
    // MARK: - Properties - RandoFacto Error
    
    // The error to show to the user as an alert or in the authentication dialog.
    @Published var errorToShow: RandoFactoError?
    
    // MARK: - Properties - Account Deletion Stage
    
    // The current stage of user deletion. Deleting a user deletes their favorite facts and reference first, then their actual account. If the user is still able to login after deletion, the actual account failed to be deleted, so the user reference will be put back.
    @Published var userDeletionStage: User.AccountDeletionStage? = nil
    
    // MARK: - Properties - Booleans
    
    // Whether an error alert should be displayed.
    @Published var showingErrorAlert: Bool = false
    
    // Whether the "logout" alert should be displayed.
    @Published var showingLogout: Bool = false
    
    // Whether the "delete account" alert should be displayed.
    @Published var showingDeleteAccount: Bool = false
    
    // Whether the "delete all favorite facts" alert should be displayed.
    @Published var showingDeleteAllFavoriteFacts: Bool = false
    
    // Whether the AuthenticationFormView should show a confirmation that a password reset email has been sent to the entered email address.
    @Published var showingResetPasswordEmailSent: Bool = false
    
    // Whether the device is online.
    @Published var online: Bool = false
    
    // Whether an authentication request is in progress.
    @Published var isAuthenticating: Bool = false
    
    // Whether favorite facts are available to be displayed.
    var favoriteFactsAvailable: Bool {
        return userLoggedIn && !favoriteFacts.isEmpty && userDeletionStage == nil
    }
    
    // Whether the fact text view is displaying something other than a fact (i.e., a loading or error message).
    var notDisplayingFact: Bool {
        return factText == loadingString || factText == generatingString
    }
    
    // Whether the displayed fact is saved as a favorite.
    var displayedFactIsSaved: Bool {
        return !favoriteFacts.filter({$0.text == factText}).isEmpty
    }
    
    // Whether a user is logged in.
    var userLoggedIn: Bool {
        return firebaseAuthentication.currentUser != nil
    }
    
    // MARK: - Properties - Favorite Facts Array
    
    // The current user's favorite facts loaded from the Firestore database. Storing the data in this array makes getting favorite facts easier than getting the corresponding Firestore data each time, which could cause errors.
    @Published var favoriteFacts: [FavoriteFact] = []
    
    // MARK: - Properties - Network Monitor
    
    // Observes changes to the device's network connection to tell the app whether it should run in online or offline mode.
    private var networkPathMonitor = NWPathMonitor()
    
    // MARK: - Properties - Firebase
    
    // The app's Firestore database.
    private var firestore = Firestore.firestore()
    
    // Listens for changes to the references for registered users.
    var userListener: ListenerRegistration? = nil
    
    // Listens for changes to the current user's favorite facts.
    var favoriteFactsListener: ListenerRegistration? = nil
    
    // Used to get the current user or to perform authentication tasks, such as to login, logout, or delete an account.
    @Published var firebaseAuthentication = Authentication.auth()
    
    // MARK: - Properties - Errors
    
    // The error logged if the RandoFacto database is unable to get the document (data) from the corresponding favorite fact QuerySnapshot.
    private let favoriteFactReferenceError = NSError(domain: "Favorite fact reference not found", code: 144)
    
    // MARK: - Initialization
    
    // This initializer sets up the network path monitor and Firestore listeners, then displays a fact to the user.
    init() {
        favoriteFactSearchManager = FavoriteFactSearchManager()
        // 1. Configure the network path monitor.
        configureNetworkPathMonitor()
        // 2. After waiting a second for the network path monitor to configure and detect the current network connection status, load all the favorite facts into the app.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [self] in
            addRegisteredUsersHandler()
            loadFavoriteFactsForCurrentUser { [self] in
                guard notDisplayingFact else { return }
                // 3. Generate a random fact.
                if initialFact == 0 || favoriteFacts.isEmpty || !userLoggedIn {
                    generateRandomFact()
                } else {
                    getRandomFavoriteFact()
                }
            }
        }
    }
    
    // MARK: - Network - Path Monitor Configuration
    
    // This method configures the network path monitor's path update handler, which tells the app to enable or disable online mode, showing or hiding internet-connection-required UI based on network connection.
    func configureNetworkPathMonitor() {
        // 1. Configure the network path monitor's path update handler.
        networkPathMonitor.pathUpdateHandler = {
            [self] path in
            if path.status == .satisfied {
                // 2. If the path status is satisfied, the device is online, so enable online mode.
                goOnline()
            } else {
                // 3. Otherwise, the device is offline, so enable offline mode.
                goOffline()
            }
        }
        // 4. Start the network path monitor, using a separate DispatchQueue for it.
        let dispatchQueue = DispatchQueue(label: "Network Path Monitor")
        networkPathMonitor.start(queue: dispatchQueue)
    }
    
    // MARK: - Network - Online
    
    // This method enables online mode.
    func goOnline() {
        // 1. Try to enable Firestore's network features.
        firestore.enableNetwork {
            [self] error in
            // 2. If that fails, log an error.
            if let error = error {
                showError(error)
            } else {
                // 3. If successful, tell the app that the device is online.
                // Updating a published property must be done on the main thread, so we use DispatchQueue.main.async to run any code that sets such properties.
                DispatchQueue.main.async { [self] in
                    online = true
                }
            }
        }
    }
    
    // MARK: - Network - Offline
    
    // This method enables offline mode.
    func goOffline() {
        // 1. Try to disable Firestore's network features.
        firestore.disableNetwork {
            [self] error in
            // 2. If that fails, log an error.
            if let error = error {
                showError(error)
            } else {
                // 3. If successful, tell the app that the device is offline.
                DispatchQueue.main.async { [self] in
                    online = false
                }
            }
        }
    }
    
    // MARK: - Fact Generation
    
    // This method tries to access a random facts API URL and parse JSON data it gives back. It then feeds the fact through another API URL to check if it contains inappropriate words. We do it this way so we don't have to include inappropriate words in the app/code itself. If everything is successful, the fact is displayed to the user, or if an error occurs, it's logged.
    func generateRandomFact() {
        // 1. Ask the fact generator to perform its URL requests to generate a random fact.
        factGenerator.generateRandomFact {
            // 2. Display a message before starting fact generation.
            DispatchQueue.main.async { [self] in
                factText = generatingString
            }
        } completionHandler: { [self]
            fact, error in
            DispatchQueue.main.async { [self] in
                if let fact = fact {
                    // 3. If we get a fact, display it.
                    factText = fact
                } else if let error = error {
                    // 4. If an error occurs, log it.
                    factText = factUnavailableString
                    showError(error)
                }
            }
        }
    }
    
}

// This is the extension which contains the favorite facts database functions.
extension RandoFactoManager {
    
    // MARK: - Favorite Facts - Loading
    
    // This method asynchronously loads all the favorite facts associated with the current user. Firestore doesn't have a way to associate data with the user that created it, so we have to add a "user" key to each favorite fact so when a user deletes their account, their favorite facts, but no one else's, are deleted.
    func loadFavoriteFactsForCurrentUser(completionHandler: @escaping (() -> Void)) {
        // 1. Make sure we can get the current user.
        guard userLoggedIn else {
            completionHandler()
            return
        }
        guard let user = firebaseAuthentication.currentUser, let userEmail = user.email else {
            completionHandler()
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
                        showError(error)
                        completionHandler()
                    } else {
                        // 6. If no data can be found, return.
                        guard let snapshot = snapshot else {
                            completionHandler()
                            return
                        }
                        // 7. Check if the snapshot is from the cache (device data for use offline).
                        if snapshot.metadata.isFromCache && online && !notDisplayingFact {
                            // Skip the callback if it's from the cache, the device is online, and a fact is already being displayed.
                            return
                        }
                        // 8. If a change was successfully detected, update the app's favorite facts array.
                        updateFavoriteFactsList(from: snapshot, completionHandler: completionHandler)
                    }
        }
    }
    
    // This method updates the app's favorite facts list with snapshot's data.
    func updateFavoriteFactsList(from snapshot: QuerySnapshot, completionHandler: @escaping (() -> Void)) {
            // 1. Try to replace the data in favoriteFacts with snapshot's data by decoding it to a FavoriteFact object.
            do {
                // compactMap is marked throws so you can call throwing functions in its closure. Errors are then "rethrown" so the catch block of this do statement can handle them.
                favoriteFacts = try snapshot.documents.compactMap { document in
                    // data(as:) handles the decoding of the data, so we don't need to use a Decoder object.
                    return try document.data(as: FavoriteFact.self)
                }
                favoriteFactSearchManager.favoriteFacts = favoriteFacts
            } catch {
                // 2. If that fails, log an error.
                showError(error)
            }
            completionHandler()
    }
    
    // MARK: - Favorite Facts - Display Favorite Fact
    
    // This method gets a random fact from the favorite facts list and sets factText to its text.
    func getRandomFavoriteFact() {
        let favoriteFact = favoriteFacts.randomElement()?.text ?? factUnavailableString
        DispatchQueue.main.async { [self] in
            factText = favoriteFact
        }
    }
    
    // This method displays favorite and switches to the "Random Fact" page.
    func displayFavoriteFact(_ favorite: String) {
        DispatchQueue.main.async { [self] in
            factText = favorite
            dismissFavoriteFacts()
        }
    }
    
    // MARK: - Favorite Facts - Unavailable Handler
    
    // This method switches the current page from favoriteFacts to randomFact if a user logs out or is being deleted.
    func dismissFavoriteFacts() {
        if selectedPage == .favoriteFacts {
            DispatchQueue.main.async { [self] in
                selectedPage = .randomFact
            }
        }
    }
    
    // MARK: - Favorite Facts - Saving/Deleting
    
    // This method creates a FavoriteFact from factText and saves it to the RandoFacto database.
    func saveToFavorites(factText: String) {
        // 1. Make sure the fact doesn't already exist and that the current user has an email (who would have an account but no email?!).
        guard let email = firebaseAuthentication.currentUser?.email else { return }
        let fact = FavoriteFact(text: factText, user: email)
        guard !favoriteFacts.contains(fact) else { return }
        // 2. Create a FavoriteFact object with the fact text and the current user's email, and try to create a new document with that data in the favorite facts Firestore collection.
        do {
            try firestore.collection(favoriteFactsCollectionName).addDocument(from: fact)
        } catch {
            showError(error)
        }
    }
    
    // This method finds a favorite fact in the database and deletes it if its text matches factText.
    func deleteFromFavorites(factText: String) {
        // 1. Get facts with text that matches the given fact text (there should only be 1).
        DispatchQueue.main.async { [self] in
            firestore.collection(favoriteFactsCollectionName)
                .whereField(factTextKeyName, isEqualTo: factText)
                .getDocuments(source: .cache) { [self] snapshot, error in
                    // 2. If that fails, log an error.
                    if let error = error {
                        showError(error)
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
                        showError(error)
                    }
                }
            } else {
                // 4. If we can't get the snapshot or corresponding data, log an error.
                showError(favoriteFactReferenceError)
            }
        }
    }
    
    // This method deletes all of the current user's favorite facts from the database.
    func deleteAllFavoriteFactsForCurrentUser(forUserDeletion deletingUser: Bool = false, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Make sure we can get the current user.
        guard let userEmail = firebaseAuthentication.currentUser?.email else {
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

// This is the extension which contains the authentication/account management functions.
extension RandoFactoManager {
    
    // MARK: - Authentication - Registered Users Handler
    
    // This method sets up the app to listen for changes to registered user references. The email addresses and IDs of registered users get added to a Firestore collection called "users" when they signup, because Firebase doesn't yet have an ability to immediately notify the app of creations/deletions of accounts or checking whether they exist.
    func addRegisteredUsersHandler() {
        DispatchQueue.main.async { [self] in
            // 1. Make sure the current user is logged in.
            guard let currentUser = firebaseAuthentication.currentUser, let email = currentUser.email else {
                logoutCurrentUser()
                return
            }
            // 2. Get all registered users.
            userListener = firestore.collection(usersCollectionName)
            // 3. Filter the results to include only the current user.
                .whereField(emailKeyName, isEqualTo: email)
            // 4. Listen for any changes made to the "users" collection.
                .addSnapshotListener(includeMetadataChanges: true) { [self] documentSnapshot, error in
                    if let error = error {
                        // 5. If that fails, log an error.
                        showError(error)
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
    
    // MARK: - Authentication - Post-Signup/Login Request Handler
    
    // This method loads the user's favorite facts if authentication is successful. Otherwise, it logs an error.
    func handleAuthenticationRequest(with result: AuthDataResult?, error: Error?, isSignup: Bool, successHandler: @escaping ((Bool) -> Void)) {
        // 1. Create the block which will be performed if authentication is successful. This block loads the user's favorite facts, adds the registered users handler, and calls the completion handler.
        let successBlock: (() -> Void) = { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [self] in
                loadFavoriteFactsForCurrentUser { [self] in
                    addRegisteredUsersHandler()
                    isAuthenticating = false
                    successHandler(true)
                }
            }
        }
        // 2. Log an error if unsuccessful.
        if let error = error {
            showError(error)
            isAuthenticating = false
            successHandler(false)
        } else {
            // 3. If successful, add the user reference if signing up, or check for the user reference when logging in, adding it if it doesn't exist. If that's successful, call the success block.
            if isSignup {
                if let email = result?.user.email, let id = result?.user.uid {
                    addUserReference(email: email, id: id) { [self] error in
                        if let error = error {
                            showError(error)
                            successHandler(false)
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
                            showError(error)
                            isAuthenticating = false
                            successHandler(false)
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
    
    // MARK: - Authentication - User References
    
    // This method adds a reference for the current user once they signup or login and such reference is missing.
    func addUserReference(email: String, id: String, completionHandler: @escaping ((Error?) -> Void)) {
        // 1. Create a User.Reference object.
        let userReference = User.Reference(email: email)
        // 2. Try to add the data from this object as a new document whose document ID is that of the user. Matching the document ID with the user ID makes deleting it easier.
        do {
            try firestore.collection(usersCollectionName).document(id).setData(from: userReference)
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
        firestore.collection(usersCollectionName)
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
    
    // MARK: - Authentication - Credential Field Change Handler
    
    func credentialFieldsChanged() {
        errorToShow = nil
        authenticationErrorText = nil
    }
    
    // MARK: - Authentication - Signup
    
    // This method takes the user's credentials and tries to sign them up for a RandoFacto database account.
    func signup(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
        isAuthenticating = true
        firebaseAuthentication.createUser(withEmail: email, password: password) { [self] result, error in
            self.handleAuthenticationRequest(with: result, error: error, isSignup: true, successHandler: successHandler)
        }
    }
    
    // MARK: - Authentication - Login
    
    // This method takes the user's credentials and tries to log them into their RandoFacto database account.
    func login(email: String, password: String, successHandler: @escaping ((Bool) -> Void)) {
        isAuthenticating = true
        firebaseAuthentication.signIn(withEmail: email, password: password) { [self] result, error in
            handleAuthenticationRequest(with: result, error: error, isSignup: false, successHandler: successHandler)
        }
    }
    
    // MARK: - Authentication - Password Reset/Update
    
    // This method sends a password reset email to email. The message body is customized in RandoFacto's Firebase console.
    func sendPasswordResetLink(toEmail email: String) {
        isAuthenticating = true
        firebaseAuthentication.sendPasswordReset(withEmail: email, actionCodeSettings: ActionCodeSettings(), completion: { [self] error in
            isAuthenticating = false
            if let error = error {
                showError(error)
            } else {
                showingResetPasswordEmailSent = true
            }
        })
    }
    
    // This method updates the current user's password to newPassword.
    func updatePasswordForCurrentUser(to newPassword: String, completionHandler: @escaping ((Bool) -> Void)) {
        guard let user = firebaseAuthentication.currentUser else { return }
        isAuthenticating = true
        user.updatePassword(to: newPassword) { [self] error in
            isAuthenticating = false
            if let error = error {
                showError(error)
                completionHandler(false)
            } else {
                completionHandler(true)
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
                favoriteFacts.removeAll()
            }
            initialFact = 0
            userListener?.remove()
            userListener = nil
            favoriteFactsListener?.remove()
            favoriteFactsListener = nil
        } catch {
            // 3. If unsuccessful, log an error.
            showError(error)
        }
    }
    
    // This method logs out the current user after deletion or if their reference goes missing. If the account itself still exists, logging in will put the missing reference back.
    func logoutMissingUser() {
        // 1. Delete all the missing user's favorite facts, getting the data from the server instead of the cache.
        deleteAllFavoriteFactsForCurrentUser(forUserDeletion: true) { [self] error in
            if let error = error {
                // 2. If that fails, log an error.
                showError(error)
                return
            } else {
                // 3. If successful, log the user out.
                logoutCurrentUser()
            }
        }
    }
    
    // MARK: - Authentication - Delete User
    
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
        deleteAllFavoriteFactsForCurrentUser(forUserDeletion: true) { [self] error in
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
        self.firestore.collection(usersCollectionName)
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

// This is the extension that contains the error handling function.
extension RandoFactoManager {
    
    // MARK: - Error Handling
    
    // This method shows error's localizedDescription as an alert or in the authentication form.
    func showError(_ error: Error) {
        DispatchQueue.main.async { [self] in
            // 1. Convert the error to NSError and print it.
            let nsError = error as NSError
            #if DEBUG
            // If an unfamiliar error appears, check its code in the console and add a friendlier message if necessary.
            print("Error: \(nsError)")
            #endif
            // 2. Check the error code to choose which error to show.
            switch nsError.code {
                // Network errors
            case URLError.notConnectedToInternet.rawValue:
                errorToShow = .noInternetFactGeneration
            case AuthErrorCode.networkError.rawValue:
                errorToShow = .noInternetAuthentication
            case URLError.networkConnectionLost.rawValue:
                errorToShow = .networkConnectionLost
            case URLError.timedOut.rawValue:
                errorToShow = .factGenerationTimedOut
                // Fact data errors
            case 33000...33999: /*HTTP response code + 33000 to add 33 (FD) to the beginning*/
                errorToShow = .badHTTPResponse(domain: nsError.domain)
            case FactGenerator.ErrorCode.noText.rawValue:
                errorToShow = .noFactText
            case FactGenerator.ErrorCode.failedToGetData.rawValue:
                errorToShow = .factDataError
                // Database errors
            case FirestoreErrorCode.unavailable.rawValue:
                errorToShow = .randoFactoDatabaseServerDataRetrievalError
            case AuthErrorCode.userNotFound.rawValue:
                errorToShow = .invalidAccount
            case AuthErrorCode.wrongPassword.rawValue:
                errorToShow = .incorrectPassword
            case AuthErrorCode.invalidEmail.rawValue:
                errorToShow = .invalidEmailFormat
            case AuthErrorCode.requiresRecentLogin.rawValue:
                logoutCurrentUser()
                authenticationFormType = nil
                errorToShow = .tooLongSinceLastLogin
            case AuthErrorCode.quotaExceeded.rawValue:
                errorToShow = .randoFactoDatabaseQuotaExceeded
            default:
                // Other errors
                // If we get an error that hasn't been customized with a friendly message, log the localized description as is.
                let reason = nsError.localizedDescription
                errorToShow = .unknown(reason: reason)
            }
            // 3. Show the error in the login/signup dialog if they're open, otherwise show it as an alert.
            if authenticationFormType != nil {
                authenticationErrorText = errorToShow?.errorDescription
            } else {
                showingErrorAlert = true
            }
        }
    }
    
}
