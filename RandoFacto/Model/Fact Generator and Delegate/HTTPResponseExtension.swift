//
//  HTTPResponseExtension.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/3/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

extension HTTPURLResponse {

	// Whether the HTTP response indicates a failure (the code is not in the 2xx range).
	var isNotSuccessful: Bool {
		return statusCode < 200 || statusCode > 299
	}

}
