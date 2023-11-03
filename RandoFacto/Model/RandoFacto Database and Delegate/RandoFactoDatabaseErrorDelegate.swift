//
//  RandoFactoDatabaseDelegate.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

// MARK: - RandoFacto Database Error Delegate

protocol RandoFactoDatabaseErrorDelegate {

	func randoFactoDatabaseNetworkEnableDidFail(_ database: RandoFactoDatabase, error: Error)

	func randoFactoDatabaseNetworkDisableDidFail(_ database: RandoFactoDatabase, error: Error)

	func randoFactoDatabaseDidFailToAddFavorite(_ database: RandoFactoDatabase, fact: String, error: Error)

	func randoFactoDatabaseDidFailToDeleteFavorite(_ database: RandoFactoDatabase, fact: String, error: Error)

	func randoFactoDatabaseLoadingDidFail(_ database: RandoFactoDatabase, error: Error)

	func randoFactoDatabaseDidFailToLogoutUser(_ database: RandoFactoDatabase, userEmail: String, error: Error)

	func randoFactoDatabaseDidFailToDeleteUser(_ database: RandoFactoDatabase, error: Error)

}
