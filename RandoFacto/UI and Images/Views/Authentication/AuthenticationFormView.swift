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
        return authenticationManager.formType == .passwordChange ? authenticationManager.passwordFieldText.isEmpty : authenticationManager.emailFieldText.isEmpty || authenticationManager.passwordFieldText.isEmpty
    }
    
    // MARK: - Dismiss
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Authentication Form
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if authenticationManager.formType == .passwordChange {
                        Text(((authenticationManager.firebaseAuthentication.currentUser?.email)!))
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                    credentialFields
                    if authenticationManager.formType == .passwordChange {
                        HStack {
                            Image(systemName: "info.circle")
                                .accessibilityHidden(true)
                            Text("Changing your password will log you out of your other devices within an hour.")
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                    if authenticationManager.showingResetPasswordEmailSent {
                        AuthenticationMessageView(text: "A password reset email has been sent to \"\(authenticationManager.emailFieldText)\". Follow the instructions to reset your password.", type: .confirmation)
                    }
                    if let errorText = authenticationManager.formErrorText {
                        AuthenticationMessageView(text: errorText, type: .error)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(authenticationManager.formType?.titleText ?? Authentication.FormType.login.titleText)
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
                        authenticationManager.formErrorText = nil
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .disabled(authenticationManager.isAuthenticating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard !authenticationManager.passwordFieldText.containsEmoji else {
                            authenticationManager.formErrorText = "Passwords can't contain emoji."
                            return
                        }
                        authenticationManager.showingResetPasswordEmailSent = false
                        errorManager.errorToShow = nil
                        authenticationManager.formErrorText = nil
                        authenticationManager.emailFieldText = authenticationManager.emailFieldText.lowercased()
                        if authenticationManager.formType == .signup {
                            authenticationManager.signup {
                                success in
                                if success {
                                    dismiss()
                                }
                            }
                        } else if authenticationManager.formType == .passwordChange {
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
                        Text(authenticationManager.formType?.confirmButtonText ?? Authentication.FormType.login.confirmButtonText)
                    }
                    .disabled(isFormInvalid || authenticationManager.isAuthenticating)
                }
            }
        }
        .onAppear {
            if authenticationManager.formType == .passwordChange {
                authenticationManager.emailFieldText = (authenticationManager.firebaseAuthentication.currentUser?.email)!
            }
        }
        .onDisappear {
            authenticationManager.emailFieldText.removeAll()
            authenticationManager.passwordFieldText.removeAll()
            authenticationManager.formErrorText = nil
            authenticationManager.formType = nil
        }
#if os(macOS)
        .frame(minWidth: 495, maxWidth: 495, minHeight: 365, maxHeight: 365)
#endif
    }
    
    // MARK: - Credential Fields
    
    var credentialFields: some View {
        Group {
            if authenticationManager.formType != .passwordChange {
                VStack(alignment: .trailing) {
                    FormTextField("Email", text: $authenticationManager.emailFieldText)
                        .textContentType(.username)
#if os(iOS)
                        .keyboardType(.emailAddress)
#endif
                    if authenticationManager.invalidCredentialField == 0 {
                        FieldNeedsAttentionView()
                    }
                }
            }
            VStack(alignment: .trailing) {
                ViewablePasswordField("Password", text: $authenticationManager.passwordFieldText, signup: authenticationManager.formType == .signup)
                if authenticationManager.invalidCredentialField == 1 {
                    FieldNeedsAttentionView()
                }
                if authenticationManager.formType == .login && !authenticationManager.emailFieldText.isEmpty && authenticationManager.passwordFieldText.isEmpty {
                    Divider()
                    Button {
                        errorManager.errorToShow = nil
                        authenticationManager.showingResetPasswordEmailSent = false
                        authenticationManager.formErrorText = nil
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
        }
        .disabled(authenticationManager.isAuthenticating)
        .onChange(of: authenticationManager.emailFieldText) { value in
            authenticationManager.credentialFieldsChanged()
        }
        .onChange(of: authenticationManager.passwordFieldText) { value in
            authenticationManager.credentialFieldsChanged()
        }
    }
    
}

#Preview {
    AuthenticationFormView()
        .environmentObject(AppStateManager())
        .environmentObject(ErrorManager())
        .environmentObject(NetworkManager())
        .environmentObject(FavoriteFactsDatabase())
        .environmentObject(AuthenticationManager())
}
