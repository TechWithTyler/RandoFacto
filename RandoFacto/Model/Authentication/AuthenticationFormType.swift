//
//  AuthenticationFormType.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 10/27/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

extension Authentication {
	
	// Represents a type of authentication form.
	enum FormType: Identifiable {
        
        // MARK: - Authentication Form Type Definitions

		case signup

		case login

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
				case .signup: return signupText
				case .passwordChange: return "Save"
				case .login: return loginText
			}
		}
        
        // MARK: - Title Text

		// The form's title text.
		var titleText: String {
			switch self {
				case .signup: return signupText
				case .passwordChange: return "Change Password"
				case .login: return loginText
			}
		}

	}
}
