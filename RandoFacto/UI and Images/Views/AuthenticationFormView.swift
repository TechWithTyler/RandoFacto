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
                if viewModel.authenticationFormType == .passwordChange {
                    Text(((viewModel.firebaseAuthentication.currentUser?.email)!))
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                }
				credentialFields
				if viewModel.authenticationFormType == .login && !email.isEmpty && password.isEmpty {
					Button(forgotPasswordButtonTitle) {
						viewModel.errorToShow = nil
						viewModel.showingResetPasswordEmailSent = false
						viewModel.authenticationErrorText = nil
						viewModel.sendPasswordResetLink(toEmail: email)
					}
#if os(macOS)
					.buttonStyle(.link)
#endif
				}
				if viewModel.showingResetPasswordEmailSent {
					AuthenticationMessageView(text: "A password reset email has been sent to \"\(email)\". Follow the instructions to reset your password.", type: .confirmation)
				}
				if let errorText = viewModel.authenticationErrorText {
					AuthenticationMessageView(text: errorText, type: .error)
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
						viewModel.errorToShow = nil
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
						viewModel.errorToShow = nil
						viewModel.authenticationErrorText = nil
						email = email.lowercased()
						if viewModel.authenticationFormType == .signup {
							viewModel.isAuthenticating = true
							viewModel.signup(email: email, password: password) {
								success in
								viewModel.isAuthenticating = false
								if success {
									dismiss()
								}
							}
						} else if viewModel.authenticationFormType == .passwordChange {
							viewModel.isAuthenticating = true
							viewModel.updatePasswordForCurrentUser(to: password) {
								success in
								viewModel.isAuthenticating = false
								if success {
									dismiss()
								}
							}
						} else {
							viewModel.isAuthenticating = true
							viewModel.login(email: email, password: password) {
								success in
								viewModel.isAuthenticating = false
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
			password.removeAll()
            viewModel.authenticationErrorText = nil
            viewModel.authenticationFormType = nil
		}
#if os(macOS)
		.frame(minWidth: 325, maxWidth: 325, minHeight: 410, maxHeight: 410)
#endif
	}

	// MARK: - Credential Fields

	var credentialFields: some View {
        Section {
            if viewModel.authenticationFormType != .passwordChange {
                HStack {
                    FormTextField("Email", text: $email)
                        .textContentType(.username)
#if os(iOS)
                        .keyboardType(.emailAddress)
#endif
                    if viewModel.invalidCredentialField == 0 {
                        InvalidCredentialsImage()
                    }
                }
            }
            HStack {
                ViewablePasswordField("Password", text: $password, signup: viewModel.authenticationFormType == .signup)
            }
            if viewModel.invalidCredentialField == 0 {
                InvalidCredentialsImage()
            }
        }
	}

}

#Preview {
	AuthenticationFormView(viewModel: RandoFactoManager())
}
