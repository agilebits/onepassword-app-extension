//
//  SignUpViewController.m
//  1Password Extension Demo
//
//  Created by Rad Azzouz on 2014-07-17.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "RegisterViewController.h"
#import <OnePasswordExtension/OnePasswordExtension.h>

@interface RegisterViewController ()

@property (weak, nonatomic) IBOutlet UIButton *onepasswordSignupButton;

@property (weak, nonatomic) IBOutlet UITextField *firstnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"register-background.png"]]];

	NSBundle *onePasswordExtensionBundle = [NSBundle bundleForClass:[OnePasswordExtension class]];
	UIImage *onePasswordButtonImage = [UIImage imageNamed:@"onepassword-button" inBundle:onePasswordExtensionBundle compatibleWithTraitCollection:self.traitCollection];
	[self.onepasswordSignupButton setImage:onePasswordButtonImage forState:UIControlStateNormal];
	[self.onepasswordSignupButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
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
		AppExtensionGeneratedPasswordMinLengthKey: @(6),
		AppExtensionGeneratedPasswordMaxLengthKey: @(50)
	};

	[[OnePasswordExtension sharedExtension] storeLoginForURLString:@"https://www.acme.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {

		if (!loginDict) {
			if (error.code != AppExtensionErrorCodeCancelledByUser) {
				NSLog(@"Failed to use 1Password App Extension to save a new Login: %@", error);
			}
			return;
		}

		self.usernameTextField.text = loginDict[AppExtensionUsernameKey] ? : @"";
		self.passwordTextField.text = loginDict[AppExtensionPasswordKey] ? : @"";
		self.firstnameTextField.text = loginDict[AppExtensionReturnedFieldsKey][@"firstname"] ? : @"";
		self.lastnameTextField.text = loginDict[AppExtensionReturnedFieldsKey][@"lastname"] ? : @"";
		// retrieve any additional fields that were passed in newLoginDetails dictionary
	}];
}

@end
