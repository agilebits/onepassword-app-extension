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
	NSString *newPassword = self.freshPasswordTextField.text ? : @"";
	NSString *oldPassword = self.oldPasswordTextField.text ? : @"";
	NSString *confirmationPassword = self.confirmPasswordTextField.text ? : @"";

	// Validate that the new password and the old password are not the same.
	if (oldPassword.length > 0 && [oldPassword isEqualToString:newPassword]) {
		[self showChangePasswordFailedAlertWithMessage:@"The old and the new password must not be the same"];
		return;
	}

	// Validate that the new and confirmation passwords match.
	if (NO == [newPassword isEqualToString:confirmationPassword]) {
		[self showChangePasswordFailedAlertWithMessage:@"The new passwords and the confirmation password must match"];
		return;
	}

	NSString *username = [LoginInformation sharedLoginInformation].username ? : @"";

	NSDictionary *loginDetails = @{
									  AppExtensionTitleKey: @"ACME",
									  AppExtensionUsernameKey: username, // 1Password will prompt the user to create a new item if no matching logins are found with this username.
									  AppExtensionPasswordKey: newPassword,
									  AppExtensionOldPasswordKey: oldPassword,
									  AppExtensionNotesKey: @"Saved with the ACME app",
									};

	// Password generation options are optional, but are very handy in case you have strict rules about password lengths
	NSDictionary *passwordGenerationOptions = @{
		AppExtensionGeneratedPasswordMinLengthKey: @(6),
		AppExtensionGeneratedPasswordMaxLengthKey: @(50)
	};

	[[OnePasswordExtension sharedExtension] changePasswordForLoginForURLString:@"https://www.acme.com" loginDetails:loginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
		if (!loginDict) {
			if (error.code != AppExtensionErrorCodeCancelledByUser) {
				NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
			}
			return;
		}

		self.oldPasswordTextField.text = loginDict[AppExtensionOldPasswordKey];
		self.freshPasswordTextField.text = loginDict[AppExtensionPasswordKey];
		self.confirmPasswordTextField.text = loginDict[AppExtensionPasswordKey];
	}];
}

#pragma mark - Convenience methods

- (void)showChangePasswordFailedAlertWithMessage:(NSString *)message {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Password Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    __strong UITextField *freshPasswordTextField = self.freshPasswordTextField;
	UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		freshPasswordTextField.text = @"";
		self.confirmPasswordTextField.text = @"";
		[freshPasswordTextField becomeFirstResponder];
	}];

	[alert addAction:dismissAction];
	[self presentViewController:alert animated:YES completion:nil];
}

@end
