//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"

// Version
#define VERSION_NUMBER @(182)
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

- (void)findLoginForURLString:(nonnull NSString *)URLString forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nullable void (^)(NSDictionary * __nullable loginDictionary, NSError * __nullable error))completion {
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

- (void)storeLoginForURLString:(nonnull NSString *)URLString loginDetails:(nullable NSDictionary *)loginDetailsDictionary passwordGenerationOptions:(nullable NSDictionary *)passwordGenerationOptions forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nullable void (^)(NSDictionary * __nullable loginDictionary, NSError * __nullable error))completion {
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

- (void)changePasswordForLoginForURLString:(nonnull NSString *)URLString loginDetails:(nullable NSDictionary *)loginDetailsDictionary passwordGenerationOptions:(nullable NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(nullable id)sender completion:(nullable void (^)(NSDictionary * __nullable loginDictionary, NSError * __nullable error))completion {
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

- (void)fillItemIntoWebView:(nonnull id)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(nullable void (^)(BOOL success, NSError * __nullable error))completion {
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

- (void)createExtensionItemForWebView:(nonnull id)webView completion:(void (^)(NSExtensionItem * __nullable extensionItem, NSError * __nullable error))completion {
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

- (void)fillReturnedItems:(nullable NSArray *)returnedItems intoWebView:(nonnull id)webView completion:(nullable void (^)(BOOL success, NSError * __nullable error))completion {
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

- (void)findLoginIn1PasswordWithURLString:(nonnull NSString *)URLString collectedPageDetails:(nullable NSString *)collectedPageDetails forWebViewController:(nonnull UIViewController *)forViewController sender:(nullable id)sender withWebView:(nonnull id)webView showOnlyLogins:(BOOL)yesOrNo completion:(void (^)(BOOL success, NSError * __nullable error))completion {
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
- (void)fillItemIntoWKWebView:(nonnull WKWebView *)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(void (^)(BOOL success, NSError * __nullable error))completion {
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

- (void)fillItemIntoUIWebView:(nonnull UIWebView *)webView webViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(void (^)(BOOL success, NSError * __nullable error))completion {
	NSString *collectedPageDetails = [webView stringByEvaluatingJavaScriptFromString:OPWebViewCollectFieldsScript];
	[self findLoginIn1PasswordWithURLString:webView.request.URL.absoluteString collectedPageDetails:collectedPageDetails forWebViewController:viewController sender:sender withWebView:webView showOnlyLogins:yesOrNo completion:^(BOOL success, NSError *error) {
		if (completion) {
			completion(success, error);
		}
	}];
}

- (void)executeFillScript:(NSString * __nullable)fillScript inWebView:(nonnull id)webView completion:(void (^)(BOOL success, NSError * __nullable error))completion {

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
- (void)processExtensionItem:(nullable NSExtensionItem *)extensionItem completion:(void (^)(NSDictionary *itemDictionary, NSError * __nullable error))completion {
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

- (void)createExtensionItemForURLString:(nonnull NSString *)URLString webPageDetails:(nullable NSString *)webPageDetails completion:(void (^)(NSExtensionItem *extensionItem, NSError * __nullable error))completion {
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
\
	document.elementsByOPID={};\
function n(d,e){function f(a,b){var c=a[b];if('string'==typeof c)return c;c=a.getAttribute(b);return'string'==typeof c?c:null}function h(a,b){if(-1===['text','password'].indexOf(b.type.toLowerCase())||!(l.test(a.value)||l.test(a.htmlID)||l.test(a.htmlName)||l.test(a.placeholder)||l.test(a['label-tag'])||l.test(a['label-data'])||l.test(a['label-aria'])))return!1;if(!a.visible)return!0;if('password'==b.type.toLowerCase())return!1;var c=b.type,d=b.value;b.focus();b.value!==d&&(b.value=d);return c!==\
b.type}function r(a){switch(m(a.type)){case 'checkbox':return a.checked?'✓':'';case 'hidden':a=a.value;if(!a||'number'!=typeof a.length)return'';254<a.length&&(a=a.substr(0,254)+'...SNIPPED');return a;default:return a.value}}function v(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){var c=a.text,c=c?m(c).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,''):null;return[c?c:null,a.value]}),{options:a}):null}function F(a){var b;for(a=a.parentElement||a.parentNode;a&&\
'td'!=m(a.tagName);)a=a.parentElement||a.parentNode;if(!a||void 0===a)return null;b=a.parentElement||a.parentNode;if('tr'!=b.tagName.toLowerCase())return null;b=b.previousElementSibling;if(!b||'tr'!=(b.tagName+'').toLowerCase()||b.cells&&a.cellIndex>=b.cells.length)return null;a=s(b.cells[a.cellIndex]);return a=u(a)}function A(a){var b=d.documentElement,c=a.getBoundingClientRect(),e=b.getBoundingClientRect(),f=c.left-b.clientLeft,b=c.top-b.clientTop;return a.offsetParent?0>f||f>e.width||0>b||b>e.height?\
w(a):(e=a.ownerDocument.elementFromPoint(f+3,b+3))?'label'===m(e.tagName)?e===B(a):e.tagName===a.tagName:!1:!1}function w(a){for(var b;a!==d&&a;a=a.parentNode){b=t.getComputedStyle?t.getComputedStyle(a,null):a.style;if(!b)return!0;if('none'===b.display||'hidden'==b.visibility)return!1}return a===d}function B(a){var b=[];a.id&&(b=b.concat(Array.prototype.slice.call(x(d,'label[for='+JSON.stringify(a.id)+']'))));a.name&&(b=b.concat(Array.prototype.slice.call(x(d,'label[for='+JSON.stringify(a.name)+']'))));\
if(0<b.length)return b.map(function(a){return s(a)}).join('');for(;a&&a!=d;a=a.parentNode)if('label'===m(a.tagName))return s(a);return null}function g(a,b,c,d){void 0!==d&&d===c||null===c||void 0===c||(a[b]=c)}function m(a){return'string'===typeof a?a.toLowerCase():(''+a).toLowerCase()}function x(a,b){var c=[];try{c=a.querySelectorAll(b)}catch(d){}return c}var t=d.defaultView?d.defaultView:window,p,l=RegExp('((\\\\b|_|-)pin(\\\\b|_|-)|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)',\
'i');p=Array.prototype.slice.call(x(d,'form')).map(function(a,b){var c={},d='__form__'+b;a.opid=d;c.opid=d;g(c,'htmlName',f(a,'name'));g(c,'htmlID',f(a,'id'));g(c,'htmlAction',y(f(a,'action')));g(c,'htmlMethod',f(a,'method'));return c});var q=Array.prototype.slice.call(z(d)).map(function(a,b){var c={},e='__'+b,k=-1==a.maxLength?999:a.maxLength;if(!k||'number'===typeof k&&isNaN(k))k=999;d.elementsByOPID[e]=a;a.opid=e;c.opid=e;c.elementNumber=b;g(c,'maxLength',Math.min(k,999),999);c.visible=w(a);c.viewable=\
A(a);g(c,'htmlID',f(a,'id'));g(c,'htmlName',f(a,'name'));g(c,'htmlClass',f(a,'class'));g(c,'tabindex',f(a,'tabindex'));if('hidden'!=m(a.type)){g(c,'label-tag',B(a));g(c,'label-data',f(a,'data-label'));g(c,'label-aria',f(a,'aria-label'));g(c,'label-top',F(a));e=[];for(k=a;k&&k.nextSibling;){k=k.nextSibling;if(C(k))break;D(e,k)}g(c,'label-right',e.join(''));e=[];E(a,e);e=e.reverse().join('');g(c,'label-left',e);g(c,'placeholder',f(a,'placeholder'))}g(c,'rel',f(a,'rel'));g(c,'type',m(f(a,'type')));g(c,\
'value',r(a));g(c,'checked',a.checked,!1);g(c,'autoCompleteType',a.getAttribute('x-autocompletetype')||a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'),'off');g(c,'disabled',a.disabled);g(c,'readonly',a.a||a.readOnly);g(c,'selectInfo',v(a));g(c,'aria-hidden','true'==a.getAttribute('aria-hidden'),!1);g(c,'aria-disabled','true'==a.getAttribute('aria-disabled'),!1);g(c,'aria-haspopup','true'==a.getAttribute('aria-haspopup'),!1);g(c,'data-unmasked',a.dataset.unmasked);g(c,'data-stripe',\
f(a,'data-stripe'));g(c,'onepasswordFieldType',a.dataset.onepasswordFieldType||a.type);g(c,'onepasswordDesignation',a.dataset.onepasswordDesignation);g(c,'onepasswordSignInUrl',a.dataset.onepasswordSignInUrl);g(c,'onepasswordSectionTitle',a.dataset.onepasswordSectionTitle);g(c,'onepasswordSectionFieldKind',a.dataset.onepasswordSectionFieldKind);g(c,'onepasswordSectionFieldTitle',a.dataset.onepasswordSectionFieldTitle);g(c,'onepasswordSectionFieldValue',a.dataset.onepasswordSectionFieldValue);a.form&&\
(c.form=f(a.form,'opid'));g(c,'fakeTested',h(c,a),!1);return c});q.filter(function(a){return a.fakeTested}).forEach(function(a){var b=d.elementsByOPID[a.opid];b.getBoundingClientRect();var c=b.value;!b||b&&'function'!==typeof b.click||b.click();b.focus();G(b,'keydown');G(b,'keyup');G(b,'keypress');b.value!==c&&(b.value=c);b.click&&b.click();a.postFakeTestVisible=w(b);a.postFakeTestViewable=A(b);a.postFakeTestType=b.type;a=b.value;var c=b.ownerDocument.createEvent('HTMLEvents'),e=b.ownerDocument.createEvent('HTMLEvents');\
G(b,'keydown');G(b,'keyup');G(b,'keypress');e.initEvent('input',!0,!0);b.dispatchEvent(e);c.initEvent('change',!0,!0);b.dispatchEvent(c);b.blur();b.value!==a&&(b.value=a)});p={documentUUID:e,title:d.title,url:t.location.href,documentUrl:d.location.href,tabUrl:t.location.href,forms:function(a){var b={};a.forEach(function(a){b[a.opid]=a});return b}(p),fields:q,collectedTimestamp:(new Date).getTime()};(q=document.querySelector('[data-onepassword-display-title]'))&&q.dataset[DISPLAY_TITLE_ATTRIBUE]&&\
(p.displayTitle=q.dataset.onepasswordTitle);return p};document.elementForOPID=H;function G(d,e){var f;f=d.ownerDocument.createEvent('KeyboardEvent');f.initKeyboardEvent?f.initKeyboardEvent(e,!0,!0):f.initKeyEvent&&f.initKeyEvent(e,!0,!0,null,!1,!1,!1,!1,0,0);d.dispatchEvent(f)}window.LOGIN_TITLES=[/^\\W*log\\W*[oi]n\\W*$/i,/log\\W*[oi]n (?:securely|now)/i,/^\\W*sign\\W*[oi]n\\W*$/i,'continue','submit','weiter','accès','вход','connexion','entrar','anmelden','accedi','valider','登录','लॉग इन करें'];window.LOGIN_RED_HERRING_TITLES=['already have an account','sign in with'];\
window.REGISTER_TITLES='register;sign up;signup;join;регистрация;inscription;regístrate;cadastre-se;registrieren;registrazione;注册;साइन अप करें'.split(';');window.SEARCH_TITLES='search find поиск найти искать recherche suchen buscar suche ricerca procurar 検索'.split(' ');window.FORGOT_PASSWORD_TITLES='forgot geändert vergessen hilfe changeemail español'.split(' ');window.REMEMBER_ME_TITLES=['remember me','rememberme','keep me signed in'];window.BACK_TITLES=['back','назад'];\
function s(d){return d.textContent||d.innerText}function u(d){var e=null;d&&(e=d.replace(/^\\s+|\\s+$|\\r?\\n.*$/mg,''),e=0<e.length?e:null);return e}function D(d,e){var f;f='';3===e.nodeType?f=e.nodeValue:1===e.nodeType&&(f=s(e));(f=u(f))&&d.push(f)}function C(d){var e;d&&void 0!==d?(e='select option input form textarea button table iframe body head script'.split(' '),d?(d=d?(d.tagName||'').toLowerCase():'',e=e.constructor==Array?0<=e.indexOf(d):d===e):e=!1):e=!0;return e}\
function E(d,e,f){var h;for(f||(f=0);d&&d.previousSibling;){d=d.previousSibling;if(C(d))return;D(e,d)}if(d&&0===e.length){for(h=null;!h;){d=d.parentElement||d.parentNode;if(!d)return;for(h=d.previousSibling;h&&!C(h)&&h.lastChild;)h=h.lastChild}C(h)||(D(e,h),0===e.length&&E(h,e,f+1))}}\
function H(d){var e;if(void 0===d||null===d)return null;try{var f=Array.prototype.slice.call(z(document)),h=f.filter(function(e){return e.opid==d});if(0<h.length)e=h[0],1<h.length&&console.warn('More than one element found with opid '+d);else{var r=parseInt(d.split('__')[1],10);isNaN(r)||(e=f[r])}}catch(v){console.error('An unexpected error occurred: '+v)}finally{return e}};var I=/^[\\/\\?]/;function y(d){if(!d)return null;if(0==d.indexOf('http'))return d;var e=window.location.protocol+'//'+window.location.hostname;window.location.port&&''!=window.location.port&&(e+=':'+window.location.port);d.match(I)||(d='/'+d);return e+d}function z(d){var e=[];try{e=d.querySelectorAll('input, select, button')}catch(f){}return e};\
	\
	return JSON.stringify(n(document, 'oneshotUUID'));\
})(document);\
";

static NSString *const OPWebViewFillScript = @";(function(document, fillScript, undefined) {\
	\
	var f=!0,h=!0;\
function l(a){var b=null;return a?0===a.indexOf('https://')&&'http:'===document.location.protocol&&(b=document.querySelectorAll('input[type=password]'),0<b.length&&(confirmResult=confirm('1Password warning: This is an unsecured HTTP page, and any information you submit can potentially be seen and changed by others. This Login was originally saved on a secure (HTTPS) page.\\n\\nDo you still wish to fill this login?'),0==confirmResult))?!0:!1:!1}\
function k(a){var b,c=[],d=a.properties,e=1,g;d&&d.delay_between_operations&&(e=d.delay_between_operations);if(!l(a.savedURL)){g=function(a,b){var d=a[0];void 0===d?b():('delay'===d.operation||'delay'===d[0]?e=d.parameters?d.parameters[0]:d[1]:c.push(m(d)),setTimeout(function(){g(a.slice(1),b)},e))};if(b=a.options)b.hasOwnProperty('animate')&&(h=b.animate),b.hasOwnProperty('markFilling')&&(f=b.markFilling);a.itemType&&'fillPassword'===a.itemType&&(f=!1);a.hasOwnProperty('script')&&(b=a.script,g(b,\
function(){c=Array.prototype.concat.apply(c,void 0);a.hasOwnProperty('autosubmit')&&'function'==typeof autosubmit&&(a.itemType&&'fillLogin'!==a.itemType||setTimeout(function(){autosubmit(a.autosubmit,d.allow_clicky_autosubmit)},AUTOSUBMIT_DELAY));'object'==typeof protectedGlobalPage&&protectedGlobalPage.a('fillItemResults',{documentUUID:documentUUID,fillContextIdentifier:a.fillContextIdentifier,usedOpids:c},function(){fillingItemType=null})}))}}\
var v={fill_by_opid:n,fill_by_query:p,click_on_opid:q,click_on_query:r,touch_all_fields:s,simple_set_value_by_query:t,focus_by_opid:u,delay:null};function m(a){var b;if(a.hasOwnProperty('operation')&&a.hasOwnProperty('parameters'))b=a.operation,a=a.parameters;else if('[object Array]'===Object.prototype.toString.call(a))b=a[0],a=a.splice(1);else return null;return v.hasOwnProperty(b)?v[b].apply(this,a):null}function n(a,b){var c;return(c=w(a))?(x(c,b),c.opid):null}\
function p(a,b){var c;c=y(a);return Array.prototype.map.call(Array.prototype.slice.call(c),function(a){x(a,b);return a.opid},this)}function t(a,b){var c,d=[];c=y(a);Array.prototype.forEach.call(Array.prototype.slice.call(c),function(a){void 0!==a.value&&(a.value=b,d.push(a.opid))});return d}function u(a){if(a=w(a))'function'===typeof a.click&&a.click(),'function'===typeof a.focus&&a.focus();return null}function q(a){return(a=w(a))?z(a)?a.opid:null:null}\
function r(a){a=y(a);return Array.prototype.map.call(Array.prototype.slice.call(a),function(a){z(a);'function'===typeof a.click&&a.click();'function'===typeof a.focus&&a.focus();return a.opid},this)}function s(){A()};var B={'true':!0,y:!0,1:!0,yes:!0,'✓':!0},C=200;function x(a,b){var c;if(a&&null!==b&&void 0!==b)switch(f&&a.form&&!a.form.opfilled&&(a.form.opfilled=!0),a.type?a.type.toLowerCase():null){case 'checkbox':c=b&&1<=b.length&&B.hasOwnProperty(b.toLowerCase())&&!0===B[b.toLowerCase()];a.checked===c||D(a,function(a){a.checked=c});break;case 'radio':!0===B[b.toLowerCase()]&&a.click();break;default:a.value==b||D(a,function(a){a.value=b})}}\
function D(a,b){E(a);b(a);F(a);G(a)&&(a.className+=' com-agilebits-onepassword-extension-animated-fill',setTimeout(function(){a&&a.className&&(a.className=a.className.replace(/(\\s)?com-agilebits-onepassword-extension-animated-fill/,''))},C))};document.elementForOPID=w;function H(a,b){var c;c=a.ownerDocument.createEvent('KeyboardEvent');c.initKeyboardEvent?c.initKeyboardEvent(b,!0,!0):c.initKeyEvent&&c.initKeyEvent(b,!0,!0,null,!1,!1,!1,!1,0,0);a.dispatchEvent(c)}function E(a){var b=a.value;z(a);a.focus();H(a,'keydown');H(a,'keyup');H(a,'keypress');a.value!==b&&(a.value=b)}\
function F(a){var b=a.value,c=a.ownerDocument.createEvent('HTMLEvents'),d=a.ownerDocument.createEvent('HTMLEvents');H(a,'keydown');H(a,'keyup');H(a,'keypress');d.initEvent('input',!0,!0);a.dispatchEvent(d);c.initEvent('change',!0,!0);a.dispatchEvent(c);a.blur();a.value!==b&&(a.value=b)}function z(a){if(!a||a&&'function'!==typeof a.click)return!1;a.click();return!0}\
function I(){var a=RegExp('((\\\\b|_|-)pin(\\\\b|_|-)|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i');return Array.prototype.slice.call(y(\"input[type='text']\")).filter(function(b){return b.value&&a.test(b.value)},this)}function A(){I().forEach(function(a){E(a);a.click&&a.click();F(a)})}\
window.LOGIN_TITLES=[/^\\W*log\\W*[oi]n\\W*$/i,/log\\W*[oi]n (?:securely|now)/i,/^\\W*sign\\W*[oi]n\\W*$/i,'continue','submit','weiter','accès','вход','connexion','entrar','anmelden','accedi','valider','登录','लॉग इन करें'];window.LOGIN_RED_HERRING_TITLES=['already have an account','sign in with'];window.REGISTER_TITLES='register;sign up;signup;join;регистрация;inscription;regístrate;cadastre-se;registrieren;registrazione;注册;साइन अप करें'.split(';');window.SEARCH_TITLES='search find поиск найти искать recherche suchen buscar suche ricerca procurar 検索'.split(' ');\
window.FORGOT_PASSWORD_TITLES='forgot geändert vergessen hilfe changeemail español'.split(' ');window.REMEMBER_ME_TITLES=['remember me','rememberme','keep me signed in'];window.BACK_TITLES=['back','назад'];\
function G(a){var b;if(b=h)a:{b=a;for(var c=a.ownerDocument,c=c?c.defaultView:{},d;b&&b!==document;){d=c.getComputedStyle?c.getComputedStyle(b,null):b.style;if(!d){b=!0;break a}if('none'===d.display||'hidden'==d.visibility){b=!1;break a}b=b.parentNode}b=b===document}return b?-1!=='email text password number tel url'.split(' ').indexOf(a.type||''):!1}\
function w(a){var b;if(void 0===a||null===a)return null;try{var c=Array.prototype.slice.call(y('input, select, button')),d=c.filter(function(b){return b.opid==a});if(0<d.length)b=d[0],1<d.length&&console.warn('More than one element found with opid '+a);else{var e=parseInt(a.split('__')[1],10);isNaN(e)||(b=c[e])}}catch(g){console.error('An unexpected error occurred: '+g)}finally{return b}};function y(a){var b=document,c=[];try{c=b.querySelectorAll(a)}catch(d){}return c};\
\
	k(fillScript);\
	return JSON.stringify({'success': true});\
})\
";


#pragma mark - Deprecated methods

/*
 Deprecated in version 1.5
 Use fillItemIntoWebView:forViewController:sender:showOnlyLogins:completion: instead
 */
- (void)fillLoginIntoWebView:(nonnull id)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nullable void (^)(BOOL success, NSError * __nullable error))completion {
	[self fillItemIntoWebView:webView forViewController:viewController sender:sender showOnlyLogins:YES completion:completion];
}

@end
