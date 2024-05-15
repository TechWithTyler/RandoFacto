//
//  AuthenticationFormView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI
import Firebase

struct AuthenticationFormView: View {
    
    // MARK: - Properties - Objects
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    @FocusState private var focusedField: Authentication.FormField?
    
    // MARK: - Dismiss
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Authentication Form
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let email = authenticationManager.firebaseAuthentication.currentUser?.email,  authenticationManager.formType == .passwordChange {
                        Text(email)
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                    credentialFields
                    if authenticationManager.formType == .passwordChange {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .symbolRenderingMode(.multicolor)
                                .accessibilityHidden(true)
                            Text("IMPORTANT: Changing your password will log you out of your other devices within an hour.")
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
            .interactiveDismissDisabled()
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
                    Button("Cancel") {
                        dismiss()
                    }
                    .controlSize(.large)
                    .disabled(authenticationManager.isAuthenticating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(authenticationManager.formType?.confirmButtonText ?? Authentication.FormType.login.confirmButtonText) {
                        authenticationManager.performAuthenticationAction { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .controlSize(.large)
                    .disabled(authenticationManager.formInvalid || authenticationManager.isAuthenticating)
                }
            }
        }
        .onAppear {
            switch authenticationManager.formType {
            case .passwordChange:
                focusedField = .password
                authenticationManager.emailFieldText = (authenticationManager.firebaseAuthentication.currentUser?.email)!
            default:
                focusedField = .email
            }
        }
        .onDisappear {
            authenticationManager.dismissForm()
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
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit(of: .text) {
                            focusedField = .password
                        }
                    if authenticationManager.invalidCredentialField == .email {
                        FieldNeedsAttentionView()
                    }
                }
            }
            VStack(alignment: .trailing) {
                ViewablePasswordField("Password", text: $authenticationManager.passwordFieldText, signup: authenticationManager.formType == .signup)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit(of: .text) {
                        guard !authenticationManager.formInvalid else {
                            focusedField = .email
                            return }
                        authenticationManager.performAuthenticationAction { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                if authenticationManager.invalidCredentialField == .password {
                    FieldNeedsAttentionView()
                }
            }
            if authenticationManager.formType == .login && !authenticationManager.emailFieldText.isEmpty && authenticationManager.passwordFieldText.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        authenticationManager.sendPasswordResetLinkToEnteredEmailAddress()
                    } label: {
                        Label(forgotPasswordButtonTitle, systemImage: "questionmark.circle.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .frame(alignment: .trailing)
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

#Preview("Login (Empty)") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            authenticationManager.formType = .login
        }
    #endif
}

#Preview("Login (Forgot Password Button)") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            authenticationManager.formType = .login
            authenticationManager.emailFieldText = "someone@example.com"
        }
    #endif
}

#Preview("Login (Forgot Password Sent)") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            authenticationManager.formType = .login
            authenticationManager.emailFieldText = "someone@example.com"
            authenticationManager.showingResetPasswordEmailSent = true
        }
    #endif
}

#Preview("Signup") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            authenticationManager.formType = .signup
        }
    #endif
}

#Preview("Change Password") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager in
            if !authenticationManager.userLoggedIn {
                authenticationManager.formType = .login
                authenticationManager.formErrorText = "Change Password preview requires you to be logged in. You can login here using Live Preview mode and try again."
            } else {
                authenticationManager.formType = .passwordChange
            }
        }
    #endif
}
