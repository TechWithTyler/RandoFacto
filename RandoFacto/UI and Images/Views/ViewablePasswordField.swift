//
//  ViewablePasswordField.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/9/23.
//

import SwiftUI

struct ViewablePasswordField: View {

	var label: String

	@Binding var text: String

	@State var showPassword: Bool = false

	init(_ label: String, text: Binding<String>) {
		self.label = label
		self._text = text
	}

    var body: some View {
			if showPassword {
				TextField(label, text: $text)
					.textContentType(.password)
			} else {
				SecureField(label, text: $text)
					.textContentType(.password)
			}
			Toggle("Show Password", isOn: $showPassword)
		#if os(macOS)
			.toggleStyle(.checkbox)
		#endif
    }
}

#Preview {
	@State var password = "password"
	return ViewablePasswordField("Password", text: $password)
}
