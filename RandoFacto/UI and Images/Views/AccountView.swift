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
#if os(iOS)
					accountSection
			.formStyle(.grouped)
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.automatic)
#else
			TabView {
				accountSection
					.tabItem {
						Label("Account", systemImage: "person.circle")
					}
					.tag(Tab.account)
			}
#endif
    }

	var accountSection: some View {
		Form {
			if viewModel.isDeletingUser {
				HStack {
					LoadingIndicator()
					Text("Deleting account…")
				}
			} else if viewModel.userLoggedIn {
				Section {
					Picker("Fact on Launch", selection: $viewModel.initialFact) {
						Text("Random Fact").tag(0)
						Text("Random Favorite Fact").tag(1)
					}
					.pickerStyle(.menu)
				}
				Section {
					Button("Change Password…") {
						viewModel.authenticationFormType = .passwordChange
					}
				}
				Section {
					Button("Logout") {
						viewModel.logoutCurrentUser()
					}
					Button("Delete Account…") {
						viewModel.showingDeleteAccount = true
					}
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
		.formStyle(.grouped)
		// Delete account alert
		.alert("Delete your account?", isPresented: $viewModel.showingDeleteAccount, actions: {
			Button("Delete", role: .destructive) {
				viewModel.deleteCurrentUser {
					[self] error in
					if let error = error {
						viewModel.showError(error: error)
					}
					viewModel.showingDeleteAccount = false
				}
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
