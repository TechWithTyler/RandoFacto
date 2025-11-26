//
//  ViewablePasswordField.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct ViewablePasswordField: View {

    // MARK: - Properties - Strings

	var label: String

	@Binding var text: String

    // MARK: - Properties - Booleans

	@State var showPassword: Bool = false

	var signup: Bool

    // MARK: - Initialization

	init(_ label: String, text: Binding<String>, signup: Bool) {
		self.label = label
		self._text = text
		self.signup = signup
	}

    // MARK: - Body

    var body: some View {
        HStack {
            if showPassword {
                    FormTextField(label, text: $text)
                        .textContentType(signup ? nil : .password)
            } else {
                FormSecureField(label, text: $text)
                    .textContentType(signup ? nil : .password)
            }
            Divider()
            Button {
                showPassword.toggle()
            } label: {
                Label(showPassword ? "Hide Password" : "Show Password", systemImage: showPassword ? "eye.slash" : "eye")
                    .frame(height: 24)
                    .font(.system(size: 24))
                    .labelStyle(.iconOnly)
                    .help(showPassword ? "Hide Password" : "Show Password")
                    .animatedSymbolReplacement(magicReplace: true)
            }
                .buttonStyle(.borderless)
            #if os(iOS)
                .hoverEffect(.highlight)
            #endif
                .tint(.primary)
        }
    }

}

// MARK: - Preview

#Preview {
	@Previewable @State var password = "password"
	return ViewablePasswordField("Password", text: $password, signup: false)
}

#Preview {
	@Previewable @State var password = "newpassword"
	return ViewablePasswordField("Password", text: $password, signup: true)
}
