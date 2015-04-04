//
//  ViewController.swift
//  Poise
//
//  Created by Adriaan Tijsseling on 01/11/15.
//  Copyright (c) 2015 infinite-sushi.com. All rights reserved.
//

import Cocoa
import AppKit

struct PixelData {
	var a:UInt8 = 255
	var r:UInt8
	var g:UInt8
	var b:UInt8
}

struct Winner {
	var data: [Int]
	var width: Int
	var height: Int
	
	init(width:Int, height:Int) {
		self.width = width
		self.height = height
		data = [Int](count:width * height, repeatedValue: 0)
	}
	
	func indexIsValidForRow(row: Int, column: Int) -> Bool {
		return row >= 0 && row < width && column >= 0 && column < height
	}
	
	subscript(i:Int, j:Int) -> Int {
		get {
			assert(indexIsValidForRow(i, column: j), "Index out of range")
			return data[width * i + j]
		}
		set {
			assert(indexIsValidForRow(i, column: j), "Index out of range")
			data[width * i + j] = newValue
		}
	}
}


class ViewController: NSViewController {

	@IBOutlet var imageView: NSImageView!
	@IBOutlet var scaleSlider: NSSlider!
	@IBOutlet var epochSetter: NSStepper!
	@IBOutlet var progressIndicator: NSProgressIndicator!
	@IBOutlet var trainButton: NSButton!
	@IBOutlet var plotButton: NSButton!

	var plotDimension = 100
	var pixelArray = [PixelData](count: 0, repeatedValue: PixelData(a: 255, r:0, g: 0, b: 0))
	var winnerData = Winner(width: 0, height: 0)
	var lastIndex = 0

	override func viewDidLoad() {
		super.viewDidLoad()
		plotDimension = Int(imageView.frame.height)
		pixelArray = [PixelData](count: plotDimension * plotDimension, repeatedValue: PixelData(a: 255, r:0, g: 0, b: 0))
		winnerData = Winner(width: plotDimension, height: plotDimension)
		
		// There doesn't seem to be an easy way to have a menu item invoke an action in a view controller,
		// so fuck it, we'll set the action and target programmatically. The tag of the menu items (File -> Open)
		// is set in the storyboard.
		var app:NSApplication = NSApplication.sharedApplication()
		var menu = app.mainMenu
		if let mItem = menu?.itemWithTag(1269)?.submenu?.itemWithTag(1269) {
			mItem.target = self
			mItem.enabled = true
			mItem.action = Selector("loadNetwork:")
		}
	}

	override var representedObject: AnyObject? {
		didSet {
		}
	}
	
	@IBAction func loadNetwork(sender: AnyObject?) {
		var openPanel = NSOpenPanel()
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = true
		openPanel.canCreateDirectories = false
		openPanel.canChooseFiles = false
		openPanel.beginWithCompletionHandler { [weak self] (result) -> Void in
			if result == NSFileHandlingPanelOKButton {
				if let path = openPanel.URL?.path {
					if let strongSelf = self {
						Workspace.network = Network(baseDirectory: path)
						if let network = Workspace.network {
							// Construct simple network
							network.addInputModule("input", size: 2)
							network.addModule("intern", size: 5)
							network.addModule("out", size: 2)
							network.connectModuleWithName("input", toModuleWithName: "intern")
							network.connectModuleWithName("intern", toModuleWithName: "out")
							network.connectModuleWithName("out", toModuleWithName: "intern")
							
							print(network)
						}
					}
				}
			}
		}
	}

	@IBAction func startTraining(sender: AnyObject) {
		
		if let network = Workspace.network {
			let useRandom = true
			let numEpochs = epochSetter.integerValue
			
			progressIndicator.maxValue = Double(numEpochs)
			progressIndicator.doubleValue = 0.0

			network.prepareForLearning()

			let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
			dispatch_source_set_event_handler(source) {
				[unowned self] in
				let delta = Double(dispatch_source_get_data(source))
				self.progressIndicator.incrementBy(delta)
			}
			dispatch_resume(source)
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
				[unowned self] in

				if useRandom {
					let gen = UniformRandomDoubleGenerator()
					for epoch in 0..<numEpochs {
						var inputVector = [gen.nextValue(), gen.nextValue()]
						println(inputVector)
						network.train(["input": inputVector])
						dispatch_source_merge_data(source, 1);
					}
				} else {
					for epoch in 0..<numEpochs {
						network.train(["input": [1.0, 0.0]])
						network.train(["input": [0.0, 1.1]])
						dispatch_source_merge_data(source, 1);
					}
				}
				print(network)
				network.prepareForTesting()
				
				println("Test with [0 1]")
				network.test(["input": [0.0, 1.0]])
				println(network.winnerForModule("out"))
				println("Test with [1 0]")
				network.test(["input": [1.0, 0.0]])
				println(network.winnerForModule("out"))

			}
		}
		
	}
	
	
	// Simple 2D plot with winners
	@IBAction func startPlotting(sender: AnyObject) {

		plotDimension = 10 + (10 * scaleSlider.integerValue)
		pixelArray = [PixelData](count: plotDimension * plotDimension, repeatedValue: PixelData(a: 255, r:0, g: 0, b: 0))
		winnerData = Winner(width: plotDimension, height: plotDimension)

		if let network = Workspace.network {
			let testRange = Double(plotDimension)
			let useRandom = true

			network.prepareForTesting()
			lastIndex = 0

			let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
			dispatch_source_set_event_handler(source) {
				[unowned self] in
				self.renderData(dispatch_source_get_data(source), data: self.winnerData)
			}
			dispatch_resume(source)

			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
				[unowned self] in
				for row in 0..<self.plotDimension {
					for col in 0..<self.plotDimension {
						network.test(["input": [Double(row) / testRange, Double(col) / testRange]])
						self.winnerData[row, col] = network.winnerForModule("out")
						dispatch_source_merge_data(source, 1);
					}
				}
			}
		}
	}
	
	func renderData(counter: UInt, data:Winner) {
		let maxIndex: Int = Int(counter) + lastIndex
		let x = lastIndex / plotDimension
		let y = 0
		renderLoop: for i in x ..< data.width
		{
			for j in y ..< data.height
			{
				let index: Int = i * data.width + j
				if (index > maxIndex) {
					break renderLoop
				}
				let winner = data[i, j]
				if winner == 1 {
					pixelArray[index].r = 255
					pixelArray[index].g = 0
					pixelArray[index].b = 0
				} else if winner > 1 {
					pixelArray[index].r = 0
					pixelArray[index].g = 255
					pixelArray[index].b = 0
				}
			}
		}
		imageView.image = imageFromARGB32Bitmap(pixelArray, UInt(data.width), UInt(data.height))
		lastIndex = maxIndex
	}

}

