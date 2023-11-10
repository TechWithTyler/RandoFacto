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
					Button("Forgot Password") {
						viewModel.errorToShow = nil
						viewModel.showingResetPasswordEmailSent = false
						viewModel.credentialErrorText = nil
						viewModel.resetPassword(email: email)
					}
				}
				if viewModel.showingResetPasswordEmailSent {
					HStack {
						Image(systemName: "checkmark.circle")
						Text("A password reset email has been sent to \(email).")
							.font(.system(size: 18))
							.lineLimit(5)
							.multilineTextAlignment(.center)
							.padding()
					}
					.foregroundColor(.green)
				}
				if let errorText = viewModel.credentialErrorText {
					HStack {
						Image(systemName: "exclamationmark.triangle")
						Text(errorText)
							.font(.system(size: 18))
							.lineLimit(5)
							.multilineTextAlignment(.center)
							.padding()
					}
					.foregroundColor(.red)
				}
			}
			.formStyle(.grouped)
			.padding(.horizontal)
			.keyboardShortcut(.defaultAction)
			.navigationTitle(viewModel.authenticationFormType == .signup ? "Signup" : "Login")
#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
#endif
			.frame(minWidth: 400, minHeight: 400)
			.toolbar {
				if viewModel.isAuthenticating {
					ToolbarItem(placement: .automatic) {
						LoadingIndicator()
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
								viewModel.updatePasswordForCurrentUser(newPassword: password)
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
		.onDisappear {
			viewModel.credentialErrorText = nil
			viewModel.authenticationFormType = nil
		}
	}

	var confirmButtonText: String {
		switch viewModel.authenticationFormType {
			case .signup: return "Signup"
			case .passwordChange: return "Update"
			case .none, .login: return "Login"
		}
	}

	// MARK: - Credential Fields

	var credentialFields: some View {
		Section {
			if viewModel.authenticationFormType != .passwordChange {
				HStack {
					TextField("Email", text: $email)
						.textContentType(.username)
#if os(iOS)
						.keyboardType(.emailAddress)
#endif
				}
			}
			HStack {
				SecureField("Password", text: $password)
					.textContentType(.password)
			}
		}
	}

}

#Preview {
    AuthenticationFormView(viewModel: RandoFactoViewModel())
}
