//
//  AuthenticationDialogManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/8/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

// Manages UI-related authentication dialog state and delegates actions to AuthenticationManager.
class AuthenticationDialogManager: ObservableObject {

    // MARK: - Properties - Objects

    var authenticationManager: AuthenticationManager

    var errorManager: ErrorManager

    // MARK: - Properties - Strings

    @Published var emailFieldText: String = String()

    @Published var passwordFieldText: String = String()

    @Published var formErrorText: String? = nil

    // MARK: - Properties - Authentication Form Type

    @Published var formType: Authentication.FormType? = nil

    // MARK: - Properties - Booleans

    @Published var showingLogout: Bool = false

    @Published var showingDeleteAccount: Bool = false

    @Published var showingResetPasswordAlert: Bool = false

    @Published var showingResetPasswordEmailSent: Bool = false

    var formInvalid: Bool {
        return formType == .passwordChange ? passwordFieldText.isEmpty : emailFieldText.isEmpty || passwordFieldText.isEmpty
    }

    // MARK: - Properties - Invalid Credential Field

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

    // MARK: - Credential Field Submit Actions

    func submit() {
        // 1. Clear the error text.
        formErrorText = nil
        errorManager.errorToShow = nil
        // 2. Try to perform the authentication action. If it fails, show the corresponding RandoFactoError for the error. If a user is trying to change their password after having been logged in for more than 5 minutes, switch to the login dialog.
        switch formType {
        case .signup:
            authenticationManager.signup(email: emailFieldText, password: passwordFieldText) { [self] error in
                if let error = error {
                    errorManager.showError(error) { [self] randoFactoError in
                        formErrorText = randoFactoError.localizedDescription
                    }
                } else { formType = nil }
            }
        case .login:
            authenticationManager.login(email: emailFieldText, password: passwordFieldText) { [self] error in
                if let error = error {
                    errorManager.showError(error) { [self] randoFactoError in
                        formErrorText = randoFactoError.localizedDescription
                    }
                } else { formType = nil }
            }
        case .passwordChange:
            authenticationManager.changePasswordForCurrentUser(newPassword: passwordFieldText) { [self] error in
                if let error = error {
                    errorManager.showError(error) { [self] randoFactoError in
                        formErrorText = randoFactoError.localizedDescription
                        if randoFactoError == .tooLongSinceLastLogin {
                            formType = .login
                        }
                    }
                } else { formType = nil }
            }
        case .none:
            break
        }
    }

    func sendPasswordResetLink() {
        authenticationManager
            .sendPasswordResetLink(to: emailFieldText) { [self] error in
            if let error = error {
                errorManager.showError(error) { [self] randoFactoError in
                    formErrorText = randoFactoError.localizedDescription
                }
            } else {
                showingResetPasswordEmailSent = true
            }
        }
    }
}
