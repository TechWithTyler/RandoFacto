//
//  AccountSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct AccountSettingsPageView: View {

    // MARK: - Properties - Objects

    @EnvironmentObject var windowStateManager: WindowStateManager

    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var errorManager: ErrorManager

    @EnvironmentObject var authenticationDialogManager: AuthenticationDialogManager

    // MARK: - Body

    var body: some View {
        Form {
            if let deletionStage = authenticationManager.accountDeletionStage {
                LoadingIndicator(message: "Deleting \(deletionStage)…")
            } else if let email = authenticationManager.firebaseAuthentication.currentUser?.email {
                HStack {
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                        .accessibilityLabel(email)
                    VStack(alignment: .center) {
                        Text("Logged in as")
                        Text(email)
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                if networkConnectionManager.deviceIsOnline {
                        Button("Change Password…", systemImage: "key") {
                            authenticationDialogManager.formType = .passwordChange
                        }
                    .controlSize(.large)
                }
                    Button("Logout…", systemImage: "door.left.hand.open") {
                        authenticationDialogManager.showingLogout = true
                    }
                    .controlSize(.large)
                if networkConnectionManager.deviceIsOnline {
                        Button(role: .destructive) {
                            authenticationDialogManager.showingDeleteAccount = true
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
                    Text("Login to your \(appName!) account to save favorite facts to view on all your devices, even while offline.")
                        .font(.system(size: 24))
                    Button(loginText, systemImage: "entry.lever.keypad") {
                        authenticationDialogManager.formType = .login
                    }
                    .controlSize(.large)
                    Button(signupText, systemImage: "person.crop.circle.fill.badge.plus") {
                        authenticationDialogManager.formType = .signup
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
        .alert("Are you sure you REALLY want to delete your \(appName!) account?", isPresented: $authenticationDialogManager.showingDeleteAccount) {
            Button("Cancel", role: .cancel) {
                authenticationDialogManager.showingDeleteAccount = false
            }
            Button("Delete", role: .destructive) {
                authenticationDialogManager.deleteCurrentUser()
            }
        } message: {
            Text("You won't be able to save favorite facts to view offline! This can't be undone!")
        }
#if os(macOS)
        .dialogSeverity(.critical)
#endif
        // Logout alert
        .alert("Logout of your \(appName!) account?", isPresented: $authenticationDialogManager.showingLogout) {
            Button("Cancel", role: .cancel) {
                authenticationDialogManager.showingLogout = false
            }
            Button("Logout") {
                authenticationDialogManager.logoutCurrentUser()
            }
        } message: {
            Text("All favorite fact-related settings will be reset. You won't be able to save favorite facts to view offline until you login again!")
        }
        // Authentication form
        .sheet(item: $authenticationDialogManager.formType) { _ in
            AuthenticationFormView()
                .environmentObject(networkConnectionManager)
                .environmentObject(authenticationManager)
                .environmentObject(errorManager)
        }
    }

}

// MARK: - Preview

#Preview {
    AccountSettingsPageView()
        #if DEBUG
        .withPreviewData()
    #endif
}
