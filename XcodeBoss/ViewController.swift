//
//  ViewController.swift
//  XcodeBoss
//
//  Created by Kim Ahlberg on 2017-05-14.
//  Copyright © 2017 The Evil Boss. All rights reserved.
//

import Cocoa

class MyConstants {
}

class ViewController: NSViewController {

	let APP_GROUP_SUITE_NAME = "4WC27B9WNL.group.com.theevilboss.CommentBoss"
	let LINE_LENGTH_KEY = "LINE_LENGTH"
	
	var lastKnownLineLength : Int = 120

	@IBOutlet weak var lineLengthSlider: NSSlider!
	@IBOutlet weak var lineLengthTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Read the preferred line length from UserDefaults and set it to the UI.
		if let defaults : UserDefaults = UserDefaults.init(suiteName: APP_GROUP_SUITE_NAME) {
			
			let lineLength = defaults.integer(forKey: LINE_LENGTH_KEY)
			
			if lineLength > 0 {
				
				// Update the UI to reflect the stored line length.
				lineLengthSlider.integerValue = lineLength
				lineLengthTextField.integerValue = lineLength
				
				// This is now our last known line length.
				lastKnownLineLength = lineLength
			} else {
				
				NSLog("Unable to read preferred break column from the UserDefaults.")
			}
		}
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func lineLengthSliderChanged(_ sender: NSSlider) {
		
		// Update the label.
		let lineLength = sender.integerValue
		lineLengthTextField.integerValue = lineLength
		
		// Persist the new value to UserDefaults if it is different from the last known value.
		if lineLength != lastKnownLineLength {
			
			if let defaults : UserDefaults = UserDefaults.init(suiteName: APP_GROUP_SUITE_NAME) {
				
				defaults.set(lineLength, forKey: LINE_LENGTH_KEY)
			}
			
			// This is now our last known line length.
			lastKnownLineLength = lineLength
		}
    }

}

