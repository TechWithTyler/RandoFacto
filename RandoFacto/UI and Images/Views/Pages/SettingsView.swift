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
    
    // MARK: - Properties - Objects

    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var networkManager: NetworkManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    // MARK: - Properties - Fact Text Size Slider Text
    
    var factTextSizeSliderText: String {
        return "Fact Text Size: \(appStateManager.fontSizeValue)"
    }
    
    // MARK: - Body

    var body: some View {
        if appStateManager.isLoading {
#if os(macOS)
            SAMVisualEffectViewSwiftUIRepresentable {
                loadingDisplay
                    .frame(width: 400, height: 280)
            }
            #else
            loadingDisplay
#endif
        } else {
#if os(macOS)
            TabView(selection: $appStateManager.selectedSettingsPage) {
                SAMVisualEffectViewSwiftUIRepresentable {
                    displayPage
                }
                .frame(width: 400, height: authenticationManager.userLoggedIn ? 390 : 280)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.display.rawValue.capitalized, systemImage: "textformat.size")
                }
                .tag(SettingsPage.display)
                SAMVisualEffectViewSwiftUIRepresentable {
                    accountPage
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
                            displayPage
                                .navigationTitle(SettingsPage.display.rawValue.capitalized)
                        }
                        NavigationLink(SettingsPage.account.rawValue.capitalized) {
                            accountPage
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
    }
    
    // MARK: - Display Page
    
    var displayPage: some View {
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
                factTextSizeSlider
#else
                HStack {
                    Text(factTextSizeSliderText)
                    Spacer(minLength: 20)
                    factTextSizeSlider
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
    
    // MARK: - Account Page

	var accountPage: some View {
		Form {
			Text((authenticationManager.firebaseAuthentication.currentUser?.email) ?? "Login to your RandoFacto account to save favorite facts to view on all your devices, even while offline.")
				.font(.system(size: 24))
				.fontWeight(.bold)
			if let deletionStage = authenticationManager.userDeletionStage {
				LoadingIndicator(message: "Deleting \(deletionStage)…")
			} else if authenticationManager.userLoggedIn {
                if networkManager.online {
                    Section {
                        Button("Change Password…") {
                            authenticationManager.formType = .passwordChange
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
                        Button("DELETE ACCOUNT…", role: .destructive) {
                            authenticationManager.showingDeleteAccount = true
                        }
                    }
                }
			} else {
                if networkManager.online {
                    Button(loginText) {
                        authenticationManager.formType = .login
                    }
                    Button(signupText) {
                        authenticationManager.formType = .signup
                    }
                } else {
                    Text("Authentication unavailable. Please check your internet connection.")
                        .font(.system(size: 24))
                }
			}
		}
		.formStyle(.grouped)
		// Delete account alert
		.alert("Are you sure you REALLY want to delete your account?", isPresented: $authenticationManager.showingDeleteAccount) {
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
        .alert("Logout?", isPresented: $authenticationManager.showingLogout) {
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
                .environmentObject(networkManager)
                .environmentObject(authenticationManager)
                .environmentObject(errorManager)
		}
	}
    
    // MARK: - Loading Display
    
    var loadingDisplay: some View {
        Form {
            LoadingIndicator(message: pleaseWaitString)
                .padding()
        }
    }
    
    // MARK: - Fact Text Size Slider
    
    var factTextSizeSlider: some View {
        Slider(value: $appStateManager.factTextSize, in: minFontSize...maxFontSize, step: 1) {
            Text(factTextSizeSliderText)
        } minimumValueLabel: {
            Image(systemName: "textformat.size.smaller")
                .accessibilityLabel("Smaller")
        } maximumValueLabel: {
            Image(systemName: "textformat.size.larger")
                .accessibilityLabel("Larger")
        }
        .accessibilityValue("\(appStateManager.fontSizeValue)")
    }
    
}

#Preview {
	SettingsView()
        .environmentObject(AppStateManager())
        .environmentObject(ErrorManager())
        .environmentObject(NetworkManager())
        .environmentObject(FavoriteFactsDatabase())
        .environmentObject(AuthenticationManager())
        .frame(height: 500)
}
