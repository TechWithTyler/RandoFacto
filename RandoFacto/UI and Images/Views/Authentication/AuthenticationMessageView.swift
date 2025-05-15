//
//  AuthenticationMessageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
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
                    .foregroundStyle(
                        // Frontmost layer
                        .white,
                        // Rearmost layer (red = error, green = success)
                        color)
                    .imageScale(.large)
                    .accessibilityHidden(true)
                    .padding(5)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(text)
                    .font(.system(size: 18))
                    .lineLimit(10)
                    .multilineTextAlignment(.leading)
                    .padding(5)
                Spacer()
            }
        // Use the image circle's color for the text and background.
        .foregroundStyle(color)
        .background(color.opacity(0.25))
        .containerShape(.rect(cornerRadius: SAContainerViewCornerRadius))
    }

}

#Preview("Success") {
	AuthenticationMessageView(text: "Success!", type: .confirmation)
        .padding()
}

#Preview("Error") {
	AuthenticationMessageView(text: "Error!", type: .error)
        .padding()
}
