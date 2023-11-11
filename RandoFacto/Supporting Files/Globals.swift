//
//  Globals.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation
import Firebase

typealias Authentication = Auth

// Displayed when generating a random fact.
let generatingString = "Generating random fact…"

// Displayed when a FactGenerator error occurs.
let factUnavailableString = "Fact unavailable"

// The title of the button used to send a password reset email.
let forgotPasswordButtonTitle = "Forgot Password"

// The title of the login dialog/buttons.
let loginText = "Login"

// The title of the signup dialog/buttons.
let signupText = "Signup"

// The collection name of all users.
let usersCollectionName = "users"

// The collection name of the favorite facts collection in a user's Firestore database.
let favoritesCollectionName = "favoriteFacts"

// The key name of a fact's text.
let factTextKeyName = "fact"

// The key name of a fact's associated user.
let userKeyName = "user"
