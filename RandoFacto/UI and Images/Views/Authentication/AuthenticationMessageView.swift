//
//  AuthenticationMessageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct AuthenticationMessageView: View {

	var text: String

	var type: Authentication.MessageType
    
    var color: Color {
        return type == .confirmation ? .green : .red
    }

    var body: some View {
            HStack {
                Spacer()
                Image(systemName: type == .confirmation ? "checkmark.circle.fill" : errorSymbolName)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, color)
                    .imageScale(.large)
                    .accessibilityHidden(true)
                    .padding(5)
                Text(text)
                    .font(.system(size: 18))
                    .lineLimit(10)
                    .multilineTextAlignment(.leading)
                    .padding(5)
                Spacer()
            }
        .foregroundStyle(color)
        .background(color.opacity(0.25))
        .containerShape(.rect(cornerRadius: SAContainerViewCornerRadius))
    }

}

#Preview {
	AuthenticationMessageView(text: "Success!", type: .confirmation)
        .previewDisplayName("Success")
}

#Preview {
	AuthenticationMessageView(text: "Error!", type: .error)
        .previewDisplayName("Error")
}
