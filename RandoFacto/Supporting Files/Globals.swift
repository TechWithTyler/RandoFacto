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

let generateRandomFactButtonTitle = "Generate Random Fact"

let getRandomFavoriteFactButtonTitle = "Get Random Favorite Fact"

// The title of the button used to send a password reset email.
let forgotPasswordButtonTitle = "Forgot Password"

// The title of the login dialog/buttons.
let loginText = "Login"

// The title of the signup dialog/buttons.
let signupText = "Signup"

// The name of the collection containing all registered users in the Firestore database.
let usersCollectionName = "users"

// The name of the collection containing favorite facts in the Firestore database.
let favoritesCollectionName = "favoriteFacts"

// The key name of a fact's text in the Firestore database.
let factTextKeyName = "text"

// The key name of a fact's associated user.
let userKeyName = "user"

// The key name of a registered user's email.
let emailKeyName = "email"
