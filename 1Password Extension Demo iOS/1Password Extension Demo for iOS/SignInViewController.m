//
//  ViewController.m
//  1Password Extension Demo
//
//  Created by Rad on 2014-07-14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "SignInViewController.h"

#import "OPExtensionConstants.h"

// You should only ask for login information of your own service. Giving a URL for a service which you do not own or support may seriously break the customer's trust in your service/app.

@interface SignInViewController ()

@property (weak, nonatomic) IBOutlet UIButton *onepasswordSigninButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;


@end

@implementation SignInViewController


- (BOOL)is1PasswordExtensionAvailable {
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"onepassword-extension://fill"]];
}

-(void)viewWillAppear:(BOOL)animated {
	[self.onepasswordSigninButton setHidden:![self is1PasswordExtensionAvailable]];
}

#pragma mark - Actions

- (IBAction)findLoginFrom1Password:(id)sender {
	NSDictionary *item = @{ OPLoginURLStringKey : @"https://www.acmebrowser.com" }; // Ensure the URLString is set to your actual service URL, so that user will find your actual Login information in 1Password.
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionFindLoginAction];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	__weak typeof (self) miniMe = self;

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {

		// returnedItems is nil after the second call. radar://17669995
		if (completed) {
			__strong typeof(self) strongMe = miniMe;
			for (NSExtensionItem *extensionItem in returnedItems) {
				[strongMe processExtensionItem:extensionItem];
			}
		}
		else {
			NSLog(@"Error contacting the 1Password Extension: <%@>", activityError);
		}
	};

	[self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - ItemProvider Callback

- (void)processItemProvider:(NSItemProvider *)itemProvider {
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		__weak typeof (self) miniMe = self;
		[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *item, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (item) {
					__strong typeof(self) strongMe = miniMe;
					strongMe.usernameTextField.text = item[OPLoginUsernameKey];
					strongMe.passwordTextField.text = item[OPLoginPasswordKey];
				}
				else {
					NSLog(@"Failed to parse item provider result: <%@>", error);
				}
			});
		}];
	}
}

- (void)processExtensionItem:(NSExtensionItem *)extensionItem {
	for (NSItemProvider *itemProvider in extensionItem.attachments) {
		[self processItemProvider:itemProvider];
	}
}

@end
