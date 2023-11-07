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

	@State private var isAuthenticating: Bool = false

	var isFormValid: Bool {
		return !email.isEmpty || !password.isEmpty
	}

	// MARK: - Dismiss

	@Environment(\.dismiss) var dismiss

	// MARK: - Authentication Form

	var body: some View {
		NavigationStack {
			Form {
				credentialFields
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
				if isAuthenticating {
					ToolbarItem(placement: .automatic) {
						LoadingIndicator()
					}
				}
					ToolbarItem(placement: .cancellationAction) {
						Button {
							dismiss()
						} label: {
							Text("Cancel")
						}
						.disabled(isAuthenticating)
					}
					ToolbarItem(placement: .confirmationAction) {
						Button {
							if viewModel.authenticationFormType == .signup {
								isAuthenticating = true
								viewModel.signup(email: email, password: password) {
									success in
									isAuthenticating = false
									if success {
										dismiss()
									}
								}
							} else {
								isAuthenticating = true
								viewModel.login(email: email, password: password) {
									success in
									isAuthenticating = false
									if success {
										dismiss()
									}
								}
							}
						} label: {
							Text(viewModel.authenticationFormType == .signup ? "Signup" : "Login")
						}
						.disabled(!isFormValid || isAuthenticating)
					}
				}
		}
		.onDisappear {
			viewModel.credentialErrorText = nil
			viewModel.authenticationFormType = nil
		}
	}

	// MARK: - Credential Fields

	var credentialFields: some View {
		Section {
			HStack {
				TextField("Email", text: $email)
					.textContentType(.username)
#if os(iOS)
					.keyboardType(.emailAddress)
#endif
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
