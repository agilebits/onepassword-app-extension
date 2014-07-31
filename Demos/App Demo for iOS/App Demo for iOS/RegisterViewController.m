//
//  SignUpViewController.m
//  1Password Extension Demo
//
//  Created by Rad Azzouz on 2014-07-17.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "RegisterViewController.h"
#import "OnePasswordExtension.h"

#import <MessageUI/MFMailComposeViewController.h>

@interface RegisterViewController () <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *firstnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"register-background.png"]]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleDefault;
}

- (IBAction)saveLoginTo1Password:(id)sender {
	if (![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"1Password Beta is not installed" message:@"Email support+appex@agilebits.com for beta access" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Email", nil];
		[alertView show];
	}
	else {
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
			strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey] ? : strongMe.usernameTextField.text;
			strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey] ? : strongMe.usernameTextField.text;
		}];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == alertView.firstOtherButtonIndex) {
		MFMailComposeViewController* composeViewController = [[MFMailComposeViewController alloc] init];
		composeViewController.mailComposeDelegate = self;
		[composeViewController setToRecipients:@[ @"support+appex@agilebits.com" ]];
		[composeViewController setSubject:@"App Extension"];
		[self presentViewController:composeViewController animated:YES completion:nil];
	}
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
