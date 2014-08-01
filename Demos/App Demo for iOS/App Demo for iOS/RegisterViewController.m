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

@property (weak, nonatomic) IBOutlet UIButton *onepasswordSignupButton;

@property (weak, nonatomic) IBOutlet UITextField *firstnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"register-background.png"]]];
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
	
	NSDictionary *passwordGenerationOptions = @{
		AppExtensionGeneratedPasswordMinLengthKey: @(6),
		AppExtensionGeneratedPasswordMaxLengthKey: @(50)
	};
	__weak typeof (self) miniMe = self;

	[[OnePasswordExtension sharedExtension] storeLoginForURLString:@"https://www.acme.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self completion:^(NSDictionary *loginDict, NSError *error) {

		if (!loginDict) {
			NSLog(@"Error invoking 1Password App Extension for generate password: %@", error);
			return;
		}

		__strong typeof(self) strongMe = miniMe;
		
		NSArray *sectionsArray = loginDict[AppExtensionFieldsKey][AppExtensionSectionsArrayKey];
		NSDictionary *sentSection = sectionsArray.firstObject; // The first section is the one created when first invoking the Extension. Other sections may be available if the user created the manually.

		// The fields are return in the same order that they were created. In this case the firstname is at index 0 and lastname is at index 1. 
		strongMe.firstnameTextField.text = sentSection[AppExtensionFieldsKey][0][AppExtensionFieldValueKey] ? : strongMe.firstnameTextField.text;
		strongMe.lastnameTextField.text = sentSection[AppExtensionFieldsKey][1][AppExtensionFieldValueKey] ? : strongMe.lastnameTextField.text;
		strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey] ? : strongMe.usernameTextField.text;
		strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey] ? : strongMe.passwordTextField.text;
	}];
}

@end
