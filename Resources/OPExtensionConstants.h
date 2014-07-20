//
//  OPExtensionConstants.h
//  1Password Extension Demo
//
//  Created by Rad Azzouz & Michael Fey on 7/16/14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

/**
 These constants define the actions supported by the 1Password extension. Use these constants to create the NSItemProvider instance added to NSExtensionItem instance's attachments array:

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:someItemDictionary typeIdentifier:kUTTypeNSExtensionFindLoginAction];
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
 */
#define kUTTypeNSExtensionFindLoginAction @"org.nsextension.find-login-action"
#define kUTTypeNSExtensionSaveLoginAction @"org.nsextension.register-action" // TODO: Change to org.nsextension.save-login-action
#define kUTTypeNSExtensionFillWebViewAction @"org.nsextension.fill-webview-action"

/**
 These constants define the item types supported by the 1Password extension. These types are used to build the item dictionary that is passed to the NSItemProvider:

	NSDictionary *item = @{ kURLString : @"https://yourawesomedomain.com",
 kUsername : @"WendyAppleseed",
 kPassword: nil};
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionRegisterAction];
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
 */

// NSItemProviders of type kUTTypeNSExtensionFindLoginAction must include a kURLString entry in the item dictionary that defines the URL to lookup in 1Password. This URL must be limited to your domain. NSItemProviders of type kUTTypeNSExtensionRegisterAction or kUTTypeNSExtensionGeneratePasswordAction should specify this entry in the item dictionary to define the URL for the newly created login.
#define OPLoginURLStringKey @"url_string"

// NSItemProviders of type kUTTypeNSExtensionRegisterAction can use this key to specify the username stored in the newly created login.
#define OPLoginUsernameKey @"username"

// NSItemProviders of type kUTTypeNSExtensionRegisterAction can use this key to specify the password stored in the newly created login.
#define OPLoginPasswordKey @"password"

// NSItemProviders of type kUTTypeNSExtensionRegisterAction can use this key to specify the title of the newly created login.
#define OPLoginTitleKey @"login_title"

// NSItemProviders of type kUTTypeNSExtensionRegisterAction can use this key to specify the notes section of the newly created login.
#define OPLoginNotesKey @"notes"

// NSItemProviders of type kUTTypeNSExtensionRegisterAction can use this key to specify the section title of the newly created login.
#define OPLoginSectionTitleKey @"section_title"

// NSItemProviders of type kUTTypeNSExtensionRegisterAction can use this key to specify the section fields of the newly created login.
#define OPLoginFieldsKey @"fields"

// NSItemProviders of type kUTTypeNSExtensionGeneratePasswordAction can use this key to specify the length of the generated password of the newly created login.

#define OPPasswordLenghtKey @"generated_password_length"

// NSItemProviders of type kUTTypeNSExtensionGeneratePasswordAction can use this key to specify a maximum length for a generated password. The value associated with this key should be an NSNumber.

#define OPPasswordUseMixedCaseKey @"generated_password_use_mixed_case"

// NSItemProviders of type kUTTypeNSExtensionGeneratePasswordAction can use this key to specify a maximum length for a generated password. The value associated with this key should be an NSNumber that wraps a BOOL.
#define OPPasswordGeneratorUseMixedCase @"use_mixed_case"

// NSItemProviders of type kUTTypeNSExtensionGeneratePasswordAction can use this key to specify an array of strings that will separate the generated password.
#define OPPasswordSparatorsKey @"generated_password_separators"
