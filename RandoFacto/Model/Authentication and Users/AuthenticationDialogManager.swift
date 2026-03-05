//
//  AuthenticationDialogManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import FirebaseAuth

// Manages authentication form/dialog state.
class AuthenticationDialogManager: ObservableObject {
    
    // MARK: - Properties - Objects
    
    var authenticationManager: AuthenticationManager
    
    var errorManager: ErrorManager
    
    // MARK: - Properties - Strings
    
    // The email field's text.
    @Published var emailFieldText: String = String()
    
    // The password field's text.
    @Published var passwordFieldText: String = String()
    
    // The text to display when a RandoFactoError occurs in the authentication dialog.
    @Published var formErrorText: String? = nil

    // MARK: - Properties - Authentication Form Type
    
    // The type of authentication form to be displayed.
    @Published var formType: Authentication.FormType? = nil
    
    // MARK: - Properties - Booleans
    
    // Whether the logout dialog should be/is being displayed.
    @Published var showingLogout: Bool = false
    
    // Whether the "delete account" dialog should be/is being displayed.
    @Published var showingDeleteAccount: Bool = false
    
    // Whether the "send password reset email?" dialog should be/is being displayed.
    @Published var showingResetPasswordAlert: Bool = false
    
    // Whether the "password reset email sent" text should be/is being displayed.
    @Published var showingResetPasswordEmailSent: Bool = false
    
    // Whether the form is invalid (i.e., either the email or password fields are blank).
    var formInvalid: Bool {
        let emailOrPasswordEmpty = emailFieldText.isEmpty || passwordFieldText.isEmpty
        let passwordEmpty = passwordFieldText.isEmpty
        return formType == .passwordChange ? passwordEmpty : emailOrPasswordEmpty
    }
    
    // MARK: - Properties - Invalid Credential Field
    
    // The credential field (email or password) containing invalid information.
    var invalidCredentialField: Authentication.FormField? {
        if let errorText = formErrorText {
            let emailError = errorText.lowercased().contains("email")
            let passwordError = errorText.lowercased().contains("password")
            if emailError { return .email }
            if passwordError { return .password }
        }
        return nil
    }
    
    // MARK: - Initialization
    
    init(authenticationManager: AuthenticationManager,
         errorManager: ErrorManager) {
        self.authenticationManager = authenticationManager
        self.errorManager = errorManager
    }
    
    // MARK: - Credential Field Submit Action
    
    // This method submits an authentication request to the AuthenticationManager based on the displayed form.
    func submit() {
        // 1. Clear the error text.
        clearErrorText()
        // 2. Try to perform the authentication action. If it fails, show the corresponding RandoFactoError for the error.
        switch formType {
        case .signup:
            authenticationManager.signup(email: emailFieldText, password: passwordFieldText) { [self] error in
                if let error = error {
                    showErrorInline(error: error)
                } else { handleAuthenticationActionCompletion() }
            }
        case .login:
            authenticationManager.login(email: emailFieldText, password: passwordFieldText) { [self] error in
                if let error = error {
                    showErrorInline(error: error)
                } else { handleAuthenticationActionCompletion() }
            }
        case .passwordChange:
            authenticationManager.changePasswordForCurrentUser(newPassword: passwordFieldText) { [self] error in
                if let error = error {
                    showErrorInline(error: error)
                } else {
                    handleAuthenticationActionCompletion()
                }
            }
        case .none:
            break
        }
    }

    // This method handles login completion.
    func handleAuthenticationActionCompletion() {
        if !authenticationManager.userLoggedIn {
            showErrorInline(error: User.Errors.authenticationActionFailed)
        } else {
            formType = nil
        }
    }

    // This method tells AuthenticationManager to send a password reset link to the entered email address.
    func sendPasswordResetLink() {
        authenticationManager.sendPasswordResetLink(to: emailFieldText) { [self] error in
            if let error = error {
                showErrorInline(error: error)
            } else {
                showingResetPasswordEmailSent = true
            }
        }
    }
    
    // MARK: - Login/Signup Toggle
    
    // This method toggles between the login and signup forms.
    func toggleForm() {
        clearErrorText()
        formType = (formType == .signup) ? .login : .signup
    }
    
    // MARK: - Switch To Login
    
    func switchToLogin() {
        clearErrorText()
        passwordFieldText.removeAll()
        formType = .login
    }
    
    // MARK: - Clear Error Text
    
    // This method clears the error text.
    func clearErrorText() {
        formErrorText = nil
        errorManager.errorToShow = nil
    }

    // MARK: - Logout

    // This method logs the current user out of their account.
    func logoutCurrentUser() {
        // 1. Try to logout the current user.
        authenticationManager.logoutCurrentUser { [self] error in
            if let error = error {
                // 2. If an error occurs, log it.
                errorManager.showError(error)
            }
            // 3. Dismiss the alert.
            showingLogout = false
        }
    }

    // MARK: - Delete User
    
    // This method deletes the current user.
    func deleteCurrentUser() {
        // 1. Try to delete the current user.
        authenticationManager.deleteCurrentUser {
            [self] error in
            if let error = error {
                // 2. If an error occurs, show it.
                errorManager.showError(error)
            }
            // 3. Dismiss the alert.
            showingDeleteAccount = false
        }
    }

    // MARK: - Show Error Inline

    // This method shows error in the authentication dialog.
    func showErrorInline(error: Error) {
        errorManager.showError(error) { [self] randoFactoError in
            formErrorText = randoFactoError.localizedDescription
        }
    }

    // MARK: - Dismiss Form
    
    // This method prepares the authentication dialog for dismissal.
    func dismissForm() {
        // 1. Clear the credential fields.
        emailFieldText.removeAll()
        passwordFieldText.removeAll()
        // 2. Clear the error/reset password email sent text.
        clearErrorText()
        showingResetPasswordEmailSent = false
    }
    
}
