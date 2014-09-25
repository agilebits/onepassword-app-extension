//
//  SignInViewController.m
//  1Password Extension Demo
//
//  Created by Rad on 2014-07-14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "LoginViewController.h"
#import "OnePasswordExtension.h"
#import "LoginInformation.h"

@interface LoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *onepasswordSigninButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"login-background.png"]]];
	[self.onepasswordSigninButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (IBAction)findLoginFrom1Password:(id)sender {
	OnePasswordExtension *onePasswordExtension = [OnePasswordExtension sharedExtension];

	// Create the 1Password extension item.
	NSExtensionItem *extensionItem = [onePasswordExtension createExtensionItemToFindLoginForURLString:@"https://www.acme.com"];

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
					strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey];
					strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey];

					[LoginInformation sharedLoginInformation].username = loginDict[AppExtensionUsernameKey];
				}];
			}
		}
		else {
			// Code for other activity types
		}
	};

	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.usernameTextField) {
		[LoginInformation sharedLoginInformation].username = textField.text;
	}
}

@end
