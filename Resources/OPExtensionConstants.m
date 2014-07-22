//
//  OPExtensionConstants.m
//  1Password Extension Demo
//
//  Created by Rad Azzouz & Michael Fey on 7/16/14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OPExtensionConstants.h"

/**
 These constants define the actions supported by the 1Password extension. Use these constants to create the NSItemProvider instance added to NSExtensionItem instance's attachments array:

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:someItemDictionary typeIdentifier:kUTTypeNSExtensionFindLoginAction];
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
 */

NSString *const kUTTypeNSExtensionFindLoginAction = @"org.nsextension.find-login-action";
NSString *const kUTTypeNSExtensionSaveLoginAction= @"org.nsextension.save-login-action";
NSString *const kUTTypeNSExtensionFillWebViewAction= @"org.nsextension.fill-webview-action";

/**
 These constants define the item types supported by the 1Password extension. These types are used to build the item dictionary that is passed to the NSItemProvider:

	NSDictionary *item = @{ kURLString : @"https://yourawesomedomain.com",
	kUsername : @"WendyAppleseed",
 kPassword: nil };

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionSaveLoginAction];
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
 */

// NSItemProviders of type kUTTypeNSExtensionFindLoginAction must include a kURLString entry in the item dictionary that defines the URL to lookup in 1Password. This URL must be limited to your domain. NSItemProviders of type kUTTypeNSExtensionSaveLoginAction should specify this entry in the item dictionary to define the URL for the newly created login.
NSString *const OPLoginURLStringKey= @"url_string";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the username stored in the newly created login.
NSString *const OPLoginUsernameKey= @"username";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the password stored in the newly created login.
NSString *const OPLoginPasswordKey= @"password";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the minimum length of the generated password stored in the newly created login.
NSString *const OPLoginGeneratedPasswordMinLengthKey = @"password_min_length";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the maximum length of the generated password stored in the newly created login.
NSString *const OPLoginGeneratedPasswordMaxLengthKey = @"password_max_length";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the title of the newly created login.
NSString *const OPLoginTitleKey= @"login_title";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the notes section of the newly created login.
NSString *const OPLoginNotesKey= @"notes";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the section title of the newly created login.
NSString *const OPLoginSectionTitleKey= @"section_title";

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the section fields of the newly created login.
NSString *const OPLoginFieldsKey= @"fields";

// NSItemProviders of type kUTTypeNSExtensionFillWebViewAction can use this key to get the fill script from the 1Password Extension.
NSString *const OPWebViewPageFillScript= @"fillScript";

// NSItemProviders of type kUTTypeNSExtensionFillWebViewAction can use this key to pass the page details to the 1Password Extension.
NSString *const OPWebViewPageDetails= @"pageDetails";
