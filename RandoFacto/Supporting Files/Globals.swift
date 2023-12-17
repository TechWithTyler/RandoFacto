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

// MARK: - Type Aliases

typealias Authentication = Auth

// MARK: - Properties - Strings

// The application name.
let appName: String? = (Bundle.main.infoDictionary![String(kCFBundleNameKey)] as? String)!

// Displayed while the app is loading.
let loadingString = "Loading…"

// Displayed while the settings window is loading or authentication is in progress.
let pleaseWaitString = "Please wait…"

// Displayed when generating a random fact.
let generatingRandomFactString = "Generating random fact…"

// Displayed when a FactGenerator error occurs.
let factUnavailableString = "Fact unavailable. Please try again later."

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

// The name of the filled-circle exclamation mark SF Symbol used for errors.
let errorSymbolName = "exclamationmark.circle.fill"

// The name of the collection containing all registered users in the Firestore database.
let usersFirestoreCollectionName = "users"

// The name of the collection containing favorite facts in the Firestore database.
let favoriteFactsFirestoreCollectionName = "favoriteFacts"

// The key name of a fact's text in the Firestore database.
let factTextFirestoreKeyName = "text"

// The key name of a fact's associated user.
let userFirestoreKeyName = "user"

// The key name of a registered user's email.
let emailFirestoreKeyName = "email"

// MARK: - Properties - Doubles

// The app's minimum font size.
var minFontSize: Double = 14

// The app's maximum font size.
var maxFontSize: Double = 48
