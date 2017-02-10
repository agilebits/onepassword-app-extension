//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"

// Version
#define VERSION_NUMBER @(184)
static NSString *const AppExtensionVersionNumberKey = @"version_number";

// Available App Extension Actions
static NSString *const kUTTypeAppExtensionFindLoginAction = @"org.appextension.find-login-action";
static NSString *const kUTTypeAppExtensionSaveLoginAction = @"org.appextension.save-login-action";
static NSString *const kUTTypeAppExtensionChangePasswordAction = @"org.appextension.change-password-action";
static NSString *const kUTTypeAppExtensionFillWebViewAction = @"org.appextension.fill-webview-action";
static NSString *const kUTTypeAppExtensionFillBrowserAction = @"org.appextension.fill-browser-action";

// WebView Dictionary keys
static NSString *const AppExtensionWebViewPageFillScript = @"fillScript";
static NSString *const AppExtensionWebViewPageDetails = @"pageDetails";

@implementation OnePasswordExtension

#pragma mark - Public Methods

+ (OnePasswordExtension *)sharedExtension {
	static dispatch_once_t onceToken;
	static OnePasswordExtension *__sharedExtension;

	dispatch_once(&onceToken, ^{
		__sharedExtension = [OnePasswordExtension new];
	});

	return __sharedExtension;
}

- (BOOL)isAppExtensionAvailable {
	if ([self isSystemAppExtensionAPIAvailable]) {
		return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"org-appextension-feature-password-management://"]];
	}

	return NO;
}

#pragma mark - Native app Login

- (void)findLoginForURLString:(nonnull NSString *)URLString forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (NO == [self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to findLoginForURLString, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}

#ifdef __IPHONE_8_0
	NSDictionary *item = @{ AppExtensionVersionNumberKey: VERSION_NUMBER, AppExtensionURLStringKey: URLString };

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionFindLoginAction];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to findLoginForURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
			if (completion) {
				completion(itemDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - New User Registration

- (void)storeLoginForURLString:(nonnull NSString *)URLString loginDetails:(nullable NSDictionary *)loginDetailsDictionary passwordGenerationOptions:(nullable NSDictionary *)passwordGenerationOptions forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (NO == [self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to storeLoginForURLString, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}


#ifdef __IPHONE_8_0
	NSMutableDictionary *newLoginAttributesDict = [NSMutableDictionary new];
	newLoginAttributesDict[AppExtensionVersionNumberKey] = VERSION_NUMBER;
	newLoginAttributesDict[AppExtensionURLStringKey] = URLString;
	[newLoginAttributesDict addEntriesFromDictionary:loginDetailsDictionary];
	if (passwordGenerationOptions.count > 0) {
		newLoginAttributesDict[AppExtensionPasswordGeneratorOptionsKey] = passwordGenerationOptions;
	}

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:newLoginAttributesDict viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionSaveLoginAction];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to storeLoginForURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
			if (completion) {
				completion(itemDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - Change Password

- (void)changePasswordForLoginForURLString:(nonnull NSString *)URLString loginDetails:(nullable NSDictionary *)loginDetailsDictionary passwordGenerationOptions:(nullable NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (NO == [self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to changePasswordForLoginWithUsername, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}

#ifdef __IPHONE_8_0
	NSMutableDictionary *item = [NSMutableDictionary new];
	item[AppExtensionVersionNumberKey] = VERSION_NUMBER;
	item[AppExtensionURLStringKey] = URLString;
	[item addEntriesFromDictionary:loginDetailsDictionary];
	if (passwordGenerationOptions.count > 0) {
		item[AppExtensionPasswordGeneratorOptionsKey] = passwordGenerationOptions;
	}

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionChangePasswordAction];

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to changePasswordForLoginWithUsername: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
			if (completion) {
				completion(itemDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - Web View filling Support

- (void)fillItemIntoWebView:(nonnull id)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");
	NSAssert([webView isKindOfClass:[UIWebView class]] || [webView isKindOfClass:[WKWebView class]], @"webView must be an instance of WKWebView or UIWebView.");

#ifdef __IPHONE_8_0
	if ([webView isKindOfClass:[UIWebView class]]) {
		[self fillItemIntoUIWebView:webView webViewController:viewController sender:(id)sender showOnlyLogins:yesOrNo completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
	#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0 || ONE_PASSWORD_EXTENSION_ENABLE_WK_WEB_VIEW
	else if ([webView isKindOfClass:[WKWebView class]]) {
		[self fillItemIntoWKWebView:webView forViewController:viewController sender:(id)sender showOnlyLogins:yesOrNo completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
	#endif
#endif
}

#pragma mark - Support for custom UIActivityViewControllers

- (BOOL)isOnePasswordExtensionActivityType:(nullable NSString *)activityType {
	return [@"com.agilebits.onepassword-ios.extension" isEqualToString:activityType] || [@"com.agilebits.beta.onepassword-ios.extension" isEqualToString:activityType];
}

- (void)createExtensionItemForWebView:(nonnull id)webView completion:(nonnull OnePasswordExtensionItemCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert([webView isKindOfClass:[UIWebView class]] || [webView isKindOfClass:[WKWebView class]], @"webView must be an instance of WKWebView or UIWebView.");
	
#ifdef __IPHONE_8_0
	if ([webView isKindOfClass:[UIWebView class]]) {
		UIWebView *uiWebView = (UIWebView *)webView;
		NSString *collectedPageDetails = [uiWebView stringByEvaluatingJavaScriptFromString:OPWebViewCollectFieldsScript];

		[self createExtensionItemForURLString:uiWebView.request.URL.absoluteString webPageDetails:collectedPageDetails completion:completion];
	}
	#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0 || ONE_PASSWORD_EXTENSION_ENABLE_WK_WEB_VIEW
	else if ([webView isKindOfClass:[WKWebView class]]) {
		WKWebView *wkWebView = (WKWebView *)webView;
		[wkWebView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *evaluateError) {
			if (result == nil) {
				NSLog(@"1Password Extension failed to collect web page fields: %@", evaluateError);
				NSError *failedToCollectFieldsError = [OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:evaluateError];
				if (completion) {
					if ([NSThread isMainThread]) {
						completion(nil, failedToCollectFieldsError);
					}
					else {
						dispatch_async(dispatch_get_main_queue(), ^{
							completion(nil, failedToCollectFieldsError);
						});
					}
				}

				return;
			}

			[self createExtensionItemForURLString:wkWebView.URL.absoluteString webPageDetails:result completion:completion];
		}];
	}
	#endif
#endif
}

- (void)fillReturnedItems:(nullable NSArray *)returnedItems intoWebView:(nonnull id)webView completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");

	if (returnedItems.count == 0) {
		NSError *error = [OnePasswordExtension extensionCancelledByUserError];
		if (completion) {
			completion(NO, error);
		}

		return;
	}

	[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
		if (itemDictionary.count == 0) {
			if (completion) {
				completion(NO, error);
			}

			return;
		}

		NSString *fillScript = itemDictionary[AppExtensionWebViewPageFillScript];
		[self executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
			if (completion) {
				completion(success, executeFillScriptError);
			}
		}];
	}];
}

#pragma mark - Private methods

- (BOOL)isSystemAppExtensionAPIAvailable {
#ifdef __IPHONE_8_0
	return [NSExtensionItem class] != nil;
#else
	return NO;
#endif
}

- (void)findLoginIn1PasswordWithURLString:(nonnull NSString *)URLString collectedPageDetails:(nullable NSString *)collectedPageDetails forWebViewController:(nonnull UIViewController *)forViewController sender:(nullable id)sender withWebView:(nonnull id)webView showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	if ([URLString length] == 0) {
		NSError *URLStringError = [OnePasswordExtension failedToObtainURLStringFromWebViewError];
		NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", URLStringError);
		if (completion) {
			completion(NO, URLStringError);
		}
		return;
	}

	NSError *jsonError = nil;
	NSData *data = [collectedPageDetails dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *collectedPageDetailsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

	if (collectedPageDetailsDictionary.count == 0) {
		NSLog(@"Failed to parse JSON collected page details: %@", jsonError);
		if (completion) {
			completion(NO, jsonError);
		}
		return;
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : collectedPageDetailsDictionary };

	NSString *typeIdentifier = yesOrNo ? kUTTypeAppExtensionFillWebViewAction  : kUTTypeAppExtensionFillBrowserAction;
	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:forViewController sender:sender typeIdentifier:typeIdentifier];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(NO, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *processExtensionItemError) {
			if (itemDictionary.count == 0) {
				if (completion) {
					completion(NO, processExtensionItemError);
				}

				return;
			}

			NSString *fillScript = itemDictionary[AppExtensionWebViewPageFillScript];
			[self executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
				if (completion) {
					completion(success, executeFillScriptError);
				}
			}];
		}];
	};

	[forViewController presentViewController:activityViewController animated:YES completion:nil];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0 || ONE_PASSWORD_EXTENSION_ENABLE_WK_WEB_VIEW
- (void)fillItemIntoWKWebView:(nonnull WKWebView *)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	[webView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *error) {
		if (result == nil) {
			NSLog(@"1Password Extension failed to collect web page fields: %@", error);
			if (completion) {
				completion(NO,[OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:error]);
			}

			return;
		}

		[self findLoginIn1PasswordWithURLString:webView.URL.absoluteString collectedPageDetails:result forWebViewController:viewController sender:sender withWebView:webView showOnlyLogins:yesOrNo completion:^(BOOL success, NSError *findLoginError) {
			if (completion) {
				completion(success, findLoginError);
			}
		}];
	}];
}
#endif

- (void)fillItemIntoUIWebView:(nonnull UIWebView *)webView webViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	NSString *collectedPageDetails = [webView stringByEvaluatingJavaScriptFromString:OPWebViewCollectFieldsScript];
	[self findLoginIn1PasswordWithURLString:webView.request.URL.absoluteString collectedPageDetails:collectedPageDetails forWebViewController:viewController sender:sender withWebView:webView showOnlyLogins:yesOrNo completion:^(BOOL success, NSError *error) {
		if (completion) {
			completion(success, error);
		}
	}];
}

- (void)executeFillScript:(NSString * __nullable)fillScript inWebView:(nonnull id)webView completion:(nonnull OnePasswordSuccessCompletionBlock)completion {

	if (fillScript == nil) {
		NSLog(@"Failed to executeFillScript, fillScript is missing");
		if (completion) {
			completion(NO, [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedStringFromTable(@"Failed to fill web page because script is missing", @"OnePasswordExtension", @"1Password Extension Error Message") underlyingError:nil]);
		}

		return;
	}

	NSMutableString *scriptSource = [OPWebViewFillScript mutableCopy];
	[scriptSource appendFormat:@"(document, %@, undefined);", fillScript];

#ifdef __IPHONE_8_0
	if ([webView isKindOfClass:[UIWebView class]]) {
		NSString *result = [((UIWebView *)webView) stringByEvaluatingJavaScriptFromString:scriptSource];
		BOOL success = (result != nil);
		NSError *error = nil;

		if (!success) {
			NSLog(@"Cannot executeFillScript, stringByEvaluatingJavaScriptFromString failed");
			error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedStringFromTable(@"Failed to fill web page because script could not be evaluated", @"OnePasswordExtension", @"1Password Extension Error Message") underlyingError:nil];
		}

		if (completion) {
			completion(success, error);
		}
	}
	
	#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0 || ONE_PASSWORD_EXTENSION_ENABLE_WK_WEB_VIEW
	else if ([webView isKindOfClass:[WKWebView class]]) {
		[((WKWebView *)webView) evaluateJavaScript:scriptSource completionHandler:^(NSString *result, NSError *evaluationError) {
			BOOL success = (result != nil);
			NSError *error = nil;

			if (!success) {
				NSLog(@"Cannot executeFillScript, evaluateJavaScript failed: %@", evaluationError);
				error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedStringFromTable(@"Failed to fill web page because script could not be evaluated", @"OnePasswordExtension", @"1Password Extension Error Message") underlyingError:error];
			}

			if (completion) {
				completion(success, error);
			}
		}];
	}
	#endif
#endif
}

#ifdef __IPHONE_8_0
- (void)processExtensionItem:(nullable NSExtensionItem *)extensionItem completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	if (extensionItem.attachments.count == 0) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item had no attachments." };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}

	NSItemProvider *itemProvider = extensionItem.attachments.firstObject;
	if (NO == [itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePropertyList]) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item attachment does not conform to kUTTypePropertyList type identifier" };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}


	[itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *itemDictionary, NSError *itemProviderError) {
		 NSError *error = nil;
		 if (itemDictionary.count == 0) {
			 NSLog(@"Failed to loadItemForTypeIdentifier: %@", itemProviderError);
			 error = [OnePasswordExtension failedToLoadItemProviderDataErrorWithUnderlyingError:itemProviderError];
		 }

		 if (completion) {
			 if ([NSThread isMainThread]) {
				 completion(itemDictionary, error);
			 }
			 else {
				 dispatch_async(dispatch_get_main_queue(), ^{
					 completion(itemDictionary, error);
				 });
			 }
		 }
	 }];
}

- (UIActivityViewController *)activityViewControllerForItem:(nonnull NSDictionary *)item viewController:(nonnull UIViewController*)viewController sender:(nullable id)sender typeIdentifier:(nonnull NSString *)typeIdentifier {
#ifdef __IPHONE_8_0
	NSAssert(NO == (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && sender == nil), @"sender must not be nil on iPad.");

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:typeIdentifier];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];

	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		controller.popoverPresentationController.barButtonItem = sender;
	}
	else if ([sender isKindOfClass:[UIView class]]) {
		controller.popoverPresentationController.sourceView = [sender superview];
		controller.popoverPresentationController.sourceRect = [sender frame];
	}
	else {
		NSLog(@"sender can be nil on iPhone");
	}

	return controller;
#else
	return nil;
#endif
}

#endif

- (void)createExtensionItemForURLString:(nonnull NSString *)URLString webPageDetails:(nullable NSString *)webPageDetails completion:(nonnull OnePasswordExtensionItemCompletionBlock)completion {
	NSError *jsonError = nil;
	NSData *data = [webPageDetails dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *webPageDetailsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

	if (webPageDetailsDictionary.count == 0) {
		NSLog(@"Failed to parse JSON collected page details: %@", jsonError);
		if (completion) {
			completion(nil, jsonError);
		}
		return;
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : webPageDetailsDictionary };

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeAppExtensionFillBrowserAction];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	if (completion) {
		if ([NSThread isMainThread]) {
			completion(extensionItem, nil);
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(extensionItem, nil);
			});
		}
	}
}

#pragma mark - Errors

+ (NSError *)systemAppExtensionAPINotAvailableError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"App Extension API is not available in this version of iOS", @"OnePasswordExtension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeAPINotAvailable userInfo:userInfo];
}


+ (NSError *)extensionCancelledByUserError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"1Password Extension was cancelled by the user", @"OnePasswordExtension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCancelledByUser userInfo:userInfo];
}

+ (NSError *)failedToContactExtensionErrorWithActivityError:(nullable NSError *)activityError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedStringFromTable(@"Failed to contact the 1Password Extension", @"OnePasswordExtension", @"1Password Extension Error Message");
	if (activityError) {
		userInfo[NSUnderlyingErrorKey] = activityError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToContactExtension userInfo:userInfo];
}

+ (NSError *)failedToCollectFieldsErrorWithUnderlyingError:(nullable NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedStringFromTable(@"Failed to execute script that collects web page information", @"OnePasswordExtension", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCollectFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToFillFieldsErrorWithLocalizedErrorMessage:(nullable NSString *)errorMessage underlyingError:(nullable NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (errorMessage) {
		userInfo[NSLocalizedDescriptionKey] = errorMessage;
	}
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFillFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToLoadItemProviderDataErrorWithUnderlyingError:(nullable NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedStringFromTable(@"Failed to parse information returned by 1Password Extension", @"OnePasswordExtension", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToLoadItemProviderData userInfo:userInfo];
}

+ (NSError *)failedToObtainURLStringFromWebViewError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Failed to obtain URL String from web view. The web view must be loaded completely when calling the 1Password Extension", @"OnePasswordExtension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToObtainURLStringFromWebView userInfo:userInfo];
}

#pragma mark - WebView field collection and filling scripts

static NSString *const OPWebViewCollectFieldsScript = @";(function(document, undefined) {\
var isFirefox = false, isChrome = false, isSafari = true;\
\
	document.elementsByOPID={};document.addEventListener('input',function(c){!1!==c.a&&'input'===c.target.tagName.toLowerCase()&&(c.target.dataset['com.agilebits.onepassword.userEdited']='yes')},!0);\
function q(c,d){function b(a,c){var e=a[c];if('string'==typeof e)return e;e=a.getAttribute(c);return'string'==typeof e?e:null}function g(a,c){if(-1===['text','password'].indexOf(c.type.toLowerCase())||!(m.test(a.value)||m.test(a.htmlID)||m.test(a.htmlName)||m.test(a.placeholder)||m.test(a['label-tag'])||m.test(a['label-data'])||m.test(a['label-aria'])))return!1;if(!a.visible)return!0;if('password'==c.type.toLowerCase())return!1;var e=c.type;u(c,!0);return e!==c.type}function n(a){switch(p(a.type)){case 'checkbox':return a.checked?\
'✓':'';case 'hidden':a=a.value;if(!a||'number'!=typeof a.length)return'';254<a.length&&(a=a.substr(0,254)+'...SNIPPED');return a;case 'submit':case 'button':case 'reset':if(''===a.value)return v(y(a))||'';default:return a.value}}function l(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){var c=a.text,c=c?p(c).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,''):null;return[c?c:null,a.value]}),{options:a}):null}function r(a){var c;for(a=a.parentElement||\
a.parentNode;a&&'td'!=p(a.tagName);)a=a.parentElement||a.parentNode;if(!a||void 0===a)return null;c=a.parentElement||a.parentNode;if('tr'!=c.tagName.toLowerCase())return null;c=c.previousElementSibling;if(!c||'tr'!=(c.tagName+'').toLowerCase()||c.cells&&a.cellIndex>=c.cells.length)return null;a=y(c.cells[a.cellIndex]);return a=v(a)}function s(a){var b,e=[];if(a.labels&&a.labels.length&&0<a.labels.length)e=Array.prototype.slice.call(a.labels);else{a.id&&(e=e.concat(Array.prototype.slice.call(A(c,'label[for='+\
JSON.stringify(a.id)+']'))));if(a.name){b=A(c,'label[for='+JSON.stringify(a.name)+']');for(var d=0;d<b.length;d++)-1===e.indexOf(b[d])&&e.push(b[d])}for(b=a;b&&b!=c;b=b.parentNode)'label'===p(b.tagName)&&-1===e.indexOf(b)&&e.push(b)}0===e.length&&(b=a.parentNode,'dd'===b.tagName.toLowerCase()&&null!==b.previousElementSibling&&'dt'===b.previousElementSibling.tagName.toLowerCase()&&e.push(b.previousElementSibling));return 0<e.length?e.map(function(a){return v(y(a))}).join(''):null}function f(a,c,b,\
d){void 0!==d&&d===b||null===b||void 0===b||(a[c]=b)}function p(a){return'string'===typeof a?a.toLowerCase():(''+a).toLowerCase()}function A(a,c){var b=[];try{b=a.querySelectorAll(c)}catch(d){}return b}var t=c.defaultView?c.defaultView:window,w=c.activeElement,m=RegExp('((\\\\b|_|-)pin(\\\\b|_|-)|password|passwort|kennwort|(\\\\b|_|-)passe(\\\\b|_|-)|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i'),x=Array.prototype.slice.call(A(c,'form')).map(function(a,c){var e={},d='__form__'+c;a.opid=d;e.opid=\
d;f(e,'htmlName',b(a,'name'));f(e,'htmlID',b(a,'id'));d=b(a,'action');d=new URL(d,window.location.href);f(e,'htmlAction',d?d.href:null);f(e,'htmlMethod',b(a,'method'));return e}),G=Array.prototype.slice.call(z(c)).map(function(a,d){a.hasAttribute('value')&&!a.dataset['com.agilebits.onepassword.initialValue']&&(a.dataset['com.agilebits.onepassword.initialValue']=a.value);var e={},k='__'+d,h=-1==a.maxLength?999:a.maxLength;if(!h||'number'===typeof h&&isNaN(h))h=999;c.elementsByOPID[k]=a;a.opid=k;e.opid=\
k;e.elementNumber=d;f(e,'maxLength',Math.min(h,999),999);e.visible=B(a);e.viewable=C(a);f(e,'htmlID',b(a,'id'));f(e,'htmlName',b(a,'name'));f(e,'htmlClass',b(a,'class'));f(e,'tabindex',b(a,'tabindex'));f(e,'title',b(a,'title'));f(e,'userEdited',!!a.dataset['com.agilebits.onepassword.userEdited']);if('hidden'!=p(a.type)){f(e,'label-tag',s(a));f(e,'label-data',b(a,'data-label'));f(e,'label-aria',b(a,'aria-label'));f(e,'label-top',r(a));k=[];for(h=a;h&&h.nextSibling;){h=h.nextSibling;if(D(h))break;E(k,\
h)}f(e,'label-right',k.join(''));k=[];F(a,k);k=k.reverse().join('');f(e,'label-left',k);f(e,'placeholder',b(a,'placeholder'))}f(e,'rel',b(a,'rel'));f(e,'type',p(b(a,'type')));f(e,'value',n(a));f(e,'checked',a.checked,!1);f(e,'autoCompleteType',a.getAttribute('x-autocompletetype')||a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'),'off');f(e,'disabled',a.disabled);f(e,'readonly',a.b||a.readOnly);f(e,'selectInfo',l(a));f(e,'aria-hidden','true'==a.getAttribute('aria-hidden'),!1);f(e,\
'aria-disabled','true'==a.getAttribute('aria-disabled'),!1);f(e,'aria-haspopup','true'==a.getAttribute('aria-haspopup'),!1);f(e,'data-unmasked',a.dataset.unmasked);f(e,'data-stripe',b(a,'data-stripe'));f(e,'data-braintree-name',b(a,'data-braintree-name'));f(e,'onepasswordFieldType',a.dataset.onepasswordFieldType||a.type);f(e,'onepasswordDesignation',a.dataset.onepasswordDesignation);f(e,'onepasswordSignInUrl',a.dataset.onepasswordSignInUrl);f(e,'onepasswordSectionTitle',a.dataset.onepasswordSectionTitle);\
f(e,'onepasswordSectionFieldKind',a.dataset.onepasswordSectionFieldKind);f(e,'onepasswordSectionFieldTitle',a.dataset.onepasswordSectionFieldTitle);f(e,'onepasswordSectionFieldValue',a.dataset.onepasswordSectionFieldValue);a.form&&(e.form=b(a.form,'opid'));f(e,'fakeTested',g(e,a),!1);return e});G.filter(function(a){return a.fakeTested}).forEach(function(a){var b=c.elementsByOPID[a.opid];b.getBoundingClientRect();var d=b.value;u(b,!1);b.dispatchEvent(H(b,'keydown'));b.dispatchEvent(H(b,'keypress'));\
b.dispatchEvent(H(b,'keyup'));if(''===b.value||b.dataset['com.agilebits.onepassword.initialValue']&&b.value===b.dataset['com.agilebits.onepassword.initialValue'])b.value=d;b.click&&b.click();a.postFakeTestVisible=B(b);a.postFakeTestViewable=C(b);a.postFakeTestType=b.type;a=b.value;var d=b.ownerDocument.createEvent('HTMLEvents'),f=b.ownerDocument.createEvent('HTMLEvents');b.dispatchEvent(H(b,'keydown'));b.dispatchEvent(H(b,'keypress'));b.dispatchEvent(H(b,'keyup'));f.initEvent('input',!0,!0);b.dispatchEvent(f);\
d.initEvent('change',!0,!0);b.dispatchEvent(d);b.blur();if(''===b.value||b.dataset['com.agilebits.onepassword.initialValue']&&b.value===b.dataset['com.agilebits.onepassword.initialValue'])b.value=a});t={documentUUID:d,title:c.title,url:t.location.href,documentUrl:c.location.href,tabUrl:t.location.href,forms:function(a){var b={};a.forEach(function(a){b[a.opid]=a});return b}(x),fields:G,collectedTimestamp:(new Date).getTime()};(x=document.querySelector('[data-onepassword-title]'))&&x.dataset[DISPLAY_TITLE_ATTRIBUE]&&\
(t.displayTitle=x.dataset.onepasswordTitle);w&&'input'===w.tagName.toLowerCase()&&-1===w.type.search(/button|submit|reset/i)&&u(w,!0);return t};document.elementForOPID=I;function H(c,d){var b;isFirefox?(b=document.createEvent('KeyboardEvent'),b.initKeyEvent(d,!0,!1,null,!1,!1,!1,!1,0,0)):(b=c.ownerDocument.createEvent('Events'),b.initEvent(d,!0,!1),b.charCode=0,b.keyCode=0,b.which=0,b.srcElement=c,b.target=c);return b}window.LOGIN_TITLES=[/^\\W*log\\W*[oi]n\\W*$/i,/log\\W*[oi]n (?:securely|now)/i,/^\\W*sign\\W*[oi]n\\W*$/i,'continue','submit','weiter','accès','вход','connexion','entrar','anmelden','accedi','valider','登录','लॉग इन करें'];\
window.CHANGE_PASSWORD_TITLES=['change password','save changes'];window.LOGIN_RED_HERRING_TITLES=['already have an account','sign in with'];window.REGISTER_TITLES='register;sign up;signup;join;create my account;регистрация;inscription;regístrate;cadastre-se;registrieren;registrazione;注册;साइन अप करें'.split(';');window.SEARCH_TITLES='search find поиск найти искать recherche suchen buscar suche ricerca procurar 検索'.split(' ');window.FORGOT_PASSWORD_TITLES='forgot geändert vergessen hilfe changeemail español'.split(' ');\
window.REMEMBER_ME_TITLES=['remember me','rememberme','keep me signed in'];window.BACK_TITLES=['back','назад'];function y(c){return c.textContent||c.innerText}function v(c){var d=null;c&&(d=c.replace(/^\\s+|\\s+$|\\r?\\n.*$/mg,'').replace(/\\s{2,}/,' '),d=0<d.length?d:null);return d}function E(c,d){var b;b='';3===d.nodeType?b=d.nodeValue:1===d.nodeType&&(b=y(d));(b=v(b))&&c.push(b)}\
function D(c){var d;c&&void 0!==c?(d='select option input form textarea button table iframe body head script'.split(' '),c?(c=c?(c.tagName||'').toLowerCase():'',d=d.constructor==Array?0<=d.indexOf(c):c===d):d=!1):d=!0;return d}\
function F(c,d,b){var g;for(b||(b=0);c&&c.previousSibling;){c=c.previousSibling;if(D(c))return;E(d,c)}if(c&&0===d.length){for(g=null;!g;){c=c.parentElement||c.parentNode;if(!c)return;for(g=c.previousSibling;g&&!D(g)&&g.lastChild;)g=g.lastChild}D(g)||(E(d,g),0===d.length&&F(g,d,b+1))}}\
function B(c){for(var d=c,b=(c=c.ownerDocument)?c.defaultView:{},g;d&&d!==c;){g=b.getComputedStyle&&d instanceof Element?b.getComputedStyle(d,null):d.style;if(!g)return!0;if('none'===g.display||'hidden'==g.visibility)return!1;d=d.parentNode}return d===c}\
function C(c){var d=c.ownerDocument.documentElement,b=c.getBoundingClientRect(),g=d.scrollWidth,n=d.scrollHeight,l=b.left-d.clientLeft,d=b.top-d.clientTop,r;if(!B(c)||!c.offsetParent||10>c.clientWidth||10>c.clientHeight)return!1;var s=c.getClientRects();if(0===s.length)return!1;for(var f=0;f<s.length;f++)if(r=s[f],r.left>g||0>r.right)return!1;if(0>l||l>g||0>d||d>n)return!1;for(b=c.ownerDocument.elementFromPoint(l+(b.right>window.innerWidth?(window.innerWidth-l)/2:b.width/2),d+(b.bottom>window.innerHeight?\
(window.innerHeight-d)/2:b.height/2));b&&b!==c&&b!==document;){if(b.tagName&&'string'===typeof b.tagName&&'label'===b.tagName.toLowerCase()&&c.labels&&0<c.labels.length)return 0<=Array.prototype.slice.call(c.labels).indexOf(b);b=b.parentNode}return b===c}\
function I(c){var d;if(void 0===c||null===c)return null;try{var b=Array.prototype.slice.call(z(document)),g=b.filter(function(b){return b.opid==c});if(0<g.length)d=g[0],1<g.length&&console.warn('More than one element found with opid '+c);else{var n=parseInt(c.split('__')[1],10);isNaN(n)||(d=b[n])}}catch(l){console.error('An unexpected error occurred: '+l)}finally{return d}};function z(c){var d=[];try{d=c.querySelectorAll('input, select, button')}catch(b){}return d}function u(c,d){if(c){var b;d&&(b=c.value);'function'===typeof c.click&&c.click();'function'===typeof c.focus&&c.focus();d&&c.value!==b&&(c.value=b)}};\
	\
	return JSON.stringify(q(document, 'oneshotUUID'));\
})(document);\
\
";

static NSString *const OPWebViewFillScript = @";(function(document, fillScript, undefined) {\
var isFirefox = false, isChrome = false, isSafari = true;\
\
	var g=!0,h=!0,k=!0;\
function n(a){var b=null;return a?0===a.indexOf('https://')&&'http:'===document.location.protocol&&(b=document.querySelectorAll('input[type=password]'),0<b.length&&(confirmResult=confirm('1Password warning: This is an unsecured HTTP page, and any information you submit can potentially be seen and changed by others. This Login was originally saved on a secure (HTTPS) page.\\n\\nDo you still wish to fill this login?'),0==confirmResult))?!0:!1:!1}\
function m(a){var b,c=[],d=a.properties,e=1,f=[];d&&d.delay_between_operations&&(e=d.delay_between_operations);if(!n(a.savedURL)){var s=function(a,b){var d=a[0];if(void 0===d)b();else{if('delay'===d.operation||'delay'===d[0])e=d.parameters?d.parameters[0]:d[1];else{if(d=p(d))for(var l=0;l<d.length;l++)-1===f.indexOf(d[l])&&f.push(d[l]);c=c.concat(f.map(function(a){return a&&a.hasOwnProperty('opid')?a.opid:null}))}setTimeout(function(){s(a.slice(1),b)},e)}};g=k=!0;if(b=a.options)b.hasOwnProperty('animate')&&\
(h=b.animate),b.hasOwnProperty('markFilling')&&(g=b.markFilling);if((b=a.metadata)&&b.hasOwnProperty('action'))switch(b.action){case 'fillPassword':g=!1;break;case 'fillLogin':k=!1}a.hasOwnProperty('script')&&(b=a.script,s(b,function(){a.hasOwnProperty('autosubmit')&&'function'==typeof autosubmit&&(a.itemType&&'fillLogin'!==a.itemType||(0<f.length?setTimeout(function(){autosubmit(a.autosubmit,d.allow_clicky_autosubmit,f)},AUTOSUBMIT_DELAY):DEBUG_AUTOSUBMIT&&console.log('[AUTOSUBMIT] Not attempting to submit since no fields were filled: ',\
f)));'object'==typeof protectedGlobalPage&&protectedGlobalPage.b('fillItemResults',{documentUUID:documentUUID,fillContextIdentifier:a.fillContextIdentifier,usedOpids:c},function(){fillingItemType=null})}))}}var y={fill_by_opid:q,fill_by_query:r,click_on_opid:t,click_on_query:u,touch_all_fields:v,simple_set_value_by_query:w,focus_by_opid:x,delay:null};\
function p(a){var b;if(a.hasOwnProperty('operation')&&a.hasOwnProperty('parameters'))b=a.operation,a=a.parameters;else if('[object Array]'===Object.prototype.toString.call(a))b=a[0],a=a.splice(1);else return null;return y.hasOwnProperty(b)?y[b].apply(this,a):null}function q(a,b){var c;return(c=z(a))?(A(c,b),[c]):null}function r(a,b){var c;c=B(a);return Array.prototype.map.call(Array.prototype.slice.call(c),function(a){A(a,b);return a},this)}\
function w(a,b){var c,d=[];c=B(a);Array.prototype.forEach.call(Array.prototype.slice.call(c),function(a){a.disabled||a.a||a.readOnly||void 0===a.value||(a.value=b,d.push(a))});return d}function x(a){(a=z(a))&&C(a,!0);return null}function t(a){return(a=z(a))?C(a,!1)?[a]:null:null}function u(a){a=B(a);return Array.prototype.map.call(Array.prototype.slice.call(a),function(a){C(a,!0);return[a]},this)}function v(){D()};var E={'true':!0,y:!0,1:!0,yes:!0,'✓':!0},F=200;function A(a,b){var c;if(!(!a||null===b||void 0===b||k&&(a.disabled||a.a||a.readOnly)))switch(g&&a.form&&!a.form.opfilled&&(a.form.opfilled=!0),a.type?a.type.toLowerCase():null){case 'checkbox':c=b&&1<=b.length&&E.hasOwnProperty(b.toLowerCase())&&!0===E[b.toLowerCase()];a.checked===c||G(a,function(a){a.checked=c});break;case 'radio':!0===E[b.toLowerCase()]&&a.click();break;default:a.value==b||G(a,function(a){a.value=b})}}\
function G(a,b){H(a);b(a);I(a);J(a)&&(a.className+=' com-agilebits-onepassword-extension-animated-fill',setTimeout(function(){a&&a.className&&(a.className=a.className.replace(/(\\s)?com-agilebits-onepassword-extension-animated-fill/,''))},F))};document.elementForOPID=z;function K(a,b){var c;isFirefox?(c=document.createEvent('KeyboardEvent'),c.initKeyEvent(b,!0,!1,null,!1,!1,!1,!1,0,0)):(c=a.ownerDocument.createEvent('Events'),c.initEvent(b,!0,!1),c.charCode=0,c.keyCode=0,c.which=0,c.srcElement=a,c.target=a);return c}\
function H(a){var b=a.value;C(a,!1);a.dispatchEvent(K(a,'keydown'));a.dispatchEvent(K(a,'keypress'));a.dispatchEvent(K(a,'keyup'));if(''===a.value||a.dataset['com.agilebits.onepassword.initialValue']&&a.value===a.dataset['com.agilebits.onepassword.initialValue'])a.value=b}\
function I(a){var b=a.value,c=a.ownerDocument.createEvent('HTMLEvents'),d=a.ownerDocument.createEvent('HTMLEvents');a.dispatchEvent(K(a,'keydown'));a.dispatchEvent(K(a,'keypress'));a.dispatchEvent(K(a,'keyup'));d.initEvent('input',!0,!0);a.dispatchEvent(d);c.initEvent('change',!0,!0);a.dispatchEvent(c);a.blur();if(''===a.value||a.dataset['com.agilebits.onepassword.initialValue']&&a.value===a.dataset['com.agilebits.onepassword.initialValue'])a.value=b}\
function L(){var a=RegExp('((\\\\b|_|-)pin(\\\\b|_|-)|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i');return Array.prototype.slice.call(B(\"input[type='text']\")).filter(function(b){return b.value&&a.test(b.value)},this)}function D(){L().forEach(function(a){H(a);a.click&&a.click();I(a)})}\
window.LOGIN_TITLES=[/^\\W*log\\W*[oi]n\\W*$/i,/log\\W*[oi]n (?:securely|now)/i,/^\\W*sign\\W*[oi]n\\W*$/i,'continue','submit','weiter','accès','вход','connexion','entrar','anmelden','accedi','valider','登录','लॉग इन करें'];window.CHANGE_PASSWORD_TITLES=['change password','save changes'];window.LOGIN_RED_HERRING_TITLES=['already have an account','sign in with'];window.REGISTER_TITLES='register;sign up;signup;join;create my account;регистрация;inscription;regístrate;cadastre-se;registrieren;registrazione;注册;साइन अप करें'.split(';');\
window.SEARCH_TITLES='search find поиск найти искать recherche suchen buscar suche ricerca procurar 検索'.split(' ');window.FORGOT_PASSWORD_TITLES='forgot geändert vergessen hilfe changeemail español'.split(' ');window.REMEMBER_ME_TITLES=['remember me','rememberme','keep me signed in'];window.BACK_TITLES=['back','назад'];\
function J(a){var b;if(b=h)a:{b=a;for(var c=a.ownerDocument,d=c?c.defaultView:{},e;b&&b!==c;){e=d.getComputedStyle&&b instanceof Element?d.getComputedStyle(b,null):b.style;if(!e){b=!0;break a}if('none'===e.display||'hidden'==e.visibility){b=!1;break a}b=b.parentNode}b=b===c}return b?-1!=='email text password number tel url'.split(' ').indexOf(a.type||''):!1}\
function z(a){var b;if(void 0===a||null===a)return null;try{var c=Array.prototype.slice.call(B('input, select, button')),d=c.filter(function(b){return b.opid==a});if(0<d.length)b=d[0],1<d.length&&console.warn('More than one element found with opid '+a);else{var e=parseInt(a.split('__')[1],10);isNaN(e)||(b=c[e])}}catch(f){console.error('An unexpected error occurred: '+f)}finally{return b}};function B(a){var b=document,c=[];try{c=b.querySelectorAll(a)}catch(d){}return c}function C(a,b){if(!a)return!1;var c;b&&(c=a.value);'function'===typeof a.click&&a.click();'function'===typeof a.focus&&a.focus();b&&a.value!==c&&(a.value=c);return'function'===typeof a.click||'function'===typeof a.focus};\
\
	m(fillScript);\
	return JSON.stringify({'success': true});\
})\
\
";


#pragma mark - Deprecated methods

/*
 Deprecated in version 1.5
 Use fillItemIntoWebView:forViewController:sender:showOnlyLogins:completion: instead
 */
- (void)fillLoginIntoWebView:(nonnull id)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	[self fillItemIntoWebView:webView forViewController:viewController sender:sender showOnlyLogins:YES completion:completion];
}

@end
