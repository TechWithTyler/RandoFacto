//
//  AuthenticationFormType.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 10/27/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import Foundation

extension Authentication {
	
	// Represents a type of authentication form, which determines how the UI should be displayed.
	enum FormType: Identifiable {
        
        // MARK: - Authentication Form Type Definitions

        // The user is signing up for a RandoFacto account.
		case signup

        // The user is logging into their RandoFacto account or resetting their password.
		case login

        // The user is changing the password for their RandoFacto account.
		case passwordChange
        
        // MARK: - Authentication Form Type ID

		// An ID which allows SwiftUI sheets to be presented based on one of the above cases.
		var id: Int {
			return hashValue
		}
        
        // MARK: - Confirm Button Text

		// The text for the form's default button.
		var confirmButtonText: String {
			switch self {
                // "Signup"
				case .signup: return signupText
                // "Login"
                case .login: return loginText
                // "Save"
                case .passwordChange: return "Save"
			}
		}
        
        // MARK: - Title Text

		// The form's title text.
		var titleText: String {
			switch self {
                // "Signup"
				case .signup: return signupText
                // "Login"
                case .login: return loginText
                // "Change Password"
                case .passwordChange: return "Change Password"
			}
		}

	}
}
