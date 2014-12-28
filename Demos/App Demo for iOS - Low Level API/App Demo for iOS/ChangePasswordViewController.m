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
	if ([oldPassword isEqualToString:newPassword]) {
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

	OnePasswordExtension *onePasswordExtension = [OnePasswordExtension sharedExtension];

	// Create the 1Password extension item.
	NSExtensionItem *extensionItem = [onePasswordExtension createExtensionItemToChangePasswordForLoginForURLString:@"https://www.acme.com" loginDetails:loginDetails passwordGenerationOptions:passwordGenerationOptions];

	NSArray *activityItems = @[ extensionItem ]; // Add as many activity items as you please

	// Setting up the activity view controller
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems  applicationActivities:nil];

	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		self.popoverPresentationController.barButtonItem = sender;
	}
	else if ([sender isKindOfClass:[UIView class]]) {
		self.popoverPresentationController.sourceView = [sender superview];
		self.popoverPresentationController.sourceRect = [sender frame];
	}

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
	{
		// Executed when the 1Password Extension is called
		if ([onePasswordExtension isOnePasswordExtensionActivityType:activityType]) {
			if (returnedItems.count > 0) {
				__weak typeof (self) miniMe = self;
				[onePasswordExtension processReturnedItems:returnedItems completion:^(NSDictionary *loginDict, NSError *error) {
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
		}
		else {
			// Code for other activity types
		}
	};

	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Convenience methods

- (void)showChangePasswordFailedAlertWithMessage:(NSString *)message {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Password Error" message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		self.freshPasswordTextField.text = @"";
		self.confirmPasswordTextField.text = @"";
		[self.freshPasswordTextField becomeFirstResponder];
	}];

	[alert addAction:dismissAction];
	[self presentViewController:alert animated:YES completion:nil];
}

@end
