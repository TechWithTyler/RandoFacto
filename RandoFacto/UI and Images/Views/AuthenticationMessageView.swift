//
//  AuthenticationMessageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct AuthenticationMessageView: View {

	var text: String

	var type: Authentication.MessageType

    var body: some View {
		HStack {
			Image(systemName: type == .confirmation ? "checkmark.circle" : "exclamationmark.triangle")
			Text(text)
				.font(.system(size: 18))
				.lineLimit(10)
				.multilineTextAlignment(.center)
				.padding()
		}
		.foregroundStyle(type == .confirmation ? .green : .red)
    }

}

#Preview {
	AuthenticationMessageView(text: "Success!", type: .confirmation)
}

#Preview {
	AuthenticationMessageView(text: "Error!", type: .error)
}
