//
//  AuthenticationFormView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI

struct AuthenticationFormView: View {

	// MARK: - Properties - View Model

	@ObservedObject var viewModel: RandoFactoViewModel

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
				credentialFields
				if viewModel.authenticationFormType == .login && !email.isEmpty && password.isEmpty {
					Button(forgotPasswordButtonTitle) {
						viewModel.errorToShow = nil
						viewModel.showingResetPasswordEmailSent = false
						viewModel.credentialErrorText = nil
						viewModel.resetPassword(email: email)
					}
#if os(macOS)
					.buttonStyle(.link)
#endif
				}
				if viewModel.showingResetPasswordEmailSent {
					AuthenticationMessageView(text: "A password reset email has been sent to \"\(email)\". Follow the instructions to reset your password.", type: .confirmation)
				}
				if let errorText = viewModel.credentialErrorText {
					AuthenticationMessageView(text: errorText, type: .error)
				}
			}
			.formStyle(.grouped)
			.padding(.horizontal)
			.navigationTitle(titleText)
#if os(iOS)
			.navigationBarTitleDisplayMode(.automatic)
#endif
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
						viewModel.credentialErrorText = nil
						dismiss()
					} label: {
						Text("Cancel")
					}
					.disabled(viewModel.isAuthenticating)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button {
						viewModel.showingResetPasswordEmailSent = false
						viewModel.errorToShow = nil
						viewModel.credentialErrorText = nil
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
							viewModel.updatePasswordForCurrentUser(newPassword: password) {
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
						Text(confirmButtonText)
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
			viewModel.credentialErrorText = nil
			viewModel.authenticationFormType = nil
		}
#if os(macOS)
		.frame(minWidth: 400, maxWidth: 400, minHeight: 400, maxHeight: 400)
#endif
	}

	var confirmButtonText: String {
		switch viewModel.authenticationFormType {
			case .signup: return "Signup"
			case .passwordChange: return "Update"
			case .none, .login: return "Login"
		}
	}

	var titleText: String {
		switch viewModel.authenticationFormType {
			case .signup: return "Signup"
			case .passwordChange: return "Change Password"
			case .none, .login: return "Login"
		}
	}

	// MARK: - Credential Fields

	var credentialFields: some View {
		Section {
			if viewModel.authenticationFormType != .passwordChange {
				TextField("Email", text: $email)
					.textContentType(.username)
#if os(iOS)
					.keyboardType(.emailAddress)
#endif
			}
			ViewablePasswordField("Password", text: $password, signup: viewModel.authenticationFormType == .signup)
		}
	}

}

#Preview {
	AuthenticationFormView(viewModel: RandoFactoViewModel())
}
