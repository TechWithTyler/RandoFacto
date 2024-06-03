//
//  AccountSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct AccountSettingsPageView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var errorManager: ErrorManager

    var body: some View {
        Form {
            if let email = authenticationManager.firebaseAuthentication.currentUser?.email {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                        .accessibilityLabel(email)
                    VStack {
                        Text("Logged in as")
                        Text(email)
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                }
            } else {
                Text("Login to your \(appName!) account to save favorite facts to view on all your devices, even while offline.")
                    .font(.system(size: 24))
            }
            if let deletionStage = authenticationManager.accountDeletionStage {
                LoadingIndicator(message: "Deleting \(deletionStage)…")
            } else if authenticationManager.userLoggedIn {
                if networkConnectionManager.deviceIsOnline {
                        Button("Change Password…", systemImage: "key") {
                            authenticationManager.formType = .passwordChange
                        }
                    .controlSize(.large)
                }
                    Button("Logout…", systemImage: "door.left.hand.open") {
                        authenticationManager.showingLogout = true
                    }
                    .controlSize(.large)
                if networkConnectionManager.deviceIsOnline {
                        Button(role: .destructive) {
                            authenticationManager.showingDeleteAccount = true
                        } label: {
                            Label("DELETE ACCOUNT…", systemImage: "person.crop.circle.fill.badge.minus")
#if !os(macOS)
                                .foregroundStyle(.red)
#endif
                        }

                        .controlSize(.large)
                }
            } else {
                if networkConnectionManager.deviceIsOnline {
                    Button(loginText, systemImage: "entry.lever.keypad") {
                        authenticationManager.formType = .login
                    }
                    .controlSize(.large)
                    Button(signupText, systemImage: "person.crop.circle.fill.badge.plus") {
                        authenticationManager.formType = .signup
                    }
                    .controlSize(.large)
                } else {
                    Text("Authentication unavailable. Please check your internet connection.")
                        .font(.system(size: 24))
                }
            }
        }
        .formStyle(.grouped)
        // Delete account alert
        .alert("Are you sure you REALLY want to delete your \(appName!) account?", isPresented: $authenticationManager.showingDeleteAccount) {
            Button("Cancel", role: .cancel) {
                authenticationManager.showingDeleteAccount = false
            }
            Button("Delete", role: .destructive) {
                authenticationManager.deleteCurrentUser {
                    [self] error in
                    if let error = error {
                        DispatchQueue.main.async { [self] in
                            errorManager.showError(error) {
                                randoFactoError in
                                if randoFactoError == .tooLongSinceLastLogin {
                                    authenticationManager.formType = nil
                                    authenticationManager.logoutCurrentUser()
                                    errorManager.showingErrorAlert = true
                                } else {
                                    errorManager.showingErrorAlert = true
                                }
                            }
                        }
                    }
                    authenticationManager.showingDeleteAccount = false
                }
            }
        } message: {
            Text("You won't be able to save favorite facts to view offline! This can't be undone!")
        }
#if os(macOS)
        .dialogSeverity(.critical)
#endif
        // Logout alert
        .alert("Logout of your \(appName!) account?", isPresented: $authenticationManager.showingLogout) {
            Button("Cancel", role: .cancel) {
                authenticationManager.showingLogout = false
            }
            Button("Logout") {
                authenticationManager.logoutCurrentUser()
                authenticationManager.showingLogout = false
            }
        } message: {
            Text("You won't be able to save favorite facts to view offline until you login again!")
        }
        // Authentication form
        .sheet(item: $authenticationManager.formType) {_ in
            AuthenticationFormView()
                .environmentObject(appStateManager)
                .environmentObject(networkConnectionManager)
                .environmentObject(authenticationManager)
                .environmentObject(errorManager)
        }
    }

}

#Preview {
    AccountSettingsPageView()
        #if DEBUG
        .withPreviewData()
    #endif
}
