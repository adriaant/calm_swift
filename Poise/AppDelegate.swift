//
//  AppDelegate.swift
//  Poise
//
//  Created by Adriaan Tijsseling on 01/11/15.
//  Copyright (c) 2015 infinite-sushi.com. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var application: NSApplication? = nil

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		application = aNotification.object as? NSApplication
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
}

