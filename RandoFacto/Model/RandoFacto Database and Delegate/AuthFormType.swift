//
//  AuthFormType.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 10/27/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

enum AuthFormType: Identifiable {

	case signUp

	case logIn

	var id: Int {
		return hashValue
	}
	
}
