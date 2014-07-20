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

NSString *kServiceURL = @"https://wwww.twitter.com"; // URL for the 1Password Login.

@interface SignInViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;


@end

@implementation SignInViewController

- (void)processItemProvider:(NSItemProvider *)itemProvider {
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		__weak typeof (self) weakSelf = self;
		[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *item, NSError *error) {
			if (!item) {
				NSLog(@"Failed to parse item : <%@>", error);
				return;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				__strong typeof(self) strongSelf = weakSelf;
				if (strongSelf) {
					strongSelf.usernameTextField.text = item[OPLoginUsernameKey];
					strongSelf.passwordTextField.text = item[OPLoginPasswordKey];
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

#pragma mark - Actions

- (IBAction)lookupLogin:(id)sender {
	self.usernameTextField.text = @"";
	self.passwordTextField.text = @"";

	NSDictionary *item = @{ OPLoginURLStringKey : kServiceURL };
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionFindLoginAction];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	__weak typeof (self) weakSelf = self;

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		// returnedItems is nil after the second call. radar://17669995
		if (completed && (returnedItems.count > 0)) {
			for (NSExtensionItem *extensionItem in returnedItems) {
				[weakSelf processExtensionItem:extensionItem];
			}
		}
	};

	[self presentViewController:controller animated:YES completion:nil];
}

@end
