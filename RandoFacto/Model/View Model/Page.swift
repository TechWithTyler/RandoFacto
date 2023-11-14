//
//  Page.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

// A page in the app.
// CaseIterable allows you to iterate through an enum's caaes as if it were a collection.
enum Page : String, CaseIterable {
	
	case randomFact

	case favoriteFacts

	case settings

}
