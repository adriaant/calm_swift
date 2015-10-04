//
//  workspace.swift
//  calm
//
//  Created by Adriaan Tijsseling on 01/11/15.
//  Copyright (c) 2015 infinite-sushi.com. All rights reserved.
//

import Foundation

struct Workspace {
	static var network: Network?
	static let numberOfIterations = 10 // 50
	
	static func valueForParameter(name: Parameters.Names) -> Double {
		if let val = Workspace.network?.parameters[name] {
			return val
		}
		print("Unknown parameter: \(name)!")
		return 0.0
	}
}
