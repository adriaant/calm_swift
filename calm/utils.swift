//
//  utils.swift
//  calm
//
//  Created by Adriaan Tijsseling on 12/30/14.
//  Copyright (c) 2014 infinite-sushi.com. All rights reserved.
//

import Foundation

func read(path:String) -> String? {
	let fh = NSFileHandle(forReadingAtPath: path)
	let data = fh?.readDataToEndOfFile()
	if fh == nil {
		print("file(\(path)) can't open.")
		return nil
	}
	fh?.closeFile()
	return NSString(data: data!, encoding: NSUTF8StringEncoding) as? String
}

func dataFromJsonFile(path:String) -> AnyObject? {
	let data = try? NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
	if data != nil {
		var parseError: NSError?
		let parsedObject: AnyObject?
		do {
			parsedObject = try NSJSONSerialization.JSONObjectWithData(data!,
						options: NSJSONReadingOptions.AllowFragments)
		} catch let error as NSError {
			parseError = error
			parsedObject = nil
			print("Error parsing: \(parseError)")
		}
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


/// Fake random numbers for testing purposes.
public struct FakeRandomDoubleGenerator: GeneratorType, SequenceType {
	static var count = 0
	static var fake: [Double] = [0.29045394400834745,
		0.84005235323467042,
		0.48484851850984001,
		0.93624758202277325,
		0.5135127623127449,
		0.54811416520354461,
		0.8526450947475801,
		0.75750575871766834,
		0.060733832510789232,
		0.53654116426354503,
		0.24602160131114037,
		0.35608180841616599,
		0.13708598786484583,
		0.21743394489907797,
		0.15735413261461906,
		0.15435903625068059,
		0.50092554692921565,
		0.028842494893377979,
		0.11355190667052928,
		0.99617956662448326,
		0.99454234800359798,
		0.5966122865575566,
		0.96809734339805542,
		0.27943839257298608,
		0.7363552630779524,
		0.19460378995868188,
		0.74086211664114288,
		0.85567304613245165,
		0.3473937128700072,
		0.55027110817115255,
		0.060439472302122432,
		0.14870614644084801,
		0.1655358566096099,
		0.90320477284017708,
		0.94020788738735828,
		0.92733339864045872,
		0.017897657149227864,
		0.69292824828706956,
		0.66752015098376083,
		0.48874994846537967,
		0.30322599281700946,
		0.30580098894700014,
		0.0056780992596238145,
		0.17319583421010831,
		0.26552468262372408,
		0.70020962229316097,
		0.58488781820692826,
		0.56225330783686167,
		0.18182594428224219,
		0.37118956647162127,
		0.61483060875721229,
		0.50051014991026221,
		0.87564756024801516,
		0.99547586408688837,
		0.35789648868323309,
		0.092716554924280103,
		0.79561524474543865,
		0.46899023827583319,
		0.41498135000305858,
		0.84208008221540886,
		0.36030591898520714,
		0.11120205256485727,
		0.14555636516690085,
		0.32233978331300217,
		0.51525293231533109,
		0.097290044566180622,
		0.75377542000812459,
		0.012844465629798574,
		0.40933515989376779,
		0.41697322255167724,
		0.81591309825489033,
		0.91051154189855854,
		0.12061937194022543,
		0.36699014376673134,
		0.48303871485021355,
		0.49184792388869603,
		0.62972964748351823,
		0.85227370142826819,
		0.36241520037611896,
		0.80340418231725153,
		0.79050632595530501,
		0.26812462488316646,
		0.52059727963187319,
		0.71863762656789443,
		0.05624046635769242,
		0.25912090885846928,
		0.30945690020082162,
		0.028507839651114808,
		0.59625282051150408,
		0.18117944947654652,
		0.72001008555414636,
		0.22383837467473466,
		0.58572414448734034,
		0.97495749525331254,
		0.52847926208625207,
		0.058325907658165588,
		0.28595154526165212,
		0.98570563622347884,
		0.047448943436479651,
		0.68517266224013162]

	/// Note: The returned Optional value will never be nil
	public func next() -> Double? {
		let val = FakeRandomDoubleGenerator.fake[FakeRandomDoubleGenerator.count]
		FakeRandomDoubleGenerator.count++
		return val
	}

	/// Return next random value.
	///
	/// This is a convenience method that unwraps the non-nil Optional returned by next().
	public func nextValue() -> Double {
		return next()!
	}

	/// Return this generator
	public func generate() -> FakeRandomDoubleGenerator {
		return self
	}
}
