//
//  SignUpViewController.m
//  1Password Extension Demo
//
//  Created by Rad on 2014-07-17.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "SignUpViewController.h"
#import "OPExtensionConstants.h"

@interface SignUpViewController ()

@property (weak, nonatomic) IBOutlet UITextField *firstnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation SignUpViewController

- (IBAction)saveLoginTo1Password:(id)sender {
	NSDictionary *item = @{
						   // Ensure the URLString is set to your actual service URL, so that user will find your actual Login information in 1Password.
						   OPLoginURLStringKey : @"https://wwww.twitter.com",
						   OPLoginTitleKey : @"Twitter - Demo",
						   OPLoginUsernameKey : self.usernameTextField.text ? : @"",
						   OPLoginPasswordKey : self.passwordTextField.text ? : @"",
						   OPLoginNotesKey : @"Saved with 1Password Extension Demo app",
						   OPLoginSectionTitleKey : @"Registration Info",
						   OPLoginFieldsKey : @{
								   @"firstname" : self.firstnameTextField.text ? : @"",
								   @"lastname" : self.lastnameTextField.text ? : @""
								   // Add as many string fields as you please.
								   }
						   };

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionSaveLoginAction];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	__weak typeof (self) miniMe = self;

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		// returnedItems is nil after the second call. radar://17669995
		if (completed) {
			for (NSExtensionItem *extensionItem in returnedItems) {
				[miniMe processExtensionItem:extensionItem];
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
					miniMe.usernameTextField.text = item[OPLoginUsernameKey] ? : miniMe.usernameTextField.text;
					miniMe.passwordTextField.text = item[OPLoginPasswordKey] ? : miniMe.usernameTextField.text;
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
