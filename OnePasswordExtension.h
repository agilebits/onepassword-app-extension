//
//  1Password App Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

// Login Dictionary keys
FOUNDATION_EXPORT NSString *const AppExtensionURLStringKey;
FOUNDATION_EXPORT NSString *const AppExtensionUsernameKey;
FOUNDATION_EXPORT NSString *const AppExtensionPasswordKey;
FOUNDATION_EXPORT NSString *const AppExtensionTitleKey;
FOUNDATION_EXPORT NSString *const AppExtensionNotesKey;
FOUNDATION_EXPORT NSString *const AppExtensionSectionTitleKey;
FOUNDATION_EXPORT NSString *const AppExtensionFieldsKey;

// Password Generator options
FOUNDATION_EXPORT NSString *const AppExtensionGeneratedPasswordMinLengthKey;
FOUNDATION_EXPORT NSString *const AppExtensionGeneratedPasswordMaxLengthKey;

@interface OnePasswordExtension : NSObject

+ (OnePasswordExtension *)sharedExtension;

/*
 Determines if the 1Password App Extension is available. Allows you to only show the 1Password login button to those
 that can use it. Of course, you could leave the button enabled and educate users about the virtues of strong, unique 
 passwords instead :)
 
 Note that this returns YES if any app that supports the generic `org-appextension-feature-password-management` feature 
 is installed.
 */
- (BOOL)isAppExtensionAvailable;

/*
 Called from your login page, this method will find all available logins for the given URLString. After the user selects 
 a login, it is stored into an NSDictionary and given to your completion handler. Use the `Login Dictionary keys` above to 
 extract the needed information and update your UI. The completion block is guaranteed to be called on the main thread.
 */
- (void)findLoginForURLString:(NSString *)URLString forViewController:(UIViewController *)forViewController completion:(void (^)(NSDictionary *loginDict, NSError *error))completion;

/*
 Create a new login within 1Password and allow the user to generate a new password before saving. The provided URLString should be 
 unique to your app or service and be identical to what you pass into the find login method.
 
 Details about the saved login, including the generated password, are stored in an NSDictionary and given to your completion handler. 
 Use the `Login Dictionary keys` above to extract the needed information and update your UI. For example, updating the UI with the 
 newly generated password lets the user know their action was successful. The completion block is guaranteed to be called on the main
 thread.
 */
- (void)storeLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)forViewController completion:(void (^)(NSDictionary *loginDict, NSError *error))completion;

/*
 Called from your web view controller, this method will show all the saved logins for the active page in the provided web
 view, and automatically fill the HTML form fields. Supports both WKWebView and UIWebView.
 */
- (void)fillLoginIntoWebView:(id)webView forViewController:(UIViewController *)forViewController completion:(void (^)(BOOL success, NSError *error))completion;

@end
