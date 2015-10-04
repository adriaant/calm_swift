//
//  main.swift
//  calm
//
//  Created by Adriaan Tijsseling on 9/22/14.
//  Copyright (c) 2014 infinite-sushi.com. All rights reserved.
//

import Foundation

if let network = Network(baseDirectory: "/Users/adriaant/CodeBox/calm_swift/calm/sample") {
	Workspace.network = network

	// Construct simple network
	network.addInputModule("input", size: 2)
	network.addModule("intern", size: 3)
	network.addModule("out", size: 2)
	network.connectModuleWithName("input", toModuleWithName: "intern")
	network.connectModuleWithName("intern", toModuleWithName: "out")
	network.connectModuleWithName("out", toModuleWithName: "intern")
	
	print(network, terminator: "")
	network.prepareForLearning()

	// Set input
	network.train(["input": [0.0, 1.0]])
	print(network, terminator: "")
	network.train(["input": [1.0, 0.0]])
	print(network, terminator: "")

	network.prepareForTesting()

	print("Test with [0 1]")
	network.test(["input": [0.0, 1.0]])
	print(network.winnerForModule("out"))
	print("Test with [1 0]")
	network.test(["input": [1.0, 0.0]])
	print(network.winnerForModule("out"))
} else {
	print("Network could not be initialized!")
	abort()
}
