//
//  ViewablePasswordField.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct ViewablePasswordField: View {

	var label: String

	@Binding var text: String

	@State var showPassword: Bool = false

	var signup: Bool

	init(_ label: String, text: Binding<String>, signup: Bool) {
		self.label = label
		self._text = text
		self.signup = signup
	}

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
                Label(showPassword ? "Hide" : "Show", systemImage: showPassword ? "eye.slash" : "eye")
                    .labelStyle(.topIconBottomTitle)
                    .animatedSymbolReplacement()
            }
                .buttonStyle(.borderless)
            #if os(iOS)
                .hoverEffect(.highlight)
            #endif
                .tint(.primary)
        }
    }
}

#Preview {
	@State var password = "password"
	return ViewablePasswordField("Password", text: $password, signup: false)
}

#Preview {
	@State var password = "newpassword"
	return ViewablePasswordField("Password", text: $password, signup: true)
}
