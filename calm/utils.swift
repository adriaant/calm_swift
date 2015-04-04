//
//  utils.swift
//  calm
//
//  Created by Adriaan Tijsseling on 12/30/14.
//  Copyright (c) 2014 infinite-sushi.com. All rights reserved.
//

import Foundation

func read(path:String) -> String? {
	var fh = NSFileHandle(forReadingAtPath: path)
	let data = fh?.readDataToEndOfFile()
	if fh == nil {
		println("file(\(path)) can't open.")
		return nil
	}
	fh?.closeFile()
	return NSString(data: data!, encoding: NSUTF8StringEncoding)
}

func dataFromJsonFile(path:String) -> AnyObject? {
	let data = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)
	if data != nil {
		var parseError: NSError?
		let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!,
			options: NSJSONReadingOptions.AllowFragments,
			error:&parseError)
		return parsedObject
	}
	return nil
}

func randomDouble() -> Double {
	return Double(arc4random()) / Double(UInt32.max)
}


/// Generator of random double values uniformly distributed between 0.0 and 1.0
/// From: https://gist.github.com/kristopherjohnson/f941f2dab644c481c4aa
public struct UniformRandomDoubleGenerator: GeneratorType, SequenceType {
	/// Return next random value.
	///
	/// Note: The returned Optional value will never be nil
	public func next() -> Double? {
		// There may be a better magic number to use here, but this should work
		let intervalCount = UInt(1) << 31
		return Double(arc4random_uniform(UInt32(intervalCount))) / Double(intervalCount)
	}
 
	/// Return next random value.
	///
	/// This is a convenience method that unwraps the non-nil Optional returned by next().
	public func nextValue() -> Double {
		return next()!
	}
 
	/// Return this generator
	public func generate() -> UniformRandomDoubleGenerator {
		return self
	}
}
