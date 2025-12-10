//
//  AuthenticationFormView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI
import Firebase

struct AuthenticationFormView: View {
    
    // MARK: - Properties - Objects
    
    @EnvironmentObject var windowStateManager: WindowStateManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager
    
    @EnvironmentObject var authenticationDialogManager: AuthenticationDialogManager
    
    @FocusState private var focusedCredentialField: Authentication.FormField?
    
    // MARK: - Properties - Dismiss Action

    @Environment(\.dismiss) var dismiss
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let email = authenticationManager.firebaseAuthentication.currentUser?.email,  authenticationDialogManager.formType == .passwordChange {
                        Text(email)
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                    credentialFields
                    if authenticationDialogManager.formType == .passwordChange {
                        WarningText("Changing your password will log you out of your other devices within an hour.", prefix: .importantUrgent)
                    } else {
                        HStack {
                            Text(authenticationDialogManager.formType == .signup ? "Already have an account?" : "No account yet?")
                            Button(authenticationDialogManager.formType == .signup ? "Login" : "Signup") {
                                authenticationDialogManager.toggleForm()
                            }
#if os(macOS)
                    .buttonStyle(.link)
#endif
                        }
                    }
                    if authenticationDialogManager.showingResetPasswordEmailSent {
                        AuthenticationMessageView(text: "A password reset email has been sent to \"\(authenticationDialogManager.emailFieldText)\". Follow the instructions in the email to reset your password. If you don't see the email from \(appName!), check your spam folder.", type: .confirmation)
                    }
                    if let errorText = authenticationDialogManager.formErrorText {
                        AuthenticationMessageView(text: errorText, type: .error)
                    }
                    if authenticationDialogManager.formType == .signup {
                        WarningText("You need an active email mailbox on your account in order to reset your password in case you forget it.", prefix: .importantUrgent)
                        PrivacyPolicyAgreementText()
                    }
                }
                .animation(.linear, value: authenticationDialogManager.formType)
            }
            .formStyle(.grouped)
            .navigationTitle(authenticationDialogManager.formType?.title ?? Authentication.FormType.login.title)
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
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .controlSize(.large)
                    .disabled(authenticationManager.isAuthenticating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(authenticationDialogManager.formType?.confirmButtonTitle ?? Authentication.FormType.login.confirmButtonTitle) {
                        authenticationDialogManager.submit()
                    }
                    .controlSize(.large)
                    .disabled(authenticationDialogManager.formInvalid || authenticationManager.isAuthenticating)
                }
            }
        }
        .onAppear {
            switch authenticationDialogManager.formType {
            case .passwordChange:
                focusedCredentialField = .password
                authenticationDialogManager.emailFieldText = (authenticationManager.firebaseAuthentication.currentUser?.email)!
            default:
                focusedCredentialField = .email
            }
        }
        .onDisappear {
            authenticationDialogManager.dismissForm()
        }
#if os(macOS)
        .frame(minWidth: 495, maxWidth: 495, minHeight: 365, maxHeight: 365)
#endif
    }
    
    // MARK: - Credential Fields
    
    @ViewBuilder
    var credentialFields: some View {
        Group {
            if authenticationDialogManager.formType != .passwordChange {
                VStack(alignment: .trailing) {
                    FormTextField("Email", text: $authenticationDialogManager.emailFieldText)
                        .textContentType(.username)
#if os(iOS)
                        .keyboardType(.emailAddress)
#endif
                        .submitLabel(.next)
                        .focused($focusedCredentialField, equals: .email)
                        .onSubmit(of: .text) {
                            focusedCredentialField = .password
                        }
                    if authenticationDialogManager.invalidCredentialField == .email {
                        FieldNeedsAttentionView()
                            .onAppear {
                                focusedCredentialField = .email
                            }
                    }
                }
            }
            VStack(alignment: .trailing) {
                ViewablePasswordField("Password", text: $authenticationDialogManager.passwordFieldText, signup: authenticationDialogManager.formType == .signup)
                    .focused($focusedCredentialField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit(of: .text) {
                        authenticationDialogManager.submit()
                    }
                if authenticationDialogManager.formType != .login {
                    PasswordStrengthMeter(password: $authenticationDialogManager.passwordFieldText)
                }
                if authenticationDialogManager.invalidCredentialField == .password {
                    FieldNeedsAttentionView()
                        .onAppear {
                            focusedCredentialField = .password
                        }
                }
            }
            if authenticationDialogManager.formType == .login && !authenticationDialogManager.emailFieldText.isEmpty && authenticationDialogManager.passwordFieldText.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        authenticationDialogManager.showingResetPasswordAlert = true
                    } label: {
                        Label(authenticationDialogManager.showingResetPasswordEmailSent ? "Resend Password Reset" : forgotPasswordButtonTitle, systemImage: "questionmark.circle.fill")
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
        .onChange(of: authenticationDialogManager.emailFieldText) { oldValue, newValue in
            authenticationDialogManager.formErrorText = nil
            authenticationDialogManager.showingResetPasswordEmailSent = false
            authenticationDialogManager.showingResetPasswordAlert = false
        }
        .onChange(of: authenticationDialogManager.passwordFieldText) { oldValue, newValue in
            authenticationDialogManager.formErrorText = nil
            authenticationDialogManager.showingResetPasswordEmailSent = false
            authenticationDialogManager.showingResetPasswordAlert = false
        }
        .alert("Send password reset request to \"\(authenticationDialogManager.emailFieldText)\"?", isPresented: $authenticationDialogManager.showingResetPasswordAlert) {
            Button("Send") {
                authenticationDialogManager.sendPasswordResetLink()
            }
            Button("Cancel", role: .cancel) {
                authenticationDialogManager.showingResetPasswordAlert = false
            }
        } message: {
            Text("By continuing, you confirm that \"\(authenticationDialogManager.emailFieldText)\" is your email address.")
        }
    }

}

// MARK: - Preview

#Preview("Login (Empty)") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { windowStateManager, errorManager, authenticationDialogManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsDisplayManager in
            authenticationDialogManager.formType = .login
        }
    #endif
}

#Preview("Login (Forgot Password Button)") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { windowStateManager, errorManager, authenticationDialogManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsDisplayManager in
            authenticationDialogManager.formType = .login
            authenticationDialogManager.emailFieldText = "someone@example.com"
        }
    #endif
}

#Preview("Login (Forgot Password Sent)") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { windowStateManager, errorManager, authenticationDialogManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsDisplayManager in
            authenticationDialogManager.formType = .login
            authenticationDialogManager.emailFieldText = "someone@example.com"
            authenticationDialogManager.showingResetPasswordEmailSent = true
        }
    #endif
}

#Preview("Signup") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { _, _, authenticationDialogManager, _, _, _, _ in
            authenticationDialogManager.formType = .signup
        }
    #endif
}

#Preview("Change Password") {
    AuthenticationFormView()
        #if DEBUG
        .withPreviewData { _, _, authenticationDialogManager, _, _, authenticationManager, _ in
            if !authenticationManager.userLoggedIn {
                authenticationDialogManager.formType = .login
                authenticationDialogManager.formErrorText = "Change Password preview requires you to be logged in. You can login here using Live Preview mode and try again."
            } else {
                authenticationDialogManager.formType = .passwordChange
            }
        }
    #endif
}

