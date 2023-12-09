//
//  SettingsView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct SettingsView: View {

    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var networkManager: NetworkManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    var sliderText: String {
        return "Fact Text Size: \(appStateManager.fontSizeValue)"
    }

    var body: some View {
#if os(macOS)
        TabView(selection: $appStateManager.selectedSettingsPage) {
            SAMVisualEffectViewSwiftUIRepresentable {
                    displaySection
            }
            .frame(width: 400, height: authenticationManager.userLoggedIn ? 390 : 280)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.display.rawValue.capitalized, systemImage: "textformat.size")
                }
                .tag(SettingsPage.display)
            SAMVisualEffectViewSwiftUIRepresentable {
                    accountSection
            }
            .frame(width: 400, height: 260)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.account.rawValue.capitalized, systemImage: "person.circle")
                }
                .tag(SettingsPage.account)
        }
#else
        NavigationStack {
            Form {
                Section {
                    NavigationLink(SettingsPage.display.rawValue.capitalized) {
                        displaySection
                            .navigationTitle(SettingsPage.display.rawValue.capitalized)
                    }
                    NavigationLink(SettingsPage.account.rawValue.capitalized) {
                        accountSection
                            .navigationTitle(SettingsPage.account.rawValue.capitalized)
                    }
                }
                Section {
                    Button("Help…") {
                        showHelp()
                    }
                }
            }
        }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.automatic)
            .formStyle(.grouped)
#endif
    }

	var accountSection: some View {
		Form {
			Text((authenticationManager.firebaseAuthentication.currentUser?.email) ?? "Login to your RandoFacto account to save favorite facts to view on all your devices, even while offline.")
				.font(.system(size: 24))
				.fontWeight(.bold)
			if let deletionStage = authenticationManager.userDeletionStage {
				LoadingIndicator(text: "Deleting \(deletionStage)…")
			} else if authenticationManager.userLoggedIn {
                if networkManager.online {
                    Section {
                        Button("Change Password…") {
                            authenticationManager.authenticationFormType = .passwordChange
                        }
                    }
                }
                Section {
                    Button("Logout…") {
                        authenticationManager.showingLogout = true
                    }
                }
                if networkManager.online {
                    Section {
                        Button("Delete Account…", role: .destructive) {
                            authenticationManager.showingDeleteAccount = true
                        }
                    }
                }
			} else {
                if networkManager.online {
                    Button(loginText) {
                        authenticationManager.authenticationFormType = .login
                    }
                    Button(signupText) {
                        authenticationManager.authenticationFormType = .signup
                    }
                } else {
                    Text("Authentication unavailable. Please check your internet connection")
                        .font(.system(size: 24))
                }
			}
		}
		.formStyle(.grouped)
		// Delete account alert
		.alert("Are you sure you REALLY want to delete your account?", isPresented: $authenticationManager.showingDeleteAccount, actions: {
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
                                    authenticationManager.authenticationFormType = nil
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
		}, message: {
			Text("You won't be able to save favorite facts to view offline! This can't be undone!")
		})
		#if os(macOS)
		.dialogSeverity(.critical)
		#endif
        // Logout alert
        .alert("Logout?", isPresented: $authenticationManager.showingLogout, actions: {
            Button("Cancel", role: .cancel) {
                authenticationManager.showingLogout = false
            }
            Button("Logout") {
                authenticationManager.logoutCurrentUser()
                authenticationManager.showingLogout = false
            }
        }, message: {
            Text("You won't be able to save favorite facts to view offline until you login again!")
        })
		// Authentication form
		.sheet(item: $authenticationManager.authenticationFormType) {_ in
			AuthenticationFormView()
                .environmentObject(appStateManager)
                .environmentObject(networkManager)
                .environmentObject(authenticationManager)
                .environmentObject(errorManager)
		}
	}
    
    var displaySection: some View {
        Form {
            if authenticationManager.userLoggedIn {
                Section {
                    Picker("Fact on Launch", selection: $favoriteFactsDatabase.initialFact) {
                        Text(randomFactSettingTitle).tag(0)
                        Text("Random Favorite Fact").tag(1)
                    }
                } footer: {
                    Text("This setting will reset to \"\(randomFactSettingTitle)\" when you logout or delete your account.")
                }
                }
            Section {
#if os(macOS)
                textSizeSlider
#else
                HStack {
                    Text(sliderText)
                    Spacer(minLength: 20)
                    textSizeSlider
                }
#endif
            }
            Section {
                Text("RandoFacto was coded in Swift by Tyler Sheft!")
                    .font(.system(size: CGFloat(appStateManager.factTextSize)))
            }
            .animation(.default, value: appStateManager.factTextSize)
            .formStyle(.grouped)
        }
    }
    
    var textSizeSlider: some View {
        Slider(value: $appStateManager.factTextSize, in: minFontSize...maxFontSize, step: 1) {
            Text(sliderText)
        } minimumValueLabel: {
            Text("\(Int(minFontSize))")
        } maximumValueLabel: {
            Text("\(Int(maxFontSize))")
        }
        .accessibilityValue("\(appStateManager.fontSizeValue)")
    }
    
}

#Preview {
	SettingsView()
}
