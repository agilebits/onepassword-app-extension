//
//  LoginViewController.swift
//  App Demo for iOS Swift
//
//  Created by Rad Azzouz on 2015-05-14.
//  Copyright (c) 2015 Agilebits. All rights reserved.
//

import Foundation

class LoginViewController: UIViewController {

	@IBOutlet weak var onepasswordButton: UIButton!
	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var oneTimePasswordTextField: UITextField!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let patternImage = UIImage(named: "login-background.png") {
			self.view.backgroundColor = UIColor(patternImage: patternImage)
		}
		
		self.onepasswordButton.isHidden = (false == OnePasswordExtension.shared().isAppExtensionAvailable())
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if OnePasswordExtension.shared().isAppExtensionAvailable() == false {
			let alertController = UIAlertController(title: "1Password is not installed", message: "Get 1Password from the App Store", preferredStyle: UIAlertControllerStyle.alert)

			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			alertController.addAction(cancelAction)

			let OKAction = UIAlertAction(title: "Get 1Password", style: .default) { (action) in UIApplication.shared().openURL(NSURL(string: "https://itunes.apple.com/app/1password-password-manager/id568903335")! as URL)
			}

			alertController.addAction(OKAction)
			self.present(alertController, animated: true, completion: nil)
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.lightContent
	}

	@IBAction func findLoginFrom1Password(sender:AnyObject) -> Void {
		OnePasswordExtension.shared().findLogin(forURLString: "https://www.acme.com", for: self, sender: sender, completion: { (loginDictionary, error) -> Void in
			if loginDictionary == nil {
				if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
					print("Error invoking 1Password App Extension for find login: \(error)")
				}
				return
			}
			
			self.usernameTextField.text = loginDictionary?[AppExtensionUsernameKey] as? String
			self.passwordTextField.text = loginDictionary?[AppExtensionPasswordKey] as? String

			if let generatedOneTimePassword = loginDictionary?[AppExtensionTOTPKey] as? String {
				self.oneTimePasswordTextField.isHidden = false
				self.oneTimePasswordTextField.text = generatedOneTimePassword

				// Important: It is recommended that you submit the OTP/TOTP to your validation server as soon as you receive it, otherwise it may expire.				
				let dispatchTime = DispatchTime.now() + 0.5
				DispatchQueue.main.after(when: dispatchTime) {
					self.performSegue(withIdentifier: "showThankYouViewController", sender: self)
				}
			}

		})
	}
}
