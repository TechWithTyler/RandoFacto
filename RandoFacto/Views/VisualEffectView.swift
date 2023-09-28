//
//  VisualEffectView.swift
//  RandoFacto
//
//  Created by TechWithTyler on 1/10/23.
//

import SwiftUI

#if os(macOS)
struct VisualEffectView<Content: View>: NSViewRepresentable {

	private let blendingMode: NSVisualEffectView.BlendingMode

	private let content: Content

	init(blendingMode: NSVisualEffectView.BlendingMode = .behindWindow, @ViewBuilder content: () -> Content) {
		self.blendingMode = blendingMode
		self.content = content()
	}

	func makeNSView(context: Context) -> NSVisualEffectView {
		let visualEffectView = NSVisualEffectView()
		visualEffectView.blendingMode = blendingMode
		return visualEffectView
	}

	func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
		// Check if the hosting view already exists
		if let hostingView = nsView.subviews.first as? NSHostingView<Content> {
			// Update the hosting view with the new content
			hostingView.rootView = content
		} else {
			// If it doesn't exist, create a new hosting view and add it as a subview
			let hostingView = NSHostingView(rootView: content)
			hostingView.translatesAutoresizingMaskIntoConstraints = false
			nsView.addSubview(hostingView)
			NSLayoutConstraint.activate([
				hostingView.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
				hostingView.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
				hostingView.topAnchor.constraint(equalTo: nsView.topAnchor),
				hostingView.bottomAnchor.constraint(equalTo: nsView.bottomAnchor)
			])
		}
	}
}

struct VisualEffectView_Previews: PreviewProvider {

	static var previews: some View {
		VisualEffectView {
			Button {
				
			} label: {
				Text("Button")
			}
		}
	}
}
#endif
