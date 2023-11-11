//
//  authenticationFormType.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 10/27/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

extension Authentication {
	
	enum FormType: Identifiable {

		case signup

		case login

		case passwordChange

		var id: Int {
			return hashValue
		}

		var confirmButtonText: String {
			switch self {
				case .signup: return signupText
				case .passwordChange: return "Save"
				case .login: return loginText
			}
		}

		var titleText: String {
			switch self {
				case .signup: return signupText
				case .passwordChange: return "Change Password"
				case .login: return loginText
			}
		}

	}
}
