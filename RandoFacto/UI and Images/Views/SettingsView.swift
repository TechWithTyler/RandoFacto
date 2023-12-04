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

	@ObservedObject var viewModel: RandoFactoViewModel
    
    var sliderText: String {
        return "Fact Text Size: \(viewModel.fontSizeValue)"
    }

    var body: some View {
#if os(macOS)
        TabView(selection: $viewModel.selectedSettingsPage) {
            SAMVisualEffectViewSwiftUIRepresentable {
                    displaySection
            }
            .frame(width: 400, height: viewModel.authenticationManager.userLoggedIn ? 390 : 280)
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
            Text((viewModel.authenticationManager.firebaseAuthentication.currentUser?.email) ?? "Login to your RandoFacto account to save favorite facts to view on all your devices, even while offline.")
				.font(.system(size: 24))
				.fontWeight(.bold)
            if let deletionStage = viewModel.authenticationManager.userDeletionStage {
				LoadingIndicator(text: "Deleting \(deletionStage)…")
            } else if (viewModel.authenticationManager.userLoggedIn) {
				Section {
					Button("Change Password…") {
                        viewModel.authenticationManager.authenticationFormType = .passwordChange
					}
				}
                Section {
                    Button("Logout…") {
                        viewModel.authenticationManager.showingLogout = true
                    }
                }
                Section {
                    Button("Delete Account…", role: .destructive) {
                        viewModel.authenticationManager.showingDeleteAccount = true
					}
				}
			} else {
				Button(loginText) {
                    viewModel.authenticationManager.authenticationFormType = .login
				}
				Button(signupText) {
                    viewModel.authenticationManager.authenticationFormType = .signup
				}
			}
		}
		.formStyle(.grouped)
		// Delete account alert
        .alert("Are you sure you REALLY want to delete your account?", isPresented: $viewModel.authenticationManager.showingDeleteAccount, actions: {
			Button("Cancel", role: .cancel) {
                viewModel.authenticationManager.showingDeleteAccount = false
			}
			Button("Delete", role: .destructive) {
                viewModel.authenticationManager.deleteCurrentUser {
					[self] error in
					if let error = error {
                        viewModel.errorManager.showError(error)
					}
                    viewModel.authenticationManager.showingDeleteAccount = false
				}
			}
		}, message: {
			Text("You won't be able to save favorite facts to view offline! This can't be undone!")
		})
		#if os(macOS)
		.dialogSeverity(.critical)
		#endif
        // Logout alert
        .alert("Logout?", isPresented: $viewModel.authenticationManager.showingLogout, actions: {
            Button("Cancel", role: .cancel) {
                viewModel.authenticationManager.showingLogout = false
            }
            Button("Logout") {
                viewModel.authenticationManager.logoutCurrentUser()
                viewModel.authenticationManager.showingLogout = false
            }
        }, message: {
            Text("You won't be able to save favorite facts to view offline until you login again!")
        })
		// Authentication form
        .sheet(item: $viewModel.authenticationManager.authenticationFormType) {_ in
			AuthenticationFormView(viewModel: viewModel)
		}
	}
    
    var displaySection: some View {
        Form {
            if viewModel.authenticationManager.userLoggedIn {
                Section {
                    Picker("Fact on Launch", selection: $viewModel.initialFact) {
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
                    .font(.system(size: CGFloat(viewModel.factTextSize)))
            }
            .animation(.default, value: viewModel.factTextSize)
            .formStyle(.grouped)
        }
    }
    
    var textSizeSlider: some View {
        Slider(value: $viewModel.factTextSize, in: minFontSize...maxFontSize, step: 1) {
            Text(sliderText)
        } minimumValueLabel: {
            Text("\(Int(minFontSize))")
        } maximumValueLabel: {
            Text("\(Int(maxFontSize))")
        }
        .accessibilityValue("\(viewModel.fontSizeValue)")
    }
    
}

#Preview {
	SettingsView(viewModel: RandoFactoViewModel())
}
