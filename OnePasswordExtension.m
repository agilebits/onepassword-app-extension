//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"

// Version
#define VERSION_NUMBER @(200)
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

// WKUserScript message names
static NSString *const kWKUserScriptMessageCollectDocuments = @"collectDocuments";
static NSString *const kWKUserScriptMessageCollectFieldsResult = @"collectFieldsResult";
static NSString *const kWKUserScriptMessageExecuteFillScript = @"executeFillScript";
static NSString *const kWKUserScriptMessageFillItemResults = @"fillItemResults";

@interface OnePasswordExtension() {
	OnePasswordExtensionItemCompletionBlock _pendingCompletion;
}
@property (weak) WKWebView *webView;
@property (weak) UIViewController *viewController;
@property (weak) id sender;
@property (readonly) NSString *securityToken;
@end
@implementation OnePasswordExtension

#pragma mark - Public Methods

static WKUserScript *injectedUserScript;

+ (OnePasswordExtension *)sharedExtension {
	static dispatch_once_t onceToken;
	static OnePasswordExtension *__sharedExtension;

	dispatch_once(&onceToken, ^{
		__sharedExtension = [OnePasswordExtension new];
	});

	return __sharedExtension;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _securityToken = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSString *wrappedUserScript = [OPUserScript stringByReplacingOccurrencesOfString:@"$SECURITY_TOKEN" withString:self.securityToken];
        injectedUserScript = [[WKUserScript alloc] initWithSource:wrappedUserScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    }
    return self;
}

- (BOOL)isAppExtensionAvailable {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"org-appextension-feature-password-management://"]];
}


- (void) userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	NSLog(@"Received message from userContentController: %@", message);
    NSString *name = message.body[@"name"];
    id payload = message.body[@"payload"];
    if ([name isEqualToString:kWKUserScriptMessageCollectFieldsResult]) {
        if ([payload count] > 0) {
			if (_pendingCompletion) {
				[self createExtensionItemForURLString:message.frameInfo.request.URL.absoluteString webPageDetails:payload completion:_pendingCompletion];
			} else {
				[self findLoginIn1PasswordWithURLString:message.frameInfo.request.URL.absoluteString collectedPageDetails:payload forWebViewController:self.viewController sender:self.sender withWebView:self.webView showOnlyLogins:YES completion:^(BOOL success, NSError *findLoginError) {
					NSLog(@"Found Login and filled? %d", success);
				}];
			}
		}
		else {
			NSLog(@"No fields in payload");
		}
    } else if ([name isEqualToString:kWKUserScriptMessageFillItemResults]) {
        NSLog(@"Filled item!");
	} else {
		NSLog(@"Unexpected message: %@", name);
	}
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
}

#pragma mark - Web View filling Support
- (WKUserContentController *)configureUserContentController:(nullable WKUserContentController *)contentController {
	if (contentController == nil) {
		contentController = [WKUserContentController new];
	}

	[contentController addUserScript:injectedUserScript];
	[contentController addScriptMessageHandler:self name:self.securityToken];
	return contentController;
}

- (void)fillItemIntoWebView:(nonnull WKWebView *)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
    self.webView = webView;
    self.viewController = viewController;
	self.sender = sender;
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");
	NSAssert([webView isKindOfClass:[WKWebView class]], @"webView must be an instance of WKWebView.");
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"var e = new CustomEvent(\"%@\", {detail: {name: \"collectDocuments\"}}); window.dispatchEvent(e);", self.securityToken] completionHandler:^(NSString *result, NSError *error) {
        if (error != nil){
            NSLog(@"1Password Extension failed to collect web page fields: %@", error);
            return;
        }
    }];
}

#pragma mark - Support for custom UIActivityViewControllers

- (BOOL)isOnePasswordExtensionActivityType:(nullable NSString *)activityType {
	return [@"com.agilebits.onepassword-ios.extension" isEqualToString:activityType] || [@"com.agilebits.beta.onepassword-ios.extension" isEqualToString:activityType];
}

- (void)createExtensionItemForWebView:(nonnull WKWebView *)webView completion:(nonnull OnePasswordExtensionItemCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert([webView isKindOfClass:[WKWebView class]], @"webView must be an instance of WKWebView.");
    self.webView = webView;
	_pendingCompletion = completion;
    [webView evaluateJavaScript:[NSString stringWithFormat:@"var e = new CustomEvent(\"%@\", {detail: {name: \"collectDocuments\"}}); window.dispatchEvent(e);", self.securityToken] completionHandler:^(NSString *result, NSError *evaluateError) {
        NSLog(@"Success dispatching collect event");
    }];
}

- (void)fillReturnedItems:(nullable NSArray *)returnedItems intoWebView:(nonnull WKWebView *)webView completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");
    NSAssert([webView isKindOfClass:[WKWebView class]], @"webView must be an instance of WKWebView.");

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
	return [NSExtensionItem class] != nil;
}

- (void)findLoginIn1PasswordWithURLString:(nonnull NSString *)URLString collectedPageDetails:(nullable NSDictionary *)collectedPageDetails forWebViewController:(nonnull UIViewController *)forViewController sender:(nullable id)sender withWebView:(nonnull WKWebView *)webView showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	if ([URLString length] == 0) {
		NSError *URLStringError = [OnePasswordExtension failedToObtainURLStringFromWebViewError];
		NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", URLStringError);
		if (completion) {
			completion(NO, URLStringError);
		}
		return;
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : collectedPageDetails };

	NSString *typeIdentifier = yesOrNo ? kUTTypeAppExtensionFillWebViewAction  : kUTTypeAppExtensionFillBrowserAction;
    UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:self.viewController sender: nil typeIdentifier:typeIdentifier];
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

	[self.viewController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)executeFillScript:(NSString * __nullable)fillScript inWebView:(WKWebView *)webView completion:(nonnull OnePasswordSuccessCompletionBlock)completion {

	if (fillScript == nil) {
		NSLog(@"Failed to executeFillScript, fillScript is missing");
		if (completion) {
			completion(NO, [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedStringFromTable(@"Failed to fill web page because script is missing", @"OnePasswordExtension", @"1Password Extension Error Message") underlyingError:nil]);
		}

		return;
	}
	
	NSString *eventScript = [NSString stringWithFormat:@"var e = new CustomEvent(\"%@\", {detail: {name: \"executeFillScript\", payload: %@}}); window.dispatchEvent(e)", self.securityToken, fillScript];
	[webView evaluateJavaScript:eventScript completionHandler:^(id _Nullable result, NSError * _Nullable evaluationError) {
        BOOL success = (evaluationError == nil);
        NSError *error = nil;
        if (evaluationError != nil) {
            NSLog(@"Cannot executeFillScript, evaluateJavaScript failed: %@", evaluationError);
            error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedStringFromTable(@"Failed to fill web page because script could not be evaluated", @"OnePasswordExtension", @"1Password Extension Error Message") underlyingError:error];
        }

        if (completion) {
            completion(success, error);
        }
	}];
}

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
}

- (void)createExtensionItemForURLString:(nonnull NSString *)URLString webPageDetails:(nullable NSDictionary *)webPageDetails completion:(nonnull OnePasswordExtensionItemCompletionBlock)completion {
	
	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : webPageDetails };

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
	_pendingCompletion = nil;
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

static NSString *const OPUserScript = @";(function(document, undefined) {\
\
	var m={};window.OnePassword=m;m.a={};m.URLTools=m.a;m.a.h=function(a){return(a=new URL(a),a.hostname)?a.hostname.toLowerCase():null};m.a.g=function(a){return a=new URL(a,window.location.href),a.href};document.addEventListener('input',function(a){!1!==a.isTrusted&&'input'===a.target.tagName.toLowerCase()&&(a.target.dataset['com.agilebits.onepassword.userEdited']='yes')},!0);\
(function(a,b,c){b.FieldCollector=new function(){function e(a){return a?a.toString().toLowerCase():''}function d(a,b,e,d){d!==c&&d===e||null===e||e===c||(a[b]=e)}function g(a,b){var f=[];try{f=a.querySelectorAll(b)}catch(ga){console.error('[COLLECT FIELDS] Exception processing selector \"'+b+'\"')}return f}function l(b){var f,c=[];if(b.labels&&b.labels.length&&0<b.labels.length)c=Array.prototype.slice.call(b.labels);else{b.id&&(c=c.concat(Array.prototype.slice.call(g(a,'label[for='+JSON.stringify(b.id)+\
']'))));if(b.name){f=g(a,'label[for='+JSON.stringify(b.name)+']');for(var d=0;d<f.length;d++)-1===c.indexOf(f[d])&&c.push(f[d])}for(f=b;f&&f!=a;f=f.parentNode)'label'===e(f.tagName)&&-1===c.indexOf(f)&&c.push(f)}0===c.length&&(f=b.parentNode,'dd'===f.tagName.toLowerCase()&&null!==f.previousElementSibling&&'dt'===f.previousElementSibling.tagName.toLowerCase()&&c.push(f.previousElementSibling));return 0<c.length?c.map(function(a){return n(p(a))}).join(''):null}function q(a){var b;for(a=a.parentElement||\
a.parentNode;a&&'td'!=e(a.tagName);)a=a.parentElement||a.parentNode;if(!a||a===c)return null;b=a.parentElement||a.parentNode;if('tr'!=b.tagName.toLowerCase())return null;b=b.previousElementSibling;if(!b||'tr'!=(b.tagName+'').toLowerCase()||b.cells&&a.cellIndex>=b.cells.length)return null;a=p(b.cells[a.cellIndex]);return a=n(a)}function r(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){var b=a.text,b=b?e(b).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,\
''):null;return[b?b:null,a.value]}),{options:a}):null}function R(a){switch(e(a.type)){case 'checkbox':return a.checked?'✓':'';case 'hidden':a=a.value;if(!a||'number'!=typeof a.length)return'';254<a.length&&(a=a.substr(0,254)+'...SNIPPED');return a;case 'submit':case 'button':case 'reset':if(''===a.value)return n(p(a))||'';default:return a.value}}function S(a,b){if(-1===['text','password'].indexOf(b.type.toLowerCase())||!(k.test(a.value)||k.test(a.htmlID)||k.test(a.htmlName)||k.test(a.placeholder)||\
k.test(a['label-tag'])||k.test(a['label-data'])||k.test(a['label-aria'])))return!1;if(!a.visible)return!0;if('password'==b.type.toLowerCase())return!1;a=b.type;t(b,!0);return a!==b.type}function T(a){var b={};a.forEach(function(a){b[a.opid]=a});return b}function h(a,b){var c=a[b];if('string'==typeof c)return c;a=a.getAttribute(b);return'string'==typeof a?a:null}function G(a){return'input'===a.nodeName.toLowerCase()&&-1===a.type.search(/button|submit|reset|hidden|checkbox/i)}var w={},k=/((\\b|_|-)pin(\\b|_|-)|password|passwort|kennwort|(\\b|_|-)passe(\\b|_|-)|contraseña|senha|密码|adgangskode|hasło|wachtwoord)/i;\
this.collect=this.b=function(a,c){w={};var f=a.defaultView?a.defaultView:b,k=a.activeElement,Q=Array.prototype.slice.call(g(a,'form')).map(function(a,b){var c={};b='__form__'+b;a.opid=b;c.opid=b;d(c,'htmlName',h(a,'name'));d(c,'htmlID',h(a,'id'));d(c,'htmlAction',m.a.g(h(a,'action')));d(c,'htmlMethod',h(a,'method'));return c}),K=u(a).map(function(a,b){G(a)&&a.hasAttribute('value')&&!a.dataset['com.agilebits.onepassword.initialValue']&&(a.dataset['com.agilebits.onepassword.initialValue']=a.value);\
var c={},g='__'+b,f=-1==a.maxLength?999:a.maxLength;if(!f||'number'===typeof f&&isNaN(f))f=999;w[g]=a;a.opid=g;c.opid=g;c.elementNumber=b;d(c,'maxLength',Math.min(f,999),999);c.visible=v(a);c.viewable=x(a);d(c,'htmlID',h(a,'id'));d(c,'htmlName',h(a,'name'));d(c,'htmlClass',h(a,'class'));d(c,'tabindex',h(a,'tabindex'));d(c,'title',h(a,'title'));d(c,'userEdited',!!a.dataset['com.agilebits.onepassword.userEdited']);if('hidden'!=e(a.type)){d(c,'label-tag',l(a));d(c,'label-data',h(a,'data-label'));d(c,\
'label-aria',h(a,'aria-label'));d(c,'label-top',q(a));b=[];for(g=a;g&&g.nextSibling;){g=g.nextSibling;if(y(g))break;z(b,g)}d(c,'label-right',b.join(''));b=[];A(a,b);b=b.reverse().join('');d(c,'label-left',b);d(c,'placeholder',h(a,'placeholder'))}d(c,'rel',h(a,'rel'));d(c,'type',e(h(a,'type')));d(c,'value',R(a));d(c,'checked',a.checked,!1);d(c,'autoCompleteType',a.getAttribute('x-autocompletetype')||a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'),'off');d(c,'disabled',a.disabled);\
d(c,'readonly',a.f||a.readOnly);d(c,'selectInfo',r(a));d(c,'aria-hidden','true'==a.getAttribute('aria-hidden'),!1);d(c,'aria-disabled','true'==a.getAttribute('aria-disabled'),!1);d(c,'aria-haspopup','true'==a.getAttribute('aria-haspopup'),!1);d(c,'data-unmasked',a.dataset.unmasked);d(c,'data-stripe',h(a,'data-stripe'));d(c,'data-braintree-name',h(a,'data-braintree-name'));d(c,'onepasswordFieldType',a.dataset.onepasswordFieldType||a.type);d(c,'onepasswordDesignation',a.dataset.onepasswordDesignation);\
d(c,'onepasswordSignInUrl',a.dataset.onepasswordSignInUrl);d(c,'onepasswordSectionTitle',a.dataset.onepasswordSectionTitle);d(c,'onepasswordSectionFieldKind',a.dataset.onepasswordSectionFieldKind);d(c,'onepasswordSectionFieldTitle',a.dataset.onepasswordSectionFieldTitle);d(c,'onepasswordSectionFieldValue',a.dataset.onepasswordSectionFieldValue);a.form&&(c.form=h(a.form,'opid'));d(c,'fakeTested',S(c,a),!1);return c});K.filter(function(a){return a.fakeTested}).forEach(function(a){var b=w[a.opid];b.getBoundingClientRect();\
B(b);b.click&&b.click();a.postFakeTestVisible=v(b);a.postFakeTestViewable=x(b);a.postFakeTestType=b.type;C(b)});c={documentUUID:c,title:a.title,url:f.location.href,documentURL:a.location.href,forms:T(Q),fields:K,collectedTimestamp:(new Date).getTime()};(a=a.querySelector('[data-onepassword-title]'))&&a.dataset.onepasswordTitle&&(c.displayTitle=a.dataset.onepasswordTitle);k&&G(k)&&t(k,!0);return c};this.elementForOPID=this.c=function(a){return w[a]}}})(document,window,void 0);\
var D={'true':!0,y:!0,1:!0,yes:!0,'✓':!0};function E(a,b){var c;if(!(!a||null===b||void 0===b||F&&(a.disabled||a.f||a.readOnly)))switch(H&&!a.opfilled&&(a.opfilled=!0,a.form&&(a.form.opfilled=!0)),a.type?a.type.toLowerCase():null){case 'checkbox':c=b&&1<=b.length&&D.hasOwnProperty(b.toLowerCase())&&!0===D[b.toLowerCase()];a.checked===c||I(a,function(a){a.checked=c});break;case 'radio':!0===D[b.toLowerCase()]&&a.click();break;default:a.value==b||I(a,function(a){a.value=b})}}\
function I(a,b){B(a);b(a);C(a);J(a)&&(a.className+=' com-agilebits-onepassword-extension-animated-fill',setTimeout(function(){a&&a.className&&(a.className=a.className.replace(/(\\s)?com-agilebits-onepassword-extension-animated-fill/,''))},200))};document.elementForOPID=L;function M(a,b){var c;c=a.ownerDocument.createEvent('Events');c.initEvent(b,!0,!1);c.charCode=0;c.keyCode=0;c.which=0;c.srcElement=a;c.target=a;return c}function B(a){var b=a.value;t(a,!1);a.dispatchEvent(M(a,'keydown'));a.dispatchEvent(M(a,'keypress'));a.dispatchEvent(M(a,'keyup'));if(''===a.value||a.dataset['com.agilebits.onepassword.initialValue']&&a.value===a.dataset['com.agilebits.onepassword.initialValue'])a.value=b}\
function C(a){var b=a.value,c=a.ownerDocument.createEvent('HTMLEvents'),e=a.ownerDocument.createEvent('HTMLEvents');a.dispatchEvent(M(a,'keydown'));a.dispatchEvent(M(a,'keypress'));a.dispatchEvent(M(a,'keyup'));e.initEvent('input',!0,!0);a.dispatchEvent(e);c.initEvent('change',!0,!0);a.dispatchEvent(c);a.blur();if(''===a.value||a.dataset['com.agilebits.onepassword.initialValue']&&a.value===a.dataset['com.agilebits.onepassword.initialValue'])a.value=b}\
function N(){var a=/((\\b|_|-)pin(\\b|_|-)|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)/i;return Array.prototype.slice.call(O(document,\"input[type='text']\")).filter(function(b){return b.value&&a.test(b.value)},this)}function P(){N().forEach(function(a){B(a);a.click&&a.click();C(a)})}\
window.LOGIN_TITLES=[/^\\W*log\\W*[oi]n\\W*$/i,/log\\W*[oi]n (?:securely|now)/i,/^\\W*sign\\W*[oi]n\\W*$/i,'continue','submit','weiter','accès','вход','connexion','entrar','anmelden','accedi','valider','登录','लॉग इन करें'];window.CHANGE_PASSWORD_TITLES=[/^(change|update) password$/i,'save changes','update'];window.LOGIN_RED_HERRING_TITLES=['already have an account','sign in with'];\
window.REGISTER_TITLES=['register','sign up','signup','join',/^create (my )?(account|profile)$/i,'регистрация','inscription','regístrate','cadastre-se','registrieren','registrazione','注册','साइन अप करें'];window.SEARCH_TITLES='search find поиск найти искать recherche suchen buscar suche ricerca procurar 検索'.split(' ');window.FORGOT_PASSWORD_TITLES='forgot geändert vergessen hilfe changeemail español'.split(' ');window.REMEMBER_ME_TITLES=['remember me','rememberme','keep me signed in'];\
window.BACK_TITLES=['back','назад'];window.DIVITIS_BUTTON_CLASSES=['button','btn-primary'];window.stringResembles=function(a,b,c){var e;if(!a||''==a)return!1;e=a.toLowerCase().replace(/\\s{2,}/g,' ').replace(/(?:^\\W+|\\W+$)/g,'');b=b.some(function(b){return'function'===typeof b.test?b.test(a)||b.test(e):0<=e.indexOf(b)});var d=!1;c&&(d=c.some(function(b){return'function'===typeof b.test?b.test(a)||b.test(e):0<=e.indexOf(b)}));return b&&!d};function p(a){return a.textContent||a.innerText}\
function n(a){var b=null;a&&(b=a.replace(/^\\s+|\\s+$|\\r?\\n.*$/mg,'').replace(/\\s{2,}/,' '),b=0<b.length?b:null);return b}function z(a,b){var c='';3===b.nodeType?c=b.nodeValue:1===b.nodeType&&(c=p(b));(b=n(c))&&a.push(b)}function y(a){var b;a&&void 0!==a?(b='select option input form textarea button table iframe body head script'.split(' '),a?(a=a?(a.tagName||'').toLowerCase():'',b=b.constructor==Array?0<=b.indexOf(a):a===b):b=!1):b=!0;return b}\
function A(a,b,c){var e;for(c||(c=0);a&&a.previousSibling;){a=a.previousSibling;if(y(a))return;z(b,a)}if(a&&0===b.length){for(e=null;!e;){a=a.parentElement||a.parentNode;if(!a)return;for(e=a.previousSibling;e&&!y(e)&&e.lastChild;)e=e.lastChild}y(e)||(z(b,e),0===b.length&&A(e,b,c+1))}}\
function v(a){for(var b=a,c=(a=a.ownerDocument)?a.defaultView:{},e;b&&b!==a;){e=c.getComputedStyle&&b instanceof Element?c.getComputedStyle(b,null):b.style;if(!e)return!0;if('none'===e.display||'hidden'==e.visibility)return!1;b=b.parentNode}return b===a}\
function x(a){var b=a.ownerDocument.documentElement,c=a.getBoundingClientRect(),e=b.scrollWidth,d=b.scrollHeight,g=c.left-b.clientLeft,b=c.top-b.clientTop,l;if(!v(a)||!a.offsetParent||10>a.clientWidth||10>a.clientHeight)return!1;var q=a.getClientRects();if(0===q.length)return!1;for(var r=0;r<q.length;r++)if(l=q[r],l.left>e||0>l.right)return!1;if(0>g||g>e||0>b||b>d)return!1;for(c=a.ownerDocument.elementFromPoint(g+(c.right>window.innerWidth?(window.innerWidth-g)/2:c.width/2),b+(c.bottom>window.innerHeight?\
(window.innerHeight-b)/2:c.height/2));c&&c!==a&&c!==document;){if(c.tagName&&'string'===typeof c.tagName&&'label'===c.tagName.toLowerCase()&&a.labels&&0<a.labels.length)return 0<=Array.prototype.slice.call(a.labels).indexOf(c);c=c.parentNode}return c===a}function J(a){return U&&v(a)?-1!=='email text password number tel url'.split(' ').indexOf(a.type||''):!1}function u(a){return Array.prototype.slice.call(O(a,'input, select, button'))}\
function L(a){var b;if(void 0===a||null===a)return null;if(b=FieldCollector.c(a))return b;try{var c=u(document),e=c.filter(function(b){return b.opid==a});if(0<e.length)b=e[0],1<e.length&&console.warn('More than one element found with opid '+a);else{var d=parseInt(a.split('__')[1],10);isNaN(d)||(b=c[d])}}catch(g){console.error('An unexpected error occurred: '+g)}finally{return b}};function O(a,b){var c=[];try{c=a.querySelectorAll(b)}catch(e){console.error('[COMMON] Exception processing selector \"'+b+'\"')}return c}function t(a,b){if(!a)return!1;var c;b&&(c=a.value);'function'===typeof a.click&&a.click();'function'===typeof a.focus&&a.focus();b&&a.value!==c&&(a.value=c);return'function'===typeof a.click||'function'===typeof a.focus};var H=!0,U=!0,F=!0;function W(a){return a?0===a.indexOf('https://')&&'http:'===document.location.protocol&&(a=document.querySelectorAll('input[type=password]'),0<a.length&&(confirmResult=confirm('1Password warning: This is an unsecured HTTP page, and any information you submit can potentially be seen and changed by others. This Login was originally saved on a secure (HTTPS) page.\\n\\nDo you still wish to fill this login?'),0==confirmResult))?!0:!1:!1}\
function V(a){var b,c=[],e=a.properties,d=1,g=[];e&&e.delay_between_operations&&(d=e.delay_between_operations);if(!W(a.savedURL)){var l=function(a,b){var c=a[0];if(void 0===c)b();else{if('delay'===c.operation||'delay'===c[0])d=c.parameters?c.parameters[0]:c[1];else if(c=X(c))for(var e=0;e<c.length;e++)-1===g.indexOf(c[e])&&g.push(c[e]);setTimeout(function(){l(a.slice(1),b)},d)}};H=F=!0;if(b=a.options)b.hasOwnProperty('animate')&&(U=b.animate),b.hasOwnProperty('markFilling')&&(H=b.markFilling);if((b=\
a.metadata)&&b.hasOwnProperty('action'))switch(b.action){case 'fillPassword':H=!1;break;case 'fillLogin':F=!1}a.hasOwnProperty('script')&&l(a.script,function(){a.hasOwnProperty('autosubmit')&&'function'==typeof autosubmit&&(a.itemType&&'fillLogin'!==a.itemType||0<g.length&&setTimeout(function(){autosubmit(a.autosubmit,e.allow_clicky_autosubmit,g)},AUTOSUBMIT_DELAY));c=g.map(function(a){return a&&a.hasOwnProperty('opid')?a.opid:null});'object'==typeof protectedGlobalPage&&protectedGlobalPage.i('fillItemResults',\
{documentUUID:documentUUID,fillContextIdentifier:a.fillContextIdentifier,usedOpids:c},function(){fillingItemType=null})})}}var Z={fill_by_opid:Y,fill_by_query:aa,click_on_opid:ba,click_on_query:ca,touch_all_fields:da,simple_set_value_by_query:ea,focus_by_opid:fa,delay:null};\
function X(a){var b;if(a.hasOwnProperty('operation')&&a.hasOwnProperty('parameters'))b=a.operation,a=a.parameters;else if('[object Array]'===Object.prototype.toString.call(a))b=a[0],a=a.splice(1);else return null;return Z.hasOwnProperty(b)?Z[b].apply(this,a):null}function Y(a,b){return(a=L(a))?(E(a,b),[a]):null}function aa(a,b){a=O(document,a);return Array.prototype.map.call(Array.prototype.slice.call(a),function(a){E(a,b);return a},this)}\
function ea(a,b){var c=[];a=O(document,a);Array.prototype.forEach.call(Array.prototype.slice.call(a),function(a){a.disabled||a.f||a.readOnly||void 0===a.value||(a.value=b,c.push(a))});return c}function fa(a){(a=L(a))&&t(a,!0);return null}function ba(a){return(a=L(a))?t(a,!1)?[a]:null:null}function ca(a){a=O(document,a);return Array.prototype.map.call(Array.prototype.slice.call(a),function(a){t(a,!0);return[a]},this)}function da(){P()};window.addEventListener('$SECURITY_TOKEN',function(a){switch(a.detail.name){case 'executeFillScript':V(a.detail.payload);window.webkit.messageHandlers.$SECURITY_TOKEN.postMessage({name:'fillItemResults',payload:{j:!0}});break;case 'collectDocuments':window.webkit.messageHandlers.$SECURITY_TOKEN.postMessage({name:'collectFieldsResult',payload:FieldCollector.b(document,'oneshotUUID')})}},!1);\
	\
})(document);\
\
";

@end
