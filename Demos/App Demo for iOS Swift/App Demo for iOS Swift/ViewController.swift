//
//  ViewController.swift
//  App Demo for iOS Swift
//
//  Created by Diego on 3/31/15.
//  Copyright (c) 2015 Agilebits. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if OnePasswordExtension.sharedInstance.isAppExtensionAvailable() == false {
			let alertController = UIAlertController(title: "Default Style", message: "A standard alert.", preferredStyle: .Alert)
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			
			let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
				var dummy = UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/app/1password-password-manager/id568903335")!)
			}
			alertController.addAction(OKAction)
			
			self.presentViewController(alertController, animated: true) {
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

