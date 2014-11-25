//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#ifdef __IPHONE_8_0
#import <WebKit/WebKit.h>
#endif

// Login Dictionary keys
#define AppExtensionURLStringKey                  @"url_string"
#define AppExtensionUsernameKey                   @"username"
#define AppExtensionPasswordKey                   @"password"
#define AppExtensionTitleKey                      @"login_title"
#define AppExtensionNotesKey                      @"notes"
#define AppExtensionSectionTitleKey               @"section_title"
#define AppExtensionFieldsKey                     @"fields"
#define AppExtensionReturnedFieldsKey             @"returned_fields"
#define AppExtensionOldPasswordKey                @"old_password"
#define AppExtensionPasswordGereratorOptionsKey   @"password_generator_options"

// Password Generator options
#define AppExtensionGeneratedPasswordMinLengthKey @"password_min_length"
#define AppExtensionGeneratedPasswordMaxLengthKey @"password_max_length"

// Errors
#define AppExtensionErrorDomain                   @"OnePasswordExtension"

#define AppExtensionErrorCodeCancelledByUser                    0
#define AppExtensionErrorCodeAPINotAvailable                    1
#define AppExtensionErrorCodeFailedToContactExtension           2
#define AppExtensionErrorCodeFailedToLoadItemProviderData       3
#define AppExtensionErrorCodeCollectFieldsScriptFailed          4
#define AppExtensionErrorCodeFillFieldsScriptFailed             5
#define AppExtensionErrorCodeUnexpectedData                     6
#define AppExtensionErrorCodeFailedToObtainURLStringFromWebView 7

// Note to creators of libraries or frameworks:
// If you include this code within your library, then to prevent potential duplicate symbol
// conflicts for adopters of your library, you should rename the OnePasswordExtension class.
// You might to so by adding your own project prefix, e.g., MyLibraryOnePasswordExtension.

@interface OnePasswordExtension : NSObject

+ (OnePasswordExtension *)sharedExtension;

/*!
 Determines if the 1Password Extension is available. Allows you to only show the 1Password login button to those
 that can use it. Of course, you could leave the button enabled and educate users about the virtues of strong, unique 
 passwords instead :)
 
 Note that this returns YES if any app that supports the generic `org-appextension-feature-password-management` feature 
 is installed.
 */
#ifdef __IPHONE_8_0
- (BOOL)isAppExtensionAvailable NS_EXTENSION_UNAVAILABLE_IOS("Not available in an extension. Check if org-appextension-feature-password-management:// URL can be opened by the app.");
#else
- (BOOL)isAppExtensionAvailable;
#endif

/*!
 Called from your login page, this method will find all available logins for the given URLString. After the user selects 
 a login, it is stored into an NSDictionary and given to your completion handler. Use the `Login Dictionary keys` above to 
 extract the needed information and update your UI. The completion block is guaranteed to be called on the main thread.
 */
- (void)findLoginForURLString:(NSString *)URLString forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *loginDict, NSError *error))completion;

/*!
 Create a new login within 1Password and allow the user to generate a new password before saving. The provided URLString should be 
 unique to your app or service and be identical to what you pass into the find login method.
 
 Details about the saved login, including the generated password, are stored in an NSDictionary and given to your completion handler. 
 Use the `Login Dictionary keys` above to extract the needed information and update your UI. For example, updating the UI with the 
 newly generated password lets the user know their action was successful. The completion block is guaranteed to be called on the main
 thread.
 */
- (void)storeLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *loginDict, NSError *error))completion;

/*!
 Change the password for an existing login within 1Password. The provided URLString should be
 unique to your app or service and be identical to what you pass into the find login method. The username must be the one that the user is currently logged in with.

 Details about the saved login, including the newly generated and the old password, are stored in an NSDictionary and given to your completion handler.
 Use the `Login Dictionary keys` above to extract the needed information and update your UI. For example, updating the UI with the
 newly generated password lets the user know their action was successful. The completion block is guaranteed to be called on the main
 thread.
 */
- (void)changePasswordForLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *loginDict, NSError *error))completion;

/*!
 Called from your web view controller, this method will show all the saved logins for the active page in the provided web
 view, and automatically fill the HTML form fields. Supports both WKWebView and UIWebView.
 */
- (void)fillLoginIntoWebView:(id)webView forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(BOOL success, NSError *error))completion;

@end
