//
//  OPExtensionConstants.h
//  1Password Extension Demo
//
//  Created by Rad Azzouz & Michael Fey on 7/16/14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <Foundation/Foundation.h>

/**
 These constants define the actions supported by the 1Password extension. Use these constants to create the NSItemProvider instance added to NSExtensionItem instance's attachments array:

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:someItemDictionary typeIdentifier:kUTTypeNSExtensionFindLoginAction];
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
 */

FOUNDATION_EXPORT NSString *const kUTTypeNSExtensionFindLoginAction;
FOUNDATION_EXPORT NSString *const kUTTypeNSExtensionSaveLoginAction;
FOUNDATION_EXPORT NSString *const kUTTypeNSExtensionFillWebViewAction;

/**
 These constants define the item types supported by the 1Password extension. These types are used to build the item dictionary that is passed to the NSItemProvider:

	NSDictionary *item = @{ kURLString : @"https://yourawesomedomain.com",
	kUsername : @"WendyAppleseed",
    kPassword: nil };

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionSaveLoginAction];
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
*/

// NSItemProviders of type kUTTypeNSExtensionFindLoginAction must include a OPLoginURLStringKey entry in the item dictionary that defines the URL to lookup in 1Password. This URL must be limited to your domain. NSItemProviders of type kUTTypeNSExtensionSaveLoginAction should specify this entry in the item dictionary to define the URL for the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginURLStringKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the username stored in the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginUsernameKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the password stored in the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginPasswordKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the minimum length of the generated password stored in the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginGeneratedPasswordMinLengthKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the maximum length of the generated password stored in the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginGeneratedPasswordMaxLengthKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the title of the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginTitleKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the notes section of the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginNotesKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the section title of the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginSectionTitleKey;

// NSItemProviders of type kUTTypeNSExtensionSaveLoginAction can use this key to specify the section fields of the newly created login.
FOUNDATION_EXPORT NSString *const OPLoginFieldsKey;

// NSItemProviders of type kUTTypeNSExtensionFillWebViewAction can use this key to get the fill script from the 1Password Extension.
FOUNDATION_EXPORT NSString *const OPWebViewPageFillScript;

// NSItemProviders of type kUTTypeNSExtensionFillWebViewAction can use this key to pass the page details to the 1Password Extension.
FOUNDATION_EXPORT NSString *const OPWebViewPageDetails;
