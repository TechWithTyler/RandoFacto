//
//  AuthenticationFormView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
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
    
    @FocusState private var focusedCredentialField: Authentication.FormField?
    
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
                        WarningText("Changing your password will log you out of your other devices within an hour.", prefix: .importantUrgent)
                    }
                    if authenticationManager.showingResetPasswordEmailSent {
                        AuthenticationMessageView(text: "A password reset email has been sent to \"\(authenticationManager.emailFieldText)\". Follow the instructions in the email to reset your password. If you don't see the email from \(appName!), check your spam folder.", type: .confirmation)
                    }
                    if let errorText = authenticationManager.formErrorText {
                        AuthenticationMessageView(text: errorText, type: .error)
                    }
                    if authenticationManager.formType == .signup {
                        PrivacyPolicyAgreementText()
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
                    Button("Cancel", role: .cancel) {
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
                focusedCredentialField = .password
                authenticationManager.emailFieldText = (authenticationManager.firebaseAuthentication.currentUser?.email)!
            default:
                focusedCredentialField = .email
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
    
    @ViewBuilder
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
                        .focused($focusedCredentialField, equals: .email)
                        .onSubmit(of: .text) {
                            focusedCredentialField = .password
                        }
                    if authenticationManager.invalidCredentialField == .email {
                        FieldNeedsAttentionView()
                            .onAppear {
                                focusedCredentialField = .email
                            }
                    }
                }
            }
            VStack(alignment: .trailing) {
                ViewablePasswordField("Password", text: $authenticationManager.passwordFieldText, signup: authenticationManager.formType == .signup)
                    .focused($focusedCredentialField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit(of: .text) {
                        guard !authenticationManager.formInvalid else {
                            focusedCredentialField = .email
                            return }
                        authenticationManager.performAuthenticationAction { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                if authenticationManager.invalidCredentialField == .password {
                    FieldNeedsAttentionView()
                        .onAppear {
                            focusedCredentialField = .password
                        }
                }
            }
            if authenticationManager.formType == .login && !authenticationManager.emailFieldText.isEmpty && authenticationManager.passwordFieldText.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        authenticationManager.showingResetPasswordAlert = true
                    } label: {
                        Label(authenticationManager.showingResetPasswordEmailSent ? "Resend Password Reset" : forgotPasswordButtonTitle, systemImage: "questionmark.circle.fill")
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
            authenticationManager.clearAuthenticationMessages()
        }
        .onChange(of: authenticationManager.passwordFieldText) { value in
            authenticationManager.clearAuthenticationMessages()
        }
        .alert("Send password reset request to \"\(authenticationManager.emailFieldText)\"?", isPresented: $authenticationManager.showingResetPasswordAlert) {
            Button("Send") {
                authenticationManager.sendPasswordResetLinkToEnteredEmailAddress()
            }
            Button("Cancel", role: .cancel) {
                authenticationManager.showingResetPasswordAlert = false
            }
        } message: {
            Text("By continuing, you confirm that \"\(authenticationManager.emailFieldText)\" is your email address.")
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
