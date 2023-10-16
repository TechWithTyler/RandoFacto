//
//  RandoFactoButton.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 10/16/23.
//

import SwiftUI
import SheftAppsStylishUI

struct RandoFactoButton: View {

	var action: (() -> Void)

	var title: String

	init(title: String, action: @escaping () -> Void) {
		self.title = title
		self.action = action
	}

    var body: some View {
		#if os(macOS)
		SAMButtonSwiftUIRepresentable(title: title, action: action)
		#else
		Button(action: action, label: {Text(title)})
		#endif
    }
}

#Preview {
	RandoFactoButton(title: "Button") {
		print("test")
	}
}
