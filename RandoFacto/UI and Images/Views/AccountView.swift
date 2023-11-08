//
//  AccountView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI

struct AccountView: View {

	@ObservedObject var viewModel: RandoFactoViewModel

    var body: some View {
		Form {
			if viewModel.userLoggedIn {
				Button("Change Password…") {
					viewModel.authenticationFormType = .passwordChange
				}
				Spacer()
				Button("Logout") {
					viewModel.logoutCurrentUser()
				}
				Button("Delete Account…") {
					viewModel.showingDeleteAccount = true
				}
			} else {
				Button("Login") {
					viewModel.authenticationFormType = .login
				}
				Button("Signup") {
					viewModel.authenticationFormType = .signup
				}
			}
		}
		.navigationTitle(viewModel.firebaseAuthentication?.currentUser?.email ?? "Account")
		#if os(iOS)
		.navigationBarTitleDisplayMode(.automatic)
		#endif
		.formStyle(.grouped)
		// Delete account alert
		.alert("Delete your account?", isPresented: $viewModel.showingDeleteAccount, actions: {
			Button("Delete", role: .destructive) {
				viewModel.deleteCurrentUser()
				viewModel.showingDeleteAccount = false
			}
			Button("Cancel", role: .cancel) {
				viewModel.showingDeleteAccount = false
			}
		}, message: {
			Text("You won't be able to save favorite facts to view offline!")
		})
		// Authentication form
		.sheet(item: $viewModel.authenticationFormType, onDismiss: {
			viewModel.authenticationFormType = nil
		}, content: { _ in
			AuthenticationFormView(viewModel: viewModel)
		})
    }
}

#Preview {
	AccountView(viewModel: RandoFactoViewModel())
}
