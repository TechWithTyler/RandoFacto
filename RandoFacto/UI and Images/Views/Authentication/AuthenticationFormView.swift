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
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .disabled(authenticationManager.isAuthenticating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        authenticationManager.performAuthenticationAction { success in
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        Text(authenticationManager.formType?.confirmButtonText ?? Authentication.FormType.login.confirmButtonText)
                    }
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
                        .foregroundStyle(authenticationManager.invalidCredentialField == .email ? .red : .primary)
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
                    .foregroundStyle(authenticationManager.invalidCredentialField == .password ? .red : .primary)
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

#Preview {
    AuthenticationFormView()
        .withPreviewData()
}
