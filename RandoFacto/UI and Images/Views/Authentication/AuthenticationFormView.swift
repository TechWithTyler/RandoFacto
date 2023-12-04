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
    
    @ObservedObject var viewModel: RandoFactoViewModel
    
    // MARK: - Properties - Strings
    
    // The email text field's text.
    @State private var email: String = String()
    
    // The password text field's text.
    @State private var password: String = String()
    
    var isFormInvalid: Bool {
        return viewModel.authenticationManager.authenticationFormType == .passwordChange ? password.isEmpty : email.isEmpty || password.isEmpty
    }
    
    // MARK: - Dismiss
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Authentication Form
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.authenticationManager.authenticationFormType == .passwordChange {
                        Text(((viewModel.authenticationManager.firebaseAuthentication.currentUser?.email)!))
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                    credentialFields
                    if viewModel.authenticationManager.showingResetPasswordEmailSent {
                        AuthenticationMessageView(text: "A password reset email has been sent to \"\(email)\". Follow the instructions to reset your password.", type: .confirmation)
                    }
                    if let errorText = viewModel.authenticationManager.authenticationErrorText {
                        AuthenticationMessageView(text: errorText, type: .error)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(viewModel.authenticationManager.authenticationFormType?.titleText ?? Authentication.FormType.login.titleText)
#if os(iOS)
            .navigationBarTitleDisplayMode(.automatic)
#endif
            .interactiveDismissDisabled(viewModel.authenticationManager.isAuthenticating)
            .toolbar {
                if viewModel.authenticationManager.isAuthenticating {
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
                        viewModel.authenticationManager.showingResetPasswordEmailSent = false
                        viewModel.errorManager.errorToShow = nil
                        viewModel.authenticationManager.authenticationErrorText = nil
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .disabled(viewModel.authenticationManager.isAuthenticating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard !password.containsEmoji else {
                            viewModel.authenticationManager.authenticationErrorText = "Passwords can't contain emoji."
                            return
                        }
                        viewModel.authenticationManager.showingResetPasswordEmailSent = false
                        viewModel.errorManager.errorToShow = nil
                        viewModel.authenticationManager.authenticationErrorText = nil
                        email = email.lowercased()
                        if viewModel.authenticationManager.authenticationFormType == .signup {
                            viewModel.authenticationManager.isAuthenticating = true
                            viewModel.authenticationManager.signup(email: email, password: password) {
                                success in
                                viewModel.authenticationManager.isAuthenticating = false
                                if success {
                                    dismiss()
                                }
                            }
                        } else if viewModel.authenticationManager.authenticationFormType == .passwordChange {
                            viewModel.authenticationManager.isAuthenticating = true
                            viewModel.authenticationManager.updatePasswordForCurrentUser(to: password) {
                                success in
                                viewModel.authenticationManager.isAuthenticating = false
                                if success {
                                    dismiss()
                                }
                            }
                        } else {
                            viewModel.authenticationManager.isAuthenticating = true
                            viewModel.authenticationManager.login(email: email, password: password) {
                                success in
                                viewModel.authenticationManager.isAuthenticating = false
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Text(viewModel.authenticationManager.authenticationFormType?.confirmButtonText ?? Authentication.FormType.login.confirmButtonText)
                    }
                    .disabled(isFormInvalid || viewModel.authenticationManager.isAuthenticating)
                }
            }
        }
        .onAppear {
            if viewModel.authenticationManager.authenticationFormType == .passwordChange {
                email = (viewModel.authenticationManager.firebaseAuthentication.currentUser?.email)!
            }
        }
        .onDisappear {
            password.removeAll()
            viewModel.authenticationManager.authenticationErrorText = nil
            viewModel.authenticationManager.authenticationFormType = nil
        }
#if os(macOS)
        .frame(minWidth: 495, maxWidth: 495, minHeight: 365, maxHeight: 365)
#endif
    }
    
    // MARK: - Credential Fields
    
    var credentialFields: some View {
        Group {
            if viewModel.authenticationManager.authenticationFormType != .passwordChange {
                VStack {
                    FormTextField("Email", text: $email)
                        .textContentType(.username)
#if os(iOS)
                        .keyboardType(.emailAddress)
#endif
                    if viewModel.authenticationManager.invalidCredentialField == 0 {
                        FieldNeedsAttentionView()
                    }
                }
            }
            VStack {
                ViewablePasswordField("Password", text: $password, signup: viewModel.authenticationManager.authenticationFormType == .signup)
                if viewModel.authenticationManager.invalidCredentialField == 1 {
                    FieldNeedsAttentionView()
                }
            }
            if viewModel.authenticationManager.authenticationFormType == .login && !email.isEmpty && password.isEmpty {
                        Button {
                            viewModel.errorManager.errorToShow = nil
                            viewModel.authenticationManager.showingResetPasswordEmailSent = false
                            viewModel.authenticationManager.authenticationErrorText = nil
                            viewModel.authenticationManager.sendPasswordResetLink(toEmail: email)
                        } label: {
                            Label(forgotPasswordButtonTitle, systemImage: "questionmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .disabled(viewModel.authenticationManager.isAuthenticating)
#if os(macOS)
                        .buttonStyle(.link)
#endif
            }
        }
        .disabled(viewModel.authenticationManager.isAuthenticating)
        .onChange(of: email) { value in
            viewModel.authenticationManager.credentialFieldsChanged()
        }
        .onChange(of: password) { value in
            viewModel.authenticationManager.credentialFieldsChanged()
        }
    }
    
}

#Preview {
    AuthenticationFormView(viewModel: RandoFactoViewModel())
}
