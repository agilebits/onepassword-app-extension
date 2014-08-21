//
//  ChangePasswordViewController.m
//  App Demo for iOS
//
//  Created by Rad on 2014-08-11.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "OnePasswordExtension.h"
#import "LoginInformation.h"

@interface ChangePasswordViewController ()

@property (weak, nonatomic) IBOutlet UIButton *onepasswordSigninButton;
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *freshPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@end

@implementation ChangePasswordViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"login-background.png"]]];
	[self.onepasswordSigninButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleLightContent;
}

- (IBAction)changePasswordIn1Password:(id)sender {
	NSString *changedPassword = self.freshPasswordTextField.text ? : @"";

	// Validate that the new and confirmation passwords match.
	if (changedPassword.length > 0 && ![changedPassword isEqualToString:self.confirmPasswordTextField.text]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Password Error" message:@"The new and the confirmation passwords must match" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			self.freshPasswordTextField.text = @"";
			self.confirmPasswordTextField.text = @"";
			[self.freshPasswordTextField becomeFirstResponder];
		}];

		[alert addAction:dismissAction];
		[self presentViewController:alert animated:YES completion:nil];
		return;
	}

	NSString *username = [LoginInformation sharedLoginInformation].username ? : @"";

	NSDictionary *loginDetails = @{
									  AppExtensionTitleKey: @"ACME",
									  AppExtensionUsernameKey: username, // 1Password will prompt the user to create a new item if no matching logins are found with this username.
									  AppExtensionPasswordKey: changedPassword,
									  AppExtensionOldPasswordKey: self.oldPasswordTextField.text ? : @"",
									  AppExtensionNotesKey: @"Saved with the ACME app",
									};

	// Password generation options are optional, but are very handy in case you have strict rules about password lengths
	NSDictionary *passwordGenerationOptions = @{
		AppExtensionGeneratedPasswordMinLengthKey: @(6),
		AppExtensionGeneratedPasswordMaxLengthKey: @(50)
	};

	__weak typeof (self) miniMe = self;

	[[OnePasswordExtension sharedExtension] changePasswordForLoginForURLString:@"https://www.acme.com" loginDetails:loginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
		if (!loginDict) {
			if (error.code != AppExtensionErrorCodeCancelledByUser) {
				NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
			}
			return;
		}

		__strong typeof(self) strongMe = miniMe;
		strongMe.oldPasswordTextField.text = loginDict[AppExtensionOldPasswordKey];
		strongMe.freshPasswordTextField.text = loginDict[AppExtensionPasswordKey];
		strongMe.confirmPasswordTextField.text = loginDict[AppExtensionPasswordKey];
	}];
}

@end
