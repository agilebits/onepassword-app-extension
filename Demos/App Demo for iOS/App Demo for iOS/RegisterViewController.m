//
//  SignUpViewController.m
//  1Password Extension Demo
//
//  Created by Rad Azzouz on 2014-07-17.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "RegisterViewController.h"
#import "OnePasswordExtension.h"

@interface RegisterViewController ()

@property (weak, nonatomic) IBOutlet UIButton *onepasswordButton;

@property (weak, nonatomic) IBOutlet UITextField *firstnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"register-background.png"]]];
	[self.onepasswordButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleDefault;
}

- (IBAction)saveLoginTo1Password:(id)sender {
	NSDictionary *newLoginDetails = @{
									  AppExtensionTitleKey: @"ACME",
									  AppExtensionUsernameKey: self.usernameTextField.text ? : @"",
									  AppExtensionPasswordKey: self.passwordTextField.text ? : @"",
									  AppExtensionNotesKey: @"Saved with the ACME app",
									  AppExtensionSectionTitleKey: @"ACME Browser",
									  AppExtensionFieldsKey: @{
											  @"firstname" : self.firstnameTextField.text ? : @"",
											  @"lastname" : self.lastnameTextField.text ? : @""
											  // Add as many string fields as you please.
											  }
									  };

	// Password generation options are optional, but are very handy in case you have strict rules about password lengths
	NSDictionary *passwordGenerationOptions = @{
		AppExtensionGeneratedPasswordMinLengthKey: @(8),
		AppExtensionGeneratedPasswordMaxLengthKey: @(30),
		AppExtensionGeneratedPasswordUseDigitsKey: @(YES),
		AppExtensionGeneratedPasswordUseSymbolsKey: @(YES),

		// Here are all the symbols available in the the 1Password Password Generator:
		// @"!", @"@", @"#", @"$", @"%", @"^", @"&", @"*", @"(", @")", @"_", @"-", @"+", @"=", @"|", @"[", @"]", @"{", @"}", @"'", @"\"", @;", @".". @",", @">", @"?", @"/", @"~", @"`"
		// The array for AppExtensionGeneratedPasswordBlacklistedSymbolsKey should contain the symbols that you wish 1Password to exclude from the generated password.

		AppExtensionGeneratedPasswordBlacklistedSymbolsKey: @[@"&", @"*", @"@", @"#", @"~", @"`", @"$", @"^", @"/", @"|", @"<", @">", @":", @";"]
	};

	[[OnePasswordExtension sharedExtension] storeLoginForURLString:@"https://www.acme.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDictionary, NSError *error) {

		if (loginDictionary.count == 0) {
			if (error.code != AppExtensionErrorCodeCancelledByUser) {
				NSLog(@"Failed to use 1Password App Extension to save a new Login: %@", error);
			}
			return;
		}

		self.usernameTextField.text = loginDictionary[AppExtensionUsernameKey] ? : @"";
		self.passwordTextField.text = loginDictionary[AppExtensionPasswordKey] ? : @"";
		self.firstnameTextField.text = loginDictionary[AppExtensionReturnedFieldsKey][@"firstname"] ? : @"";
		self.lastnameTextField.text = loginDictionary[AppExtensionReturnedFieldsKey][@"lastname"] ? : @"";
		// retrieve any additional fields that were passed in newLoginDetails dictionary
	}];
}

@end
