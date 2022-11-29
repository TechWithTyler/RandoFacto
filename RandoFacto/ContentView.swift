//
//  ContentView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//

import SwiftUI

enum FactGeneratorError: LocalizedError {

	case unknown
	
	case noInternet

	var errorDescription: String? {
		switch self {
			case .noInternet:
				return "No internet connection"
			default:
				return "Unknown error"
		}
	}

}

struct ContentView: View, FactGeneratorDelegate {

	private var factGenerator: FactGenerator {
		return FactGenerator(delegate: self)
	}

	private var generatingString = "Generating Fact…"

	@State private var factText: String = "Fact Text"

	@State private var errorToShow: FactGeneratorError?

	@State private var showingError: Bool = false

	@Environment(\.backgroundMaterial) var material

    var body: some View {
		VStack {
			Text(factText)
				.font(.largeTitle)
			Spacer()
			Button {
				Task {
					await factGenerator.generateRandomFact()
				}
			} label: {
				Text("Generate Random Fact")
			}
			.disabled(factText == generatingString)
		}
		.padding()
		.alert(isPresented: $showingError, error: errorToShow, actions: {
			Button {
				showingError = false
				errorToShow = nil
			} label: {
				Text("OK")
			}
		})
		.onAppear {
			Task {
				await factGenerator.generateRandomFact()
			}
		}
		.backgroundStyle(material!)
    }

	func factGeneratorWillGenerateFact(_ generator: FactGenerator) {
		factText = generatingString
	}

	func factGeneratorWillCheckForProfanity(_ generator: FactGenerator) {
		factText = "Removing profanity…"
	}

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String) {
		factText = fact
		print(fact)
	}

	func factGeneratorDidFail(_ generator: FactGenerator, error: Error) {
		print(error)
		factText = "Fact unavailable"
		let nsError = error as NSError
		if nsError.code == -1009 {
			errorToShow = .noInternet
		} else {
			errorToShow = .unknown
		}
		showingError = true
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
