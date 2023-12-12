//
//  AuthenticationFormView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct AuthenticationFormView: View {
    
    // MARK: - Properties - Objects
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var networkManager: NetworkManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    var isFormInvalid: Bool {
        return authenticationManager.authenticationFormType == .passwordChange ? authenticationManager.password.isEmpty : authenticationManager.email.isEmpty || authenticationManager.password.isEmpty
    }
    
    // MARK: - Dismiss
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Authentication Form
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if authenticationManager.authenticationFormType == .passwordChange {
                        Text(((authenticationManager.firebaseAuthentication.currentUser?.email)!))
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                    credentialFields
                    if authenticationManager.authenticationFormType == .passwordChange {
                        HStack {
                            Image(systemName: "info.circle")
                                .accessibilityHidden(true)
                            Text("Changing your password will log you out of your other devices within an hour.")
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                    if authenticationManager.showingResetPasswordEmailSent {
                        AuthenticationMessageView(text: "A password reset email has been sent to \"\(authenticationManager.email)\". Follow the instructions to reset your password.", type: .confirmation)
                    }
                    if let errorText = authenticationManager.authenticationErrorText {
                        AuthenticationMessageView(text: errorText, type: .error)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(authenticationManager.authenticationFormType?.titleText ?? Authentication.FormType.login.titleText)
#if os(iOS)
            .navigationBarTitleDisplayMode(.automatic)
#endif
            .interactiveDismissDisabled(authenticationManager.isAuthenticating)
            .toolbar {
                if authenticationManager.isAuthenticating {
                    ToolbarItem(placement: .automatic) {
#if os(macOS)
                        LoadingIndicator(message: pleaseWaitString)
#else
                        LoadingIndicator()
#endif
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        authenticationManager.showingResetPasswordEmailSent = false
                        errorManager.errorToShow = nil
                        authenticationManager.authenticationErrorText = nil
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .disabled(authenticationManager.isAuthenticating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard !authenticationManager.password.containsEmoji else {
                            authenticationManager.authenticationErrorText = "Passwords can't contain emoji."
                            return
                        }
                        authenticationManager.showingResetPasswordEmailSent = false
                        errorManager.errorToShow = nil
                        authenticationManager.authenticationErrorText = nil
                        authenticationManager.email = authenticationManager.email.lowercased()
                        if authenticationManager.authenticationFormType == .signup {
                            authenticationManager.signup {
                                success in
                                if success {
                                    dismiss()
                                }
                            }
                        } else if authenticationManager.authenticationFormType == .passwordChange {
                            authenticationManager.updatePasswordForCurrentUser {
                                success in
                                if success {
                                    dismiss()
                                }
                            }
                        } else {
                            authenticationManager.login {
                                success in
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Text(authenticationManager.authenticationFormType?.confirmButtonText ?? Authentication.FormType.login.confirmButtonText)
                    }
                    .disabled(isFormInvalid || authenticationManager.isAuthenticating)
                }
            }
        }
        .onAppear {
            if authenticationManager.authenticationFormType == .passwordChange {
                authenticationManager.email = (authenticationManager.firebaseAuthentication.currentUser?.email)!
            }
        }
        .onDisappear {
            authenticationManager.email.removeAll()
            authenticationManager.password.removeAll()
            authenticationManager.authenticationErrorText = nil
            authenticationManager.authenticationFormType = nil
        }
#if os(macOS)
        .frame(minWidth: 495, maxWidth: 495, minHeight: 365, maxHeight: 365)
#endif
    }
    
    // MARK: - Credential Fields
    
    var credentialFields: some View {
        Group {
            if authenticationManager.authenticationFormType != .passwordChange {
                VStack {
                    FormTextField("Email", text: $authenticationManager.email)
                        .textContentType(.username)
#if os(iOS)
                        .keyboardType(.emailAddress)
#endif
                    if authenticationManager.invalidCredentialField == 0 {
                        FieldNeedsAttentionView()
                    }
                }
            }
            VStack {
                ViewablePasswordField("Password", text: $authenticationManager.password, signup: authenticationManager.authenticationFormType == .signup)
                if authenticationManager.invalidCredentialField == 1 {
                    FieldNeedsAttentionView()
                }
            }
            if authenticationManager.authenticationFormType == .login && !authenticationManager.email.isEmpty && authenticationManager.password.isEmpty {
                        Button {
                            errorManager.errorToShow = nil
                            authenticationManager.showingResetPasswordEmailSent = false
                            authenticationManager.authenticationErrorText = nil
                            authenticationManager.sendPasswordResetLink()
                        } label: {
                            Label(forgotPasswordButtonTitle, systemImage: "questionmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .disabled(authenticationManager.isAuthenticating)
#if os(macOS)
                        .buttonStyle(.link)
#endif
            }
        }
        .disabled(authenticationManager.isAuthenticating)
        .onChange(of: authenticationManager.email) { value in
            authenticationManager.credentialFieldsChanged()
        }
        .onChange(of: authenticationManager.password) { value in
            authenticationManager.credentialFieldsChanged()
        }
    }
    
}

#Preview {
    AuthenticationFormView()
}
