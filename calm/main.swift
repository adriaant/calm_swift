//
//  main.swift
//  calm
//
//  Created by Adriaan Tijsseling on 9/22/14.
//  Copyright (c) 2014 infinite-sushi.com. All rights reserved.
//

import Foundation

if let network = Network(baseDirectory: "/Users/adriaant/CodeBox/calm_swift/calm/sample") {
	println("We got a CALM network...")
	println("UP parameter value is: \(network.parameters[.UP])")
	Workspace.network = network

	// Construct simple network
	network.addInputModule("input", size: 2)
	network.addModule("intern", size: 3)
	network.addModule("out", size: 2)
	network.connectModuleWithName("input", toModuleWithName: "intern")
	network.connectModuleWithName("intern", toModuleWithName: "out")
	network.connectModuleWithName("out", toModuleWithName: "intern")
	
	print(network)
	network.prepareForLearning()

	// Set input
	network.train(["input": [0.0, 1.0]])
	print(network)
	network.train(["input": [1.0, 0.0]])
	print(network)

	network.prepareForTesting()

	println("Test with [0 1]")
	network.test(["input": [0.0, 1.0]])
	println(network.winnerForModule("out"))
	println("Test with [1 0]")
	network.test(["input": [1.0, 0.0]])
	println(network.winnerForModule("out"))
} else {
	println("Network could not be initialized!")
	abort()
}
