//
//  SettingsView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct SettingsView: View {

	@ObservedObject var viewModel: RandoFactoManager
    
    var sliderText: String {
        return "Fact Text Size: \(viewModel.fontSizeValue)"
    }

    var body: some View {
#if os(macOS)
        TabView(selection: $viewModel.selectedSettingsPage) {
            SAMVisualEffectViewSwiftUIRepresentable {
                Form {
                    accountSection
                }
            }
                .frame(width: 400)
                .fixedSize(horizontal: false, vertical: true)
                .formStyle(.grouped)
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
                .tag(SettingsPage.account)
            SAMVisualEffectViewSwiftUIRepresentable {
                Form {
                    displaySection
                }
            }
                .frame(width: 400)
                .fixedSize(horizontal: false, vertical: true)
                .formStyle(.grouped)
                .tabItem {
                    Label("Display", systemImage: "textformat.size")
                }
                .tag(SettingsPage.display)
        }
#else
        Form {
                accountSection
                displaySection
            Button("Help…") {
                showHelp()
            }
        }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.automatic)
            .formStyle(.grouped)
#endif
    }

	var accountSection: some View {
		Group {
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
                }
                Section {
                    Button("Delete Account…", role: .destructive) {
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
    
    var displaySection: some View {
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
        .formStyle(.grouped)
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
	SettingsView(viewModel: RandoFactoManager())
}
