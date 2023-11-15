//
//  SettingsView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI

struct SettingsView: View {

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
					.tag(Page.settings)
			}
#endif
    }

	var accountSection: some View {
		Form {
			Text((viewModel.firebaseAuthentication.currentUser?.email) ?? "Login to your RandoFacto account to save favorite facts to view on all your devices, even while offline.")
				.font(.system(size: 24))
				.fontWeight(.bold)
			if let deletionStage = viewModel.userDeletionStage {
				LoadingIndicator(text: "Deleting \(deletionStage)…")
			} else if viewModel.userLoggedIn {
				Section {
					Picker("Fact on Launch", selection: $viewModel.initialFact) {
						Text("Random Fact").tag(0)
						Text("Random Favorite Fact").tag(1)
					}
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
				Button(loginText) {
					viewModel.authenticationFormType = .login
				}
				Button(signupText) {
					viewModel.authenticationFormType = .signup
				}
			}
		}
		.formStyle(.grouped)
		// Delete account alert
		.alert("Delete your account?", isPresented: $viewModel.showingDeleteAccount, actions: {
			Button("Cancel", role: .cancel) {
				viewModel.showingDeleteAccount = false
			}
			Button("Delete", role: .destructive) {
				viewModel.deleteCurrentUser {
					[self] error in
					if let error = error {
						viewModel.showError(error)
					}
					viewModel.showingDeleteAccount = false
				}
			}
		}, message: {
			Text("You won't be able to save favorite facts to view offline!")
		})
		#if os(macOS)
		.dialogSeverity(.critical)
		#endif
		// Authentication form
		.sheet(item: $viewModel.authenticationFormType) {_ in 
			AuthenticationFormView(viewModel: viewModel)
		}
	}
}

#Preview {
	SettingsView(viewModel: RandoFactoViewModel())
}
