//
//  VisualEffectView.swift
//  RandoFacto
//
//  Created by TechWithTyler on 1/10/23.
//

import SwiftUI

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {

	func makeNSView(context: Context) -> NSVisualEffectView {
		let visualEffectView = NSVisualEffectView()
		visualEffectView.blendingMode = .behindWindow
		return visualEffectView
	}

	func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
		
	}

}
#endif
