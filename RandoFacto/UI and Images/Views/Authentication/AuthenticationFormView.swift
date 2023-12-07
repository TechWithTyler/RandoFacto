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
    
    // MARK: - Properties - View Model
    
    @ObservedObject var viewModel: RandoFactoManager
    
    // MARK: - Properties - Strings
    
    // The email text field's text.
    @State private var email: String = String()
    
    // The password text field's text.
    @State private var password: String = String()
    
    var isFormInvalid: Bool {
        return viewModel.authenticationFormType == .passwordChange ? password.isEmpty : email.isEmpty || password.isEmpty
    }
    
    // MARK: - Dismiss
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Authentication Form
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.authenticationFormType == .passwordChange {
                        Text(((viewModel.firebaseAuthentication.currentUser?.email)!))
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                    credentialFields
                    if viewModel.showingResetPasswordEmailSent {
                        AuthenticationMessageView(text: "A password reset email has been sent to \"\(email)\". Follow the instructions to reset your password.", type: .confirmation)
                    }
                    if let errorText = viewModel.authenticationErrorText {
                        AuthenticationMessageView(text: errorText, type: .error)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(viewModel.authenticationFormType?.titleText ?? Authentication.FormType.login.titleText)
#if os(iOS)
            .navigationBarTitleDisplayMode(.automatic)
#endif
            .interactiveDismissDisabled(viewModel.isAuthenticating)
            .toolbar {
                if viewModel.isAuthenticating {
                    ToolbarItem(placement: .automatic) {
#if os(macOS)
                        LoadingIndicator(text: "Please wait…")
#else
                        LoadingIndicator()
#endif
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.showingResetPasswordEmailSent = false
                        viewModel.errorManager.errorToShow = nil
                        viewModel.authenticationErrorText = nil
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .disabled(viewModel.isAuthenticating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard !password.containsEmoji else {
                            viewModel.authenticationErrorText = "Passwords can't contain emoji."
                            return
                        }
                        viewModel.showingResetPasswordEmailSent = false
                        viewModel.errorManager.errorToShow = nil
                        viewModel.authenticationErrorText = nil
                        email = email.lowercased()
                        if viewModel.authenticationFormType == .signup {
                            viewModel.signup(email: email, password: password) {
                                success in
                                if success {
                                    dismiss()
                                }
                            }
                        } else if viewModel.authenticationFormType == .passwordChange {
                            viewModel.updatePasswordForCurrentUser(to: password) {
                                success in
                                if success {
                                    dismiss()
                                }
                            }
                        } else {
                            viewModel.login(email: email, password: password) {
                                success in
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Text(viewModel.authenticationFormType?.confirmButtonText ?? Authentication.FormType.login.confirmButtonText)
                    }
                    .disabled(isFormInvalid || viewModel.isAuthenticating)
                }
            }
        }
        .onAppear {
            if viewModel.authenticationFormType == .passwordChange {
                email = (viewModel.firebaseAuthentication.currentUser?.email)!
            }
        }
        .onDisappear {
            email.removeAll()
            password.removeAll()
            viewModel.authenticationErrorText = nil
            viewModel.authenticationFormType = nil
        }
#if os(macOS)
        .frame(minWidth: 495, maxWidth: 495, minHeight: 365, maxHeight: 365)
#endif
    }
    
    // MARK: - Credential Fields
    
    var credentialFields: some View {
        Group {
            if viewModel.authenticationFormType != .passwordChange {
                VStack {
                    FormTextField("Email", text: $email)
                        .textContentType(.username)
#if os(iOS)
                        .keyboardType(.emailAddress)
#endif
                    if viewModel.invalidCredentialField == 0 {
                        FieldNeedsAttentionView()
                    }
                }
            }
            VStack {
                ViewablePasswordField("Password", text: $password, signup: viewModel.authenticationFormType == .signup)
                if viewModel.invalidCredentialField == 1 {
                    FieldNeedsAttentionView()
                }
            }
                    if viewModel.authenticationFormType == .login && !email.isEmpty && password.isEmpty {
                        Button {
                            viewModel.errorManager.errorToShow = nil
                            viewModel.showingResetPasswordEmailSent = false
                            viewModel.authenticationErrorText = nil
                            viewModel.sendPasswordResetLink(toEmail: email)
                        } label: {
                            Label(forgotPasswordButtonTitle, systemImage: "questionmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .disabled(viewModel.isAuthenticating)
#if os(macOS)
                        .buttonStyle(.link)
#endif
            }
        }
        .disabled(viewModel.isAuthenticating)
        .onChange(of: email) { value in
            viewModel.credentialFieldsChanged()
        }
        .onChange(of: password) { value in
            viewModel.credentialFieldsChanged()
        }
    }
    
}

#Preview {
    AuthenticationFormView(viewModel: RandoFactoManager())
}
