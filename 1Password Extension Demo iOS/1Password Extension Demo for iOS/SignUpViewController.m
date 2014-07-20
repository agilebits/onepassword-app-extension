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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
					strongSelf.usernameTextField.text = item[OPLoginUsernameKey] ? : strongSelf.usernameTextField.text;
					strongSelf.passwordTextField.text = item[OPLoginPasswordKey] ? : strongSelf.usernameTextField.text;
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

- (IBAction)saveLoginInformation:(id)sender {
	NSDictionary *item = @{
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

	__weak typeof (self) weakSelf = self;

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		// returnedItems is nil after the second call. radar://17669995

		if (completed) {
			if (returnedItems.count > 0) {
				for (NSExtensionItem *extensionItem in returnedItems) {
					[weakSelf processExtensionItem:extensionItem];
				}
			}
		}
		else {
			NSLog(@"Failed to save Registration information : <%@>", activityError);
		}
	};

	[self presentViewController:controller animated:YES completion:nil];
}

@end
