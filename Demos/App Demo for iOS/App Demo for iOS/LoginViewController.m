//
//  SignInViewController.m
//  1Password Extension Demo
//
//  Created by Rad on 2014-07-14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "LoginViewController.h"
#import "OnePasswordExtension.h"

#import <MessageUI/MFMailComposeViewController.h>

@interface LoginViewController () <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"login-background.png"]]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (IBAction)findLoginFrom1Password:(id)sender {
	if (![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"1Password Beta is not installed" message:@"Email support+appex@agilebits.com for beta access" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Email", nil];
		[alertView show];
	}
	else {
		__weak typeof (self) miniMe = self;
		[[OnePasswordExtension sharedExtension] findLoginForURLString:@"https://www.acme.com" forViewController:self completion:^(NSDictionary *loginDict, NSError *error) {
			if (!loginDict) {
				NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
				return;
			}

			__strong typeof(self) strongMe = miniMe;
			strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey];
			strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey];
		}];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == alertView.firstOtherButtonIndex) {
		MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
		controller.mailComposeDelegate = self;
		[controller setToRecipients:@[ @"support+appex@agilebits.com" ]];
		[controller setSubject:@"App Extension"];
		[self presentViewController:controller animated:YES completion:nil];
	}
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
