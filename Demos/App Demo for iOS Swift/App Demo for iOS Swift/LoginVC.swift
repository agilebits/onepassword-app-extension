//
//  LoginVC.swift
//  App Demo for iOS Swift
//
//  Created by Diego on 3/31/15.
//  Copyright (c) 2015 Agilebits. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {
	
	@IBOutlet weak var usernameText: UITextField!
	@IBOutlet weak var passwordText: UITextField!
	@IBOutlet weak var onePasswordButton: UIButton!
	
	@IBAction func onePasswordTapped() {
		OnePasswordExtension.sharedInstance.findLoginWithURLString("https://www.acme.com", viewController: self, sender: self, completion: { (loginDict, error) in
			if loginDict == nil {
				if error!.code != AppExtensionErrorCodeCancelledByUser {
					NSLog("Error invoking 1Password App Extension for find login: %@", error!)
				}
				return
			}
			
			self.usernameText.text = loginDict![AppExtensionUsernameKey] as String
			self.passwordText.text = loginDict![AppExtensionPasswordKey] as String
		})
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
