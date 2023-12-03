//
//  Globals.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation
import Firebase

// MARK: - Functions

func showHelp() {
    let helpURL = URL(string: "https://techwithtyler20.weebly.com/randofactohelp")!
    #if os(macOS)
    NSWorkspace.shared.open(helpURL)
    #else
    UIApplication.shared.open(helpURL)
    #endif
}

// MARK: - Typealiases

typealias Authentication = Auth

// MARK: - Properties - Strings

// Displayed while the app is loading.
let loadingString = "Loading…"

// Displayed when generating a random fact.
let generatingString = "Generating random fact…"

// Displayed when a FactGenerator error occurs.
let factUnavailableString = "Fact unavailable"

// The title of the button/menu item used to generate a random fact.
let generateRandomFactButtonTitle = "Generate Random Fact"

// The title of the button/menu item used to get a random favorite fact.
let getRandomFavoriteFactButtonTitle = "Get Random Favorite Fact"

// The title of the button used to send a password reset email.
let forgotPasswordButtonTitle = "Forgot Password"

// The title of the "Fact on Launch" option to start the app with a random fact.
let randomFactSettingTitle = "Random Fact"

// The title of the login dialog/buttons.
let loginText = "Login"

// The title of the signup dialog/buttons.
let signupText = "Signup"

// The name of the collection containing all registered users in the Firestore database.
let usersCollectionName = "users"

// The name of the collection containing favorite facts in the Firestore database.
let favoriteFactsCollectionName = "favoriteFacts"

// The key name of a fact's text in the Firestore database.
let factTextKeyName = "text"

// The key name of a fact's associated user.
let userKeyName = "user"

// The key name of a registered user's email.
let emailKeyName = "email"

let errorSymbolName = "exclamationmark.circle.fill"

// MARK: - Properties - Doubles

var minFontSize: Double = 14

var maxFontSize: Double = 48
