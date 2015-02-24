//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"

// Version
#define VERSION_NUMBER @(112)
static NSString *const AppExtensionVersionNumberKey = @"version_number";

// Available App Extension Actions
static NSString *const kUTTypeAppExtensionFindLoginAction = @"org.appextension.find-login-action";
static NSString *const kUTTypeAppExtensionSaveLoginAction = @"org.appextension.save-login-action";
static NSString *const kUTTypeAppExtensionChangePasswordAction = @"org.appextension.change-password-action";
static NSString *const kUTTypeAppExtensionFillWebViewAction = @"org.appextension.fill-webview-action";

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

- (BOOL)isSystemAppExtensionAPIAvailable {
#ifdef __IPHONE_8_0
	return NSClassFromString(@"NSExtensionItem") != nil;
#else
	return NO;
#endif
}

- (BOOL)isAppExtensionAvailable {
	if ([self isSystemAppExtensionAPIAvailable]) {
		return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"org-appextension-feature-password-management://"]];
    }

	return NO;
}

- (void)findLoginForURLString:(NSString *)URLString forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *loginDictionary, NSError *error))completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (![self isSystemAppExtensionAPIAvailable]) {
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

		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
			if (completion) {
				completion(loginDictionary, error);
			}
		}];
	};
	
	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

- (void)storeLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *, NSError *))completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(loginDetailsDict != nil, @"loginDetailsDict must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (![self isSystemAppExtensionAPIAvailable]) {
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
	[newLoginAttributesDict addEntriesFromDictionary:loginDetailsDict];
	if (passwordGenerationOptions.count > 0) {
		newLoginAttributesDict[AppExtensionPasswordGereratorOptionsKey] = passwordGenerationOptions;
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
		
		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
			if (completion) {
				completion(loginDictionary, error);
			}
		}];
	};
	
	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

- (void)changePasswordForLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *loginDict, NSError *error))completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (![self isSystemAppExtensionAPIAvailable]) {
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
	[item addEntriesFromDictionary:loginDetailsDict];
	if (passwordGenerationOptions.count > 0) {
		item[AppExtensionPasswordGereratorOptionsKey] = passwordGenerationOptions;
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

		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
			if (completion) {
				completion(loginDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

- (void)fillLoginIntoWebView:(id)webView forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(BOOL success, NSError *error))completion {
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

#ifdef __IPHONE_8_0
	if ([webView isKindOfClass:[UIWebView class]]) {
		[self fillLoginIntoUIWebView:webView webViewController:viewController sender:(id)sender completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
	else if ([webView isKindOfClass:[WKWebView class]]) {
		[self fillLoginIntoWKWebView:webView forViewController:viewController sender:(id)sender completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
#endif
	else {
		[NSException raise:@"Invalid argument: web view must be an instance of WKWebView or UIWebView." format:@""];
	}
#endif
}

#pragma mark - Helpers

- (UIActivityViewController *)activityViewControllerForItem:(NSDictionary *)item viewController:(UIViewController*)viewController sender:(id)sender typeIdentifier:(NSString *)typeIdentifier {
#ifdef __IPHONE_8_0
    
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


#pragma mark - Errors

+ (NSError *)systemAppExtensionAPINotAvailableError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"App Extension API is not available is this version of iOS", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeAPINotAvailable userInfo:userInfo];
}


+ (NSError *)extensionCancelledByUserError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"1Password Extension was cancelled by the user", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCancelledByUser userInfo:userInfo];
}

+ (NSError *)failedToContactExtensionErrorWithActivityError:(NSError *)activityError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Failed to contact the 1Password Extension", @"1Password Extension Error Message");
	if (activityError) {
		userInfo[NSUnderlyingErrorKey] = activityError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToContactExtension userInfo:userInfo];
}

+ (NSError *)failedToCollectFieldsErrorWithUnderlyingError:(NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Failed to execute script that collects web page information", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCollectFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToFillFieldsErrorWithLocalizedErrorMessage:(NSString *)errorMessage underlyingError:(NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (errorMessage) {
		userInfo[NSLocalizedDescriptionKey] = errorMessage;
	}
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFillFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToLoadItemProviderDataErrorWithUnderlyingError:(NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Failed to parse information returned by 1Password Extension", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToLoadItemProviderData userInfo:userInfo];
}

+ (NSError *)failedToObtainURLStringFromWebViewError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to obtain URL String from web view. The web view must be loaded completely when calling the 1Password Extension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToObtainURLStringFromWebView userInfo:userInfo];
}


#pragma mark - App Extension ItemProvider Callback

#ifdef __IPHONE_8_0
- (void)processExtensionItem:(NSExtensionItem *)extensionItem completion:(void (^)(NSDictionary *loginDictionary, NSError *error))completion {
	if (extensionItem.attachments.count == 0) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item had no attachments." };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}
	
	NSItemProvider *itemProvider = extensionItem.attachments[0];
	if (![itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item attachment does not conform to kUTTypePropertyList type identifier" };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}


	[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *loginDictionary, NSError *itemProviderError)
	{
		NSError *error = nil;
		if (!loginDictionary) {
			NSLog(@"Failed to loadItemForTypeIdentifier: %@", itemProviderError);
			error = [OnePasswordExtension failedToLoadItemProviderDataErrorWithUnderlyingError:itemProviderError];
		}

		if (completion) {
			if ([NSThread isMainThread]) {
				completion(loginDictionary, error);
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(loginDictionary, error);
				});
			}
		}
	}];
}


#pragma mark - Web view integration

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
- (void)fillLoginIntoWKWebView:(WKWebView *)webView forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(BOOL success, NSError *error))completion {
	[webView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *error) {
		if (!result) {
			NSLog(@"1Password Extension failed to collect web page fields: %@", error);
			if (completion) {
				completion(NO,[OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:error]);
			}

			return;
		}
		
		[self findLoginIn1PasswordWithURLString:webView.URL.absoluteString collectedPageDetails:result forWebViewController:viewController sender:sender withWebView:webView completion:^(BOOL success, NSError *findLoginError) {
			if (completion) {
				completion(success, findLoginError);
			}
		}];
	}];
}
#endif

- (void)fillLoginIntoUIWebView:(UIWebView *)webView webViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(BOOL success, NSError *error))completion {
	NSString *collectedPageDetails = [webView stringByEvaluatingJavaScriptFromString:OPWebViewCollectFieldsScript];
	[self findLoginIn1PasswordWithURLString:webView.request.URL.absoluteString collectedPageDetails:collectedPageDetails forWebViewController:viewController sender:sender withWebView:webView completion:^(BOOL success, NSError *error) {
		if (completion) {
			completion(success, error);
		}
	}];
}

- (void)findLoginIn1PasswordWithURLString:(NSString *)URLString collectedPageDetails:(NSString *)collectedPageDetails forWebViewController:(UIViewController *)forViewController sender:(id)sender withWebView:(id)webView completion:(void (^)(BOOL success, NSError *error))completion {
	if ([URLString length] == 0) {
		NSError *URLStringError = [OnePasswordExtension failedToObtainURLStringFromWebViewError];
		NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", URLStringError);
		completion(NO, URLStringError);
	}

	NSError *jsonError = nil;
	NSData *data = [collectedPageDetails dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *collectedPageDetailsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

	if (collectedPageDetailsDictionary.count == 0) {
		NSLog(@"Failed to parse JSON collected page details: %@", jsonError);
		completion(NO, jsonError);
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : collectedPageDetailsDictionary };

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:forViewController sender:sender typeIdentifier:kUTTypeAppExtensionFillWebViewAction];
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

		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *processExtensionItemError) {
			if (!loginDictionary) {
				if (completion) {
					completion(NO, processExtensionItemError);
				}

				return;
			}
			
			NSString *fillScript = loginDictionary[AppExtensionWebViewPageFillScript];
			[self executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
				if (completion) {
					completion(success, executeFillScriptError);
				}
			}];
		}];
	};
	
	[forViewController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)executeFillScript:(NSString *)fillScript inWebView:(id)webView completion:(void (^)(BOOL success, NSError *error))completion {
	if (!fillScript) {
		NSLog(@"Failed to executeFillScript, fillScript is missing");
		if (completion) {
			completion(NO, [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedString(@"Failed to fill web page because script is missing", @"1Password Extension Error Message") underlyingError:nil]);
		}

		return;
	}
	
	NSMutableString *scriptSource = [OPWebViewFillScript mutableCopy];
	[scriptSource appendFormat:@"(document, %@);", fillScript];
	
	if ([webView isKindOfClass:[UIWebView class]]) {
		NSString *result = [((UIWebView *)webView) stringByEvaluatingJavaScriptFromString:scriptSource];
		BOOL success = (result != nil);
		NSError *error = nil;

		if (!success) {
			NSLog(@"Cannot executeFillScript, stringByEvaluatingJavaScriptFromString failed");
			error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedString(@"Failed to fill web page because script could not be evaluated", @"1Password Extension Error Message") underlyingError:nil];
		}

		if (completion) {
			completion(success, error);
		}

		return;
	}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
	if ([webView isKindOfClass:[WKWebView class]]) {
		[((WKWebView *)webView) evaluateJavaScript:scriptSource completionHandler:^(NSString *result, NSError *evaluationError) {
			BOOL success = (result != nil);
			NSError *error = nil;

			if (!success) {
				NSLog(@"Cannot executeFillScript, evaluateJavaScript failed: %@", evaluationError);
				error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedString(@"Failed to fill web page because script could not be evaluated", @"1Password Extension Error Message") underlyingError:error];
			}

			if (completion) {
				completion(success, error);
			}
		}];

		return;
	}
#endif

	[NSException raise:@"Invalid argument: web view must be an instance of WKWebView or UIWebView." format:@""];
}
#endif


#pragma mark - WebView field collection and filling scripts

static NSString *const OPWebViewCollectFieldsScript = @"document.collect=n;document.elementsByOPID={};\
function n(d,b){function e(a,f){var c=a[f];if('string'==typeof c)return c;c=a.getAttribute(f);return'string'==typeof c?c:null}function h(a){switch(l(a.type)){case 'checkbox':return a.checked?'✓':'';case 'hidden':a=a.value;if(!a||'number'!=typeof a.length)return'';254<a.length&&(a=a.substr(0,254)+'...SNIPPED');return a;default:return a.value}}function q(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){var c=a.text,c=c?l(c).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,\
''):null;return[c?c:null,a.value]}),{options:a}):null}function s(a){var f;for(a=a.parentElement||a.parentNode;a&&'td'!=l(a.tagName);)a=a.parentElement||a.parentNode;if(!a||void 0===a)return null;f=a.parentElement||a.parentNode;if('tr'!=f.tagName.toLowerCase())return null;f=f.previousElementSibling;if(!f||'tr'!=(f.tagName+'').toLowerCase()||f.cells&&a.cellIndex>=f.cells.length)return null;a=p(f.cells[a.cellIndex]);return a=r(a)}function x(a){var f=d.documentElement,c=a.getBoundingClientRect(),b=f.getBoundingClientRect(),\
e=c.left-f.clientLeft,f=c.top-f.clientTop;return a.offsetParent?0>e||e>b.width||0>f||f>b.height?t(a):(b=a.ownerDocument.elementFromPoint(e+3,f+3))?'label'===l(b.tagName)?b===y(a):b.tagName===a.tagName:!1:!1}function t(a){for(var f;a!==d&&a;a=a.parentNode)if(f=u.getComputedStyle?u.getComputedStyle(a,null):a.style,'none'===f.display||'hidden'==f.visibility)return!1;return a===d}function y(a){function f(a){return String.prototype.replace.call(a,\"'\",\"\\\\'\")}var c;if(f(a.id)&&(c=d.querySelector(\"label[for='\"+\
f(a.id)+\"']\"))||f(a.name)&&(c=d.querySelector(\"label[for='\"+f(a.name)+\"']\")))return p(c);for(;a&&a!=d;a=a.parentNode)if('label'===l(a.tagName))return p(a);return null}function g(a,f,c,d){void 0!==d&&d===c||null===c||void 0===c||(a[f]=c)}function l(a){return'string'===typeof a?a.toLowerCase():(''+a).toLowerCase()}var u=d.defaultView?d.defaultView:window,m=RegExp('(pin|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i'),D=Array.prototype.slice.call(d.querySelectorAll('form')).map(function(a,\
d){var c={},b='__form__'+d;a.opid=b;c.opid=b;g(c,'htmlName',e(a,'name'));g(c,'htmlID',e(a,'id'));g(c,'htmlAction',v(e(a,'action')));g(c,'htmlMethod',e(a,'method'));return c}),A=Array.prototype.slice.call(d.querySelectorAll('input, select')).map(function(a,f){var c={},b='__'+f,k=-1==a.maxLength?999:a.maxLength;d.elementsByOPID[b]=a;a.opid=b;c.opid=b;c.elementNumber=f;g(c,'maxLength',Math.min(k,999),999);c.visible=t(a);c.viewable=x(a);g(c,'htmlID',e(a,'id'));g(c,'htmlName',e(a,'name'));g(c,'htmlClass',\
e(a,'class'));if('hidden'!=l(a.type)){g(c,'label-tag',y(a));g(c,'label-data',e(a,'data-label'));g(c,'label-aria',e(a,'aria-label'));g(c,'label-top',s(a));b=[];for(k=a;k&&k.nextSibling;){k=k.nextSibling;if(w(k))break;z(b,k)}g(c,'label-right',b.join(''));b=[];B(a,b);b=b.reverse().join('');g(c,'label-left',b);g(c,'placeholder',e(a,'placeholder'))}g(c,'rel',e(a,'rel'));g(c,'type',l(e(a,'type')));g(c,'value',h(a));g(c,'checked',a.checked,!1);g(c,'autoCompleteType',a.getAttribute('x-autocompletetype')||\
a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'),'off');g(c,'selectInfo',q(a));g(c,'aria-hidden','true'==a.getAttribute('aria-hidden'),!1);g(c,'aria-disabled','true'==a.getAttribute('aria-disabled'),!1);g(c,'aria-haspopup','true'==a.getAttribute('aria-haspopup'),!1);g(c,'data-stripe',e(a,'data-stripe'));a.form&&(c.form=e(a.form,'opid'));b=(m.test(c.value)||m.test(c.htmlID)||m.test(c.htmlName)||m.test(c.placeholder)||m.test(c['label-tag'])||m.test(c['label-data'])||m.test(c['label-aria']))&&\
('text'==c.type||'password'==c.type&&!c.visible);g(c,'fakeTested',b,!1);return c});A.filter(function(a){return a.fakeTested}).forEach(function(a){var b=d.elementsByOPID[a.opid];b.getBoundingClientRect();!b||b&&'function'!==typeof b.click||b.click();b.focus();C(b,'keydown');C(b,'keyup');C(b,'keypress');b.click&&b.click();a.postFakeTestVisible=t(b);a.postFakeTestViewable=x(b);a=b.ownerDocument.createEvent('HTMLEvents');var c=b.ownerDocument.createEvent('HTMLEvents');C(b,'keydown');C(b,'keyup');C(b,\
'keypress');c.initEvent('input',!0,!0);b.dispatchEvent(c);a.initEvent('change',!0,!0);b.dispatchEvent(a);b.blur()});return{documentUUID:b,title:d.title,url:u.location.href,forms:function(a){var b={};a.forEach(function(a){b[a.opid]=a});return b}(D),fields:A,collectedTimestamp:(new Date).getTime()}};document.elementForOPID=E;function C(d,b){var e;e=d.ownerDocument.createEvent('KeyboardEvent');e.initKeyboardEvent?e.initKeyboardEvent(b,!0,!0):e.initKeyEvent&&e.initKeyEvent(b,!0,!0,null,!1,!1,!1,!1,0,0);d.dispatchEvent(e)}function p(d){return d.textContent||d.innerText}function r(d){var b=null;d&&(b=d.replace(/^\\s+|\\s+$|\\r?\\n.*$/mg,''),b=0<b.length?b:null);return b}function z(d,b){var e;e='';3===b.nodeType?e=b.nodeValue:1===b.nodeType&&(e=p(b));(e=r(e))&&d.push(e)}\
function w(d){var b;d&&void 0!==d?(b='select option input form textarea button table iframe body head script'.split(' '),d?(d=d?(d.tagName||'').toLowerCase():'',b=b.constructor==Array?0<=b.indexOf(d):d===b):b=!1):b=!0;return b}\
function B(d,b,e){var h;for(e||(e=0);d&&d.previousSibling;){d=d.previousSibling;if(w(d))return;z(b,d)}if(d&&0===b.length){for(h=null;!h;){d=d.parentElement||d.parentNode;if(!d)return;for(h=d.previousSibling;h&&!w(h)&&h.lastChild;)h=h.lastChild}w(h)||(z(b,h),0===b.length&&B(h,b,e+1))}}\
function E(d){var b;if(void 0===d||null===d)return null;try{var e=Array.prototype.slice.call(document.querySelectorAll('input, select')),h=e.filter(function(b){return b.opid==d});if(0<h.length)b=h[0],1<h.length&&console.warn('More than one element found with opid '+d);else{var q=parseInt(d.split('__')[1],10);isNaN(q)||(b=e[q])}}catch(s){console.error('An unexpected error occurred: '+s)}finally{return b}};var F=/^[\\/\\?]/;function v(d){if(!d)return null;if(0==d.indexOf('http'))return d;var b=window.location.protocol+'//'+window.location.hostname;window.location.port&&''!=window.location.port&&(b+=':'+window.location.port);d.match(F)||(d='/'+d);return b+d};\
(function collect(uuid) { var pageDetails = document.collect(document, uuid); return JSON.stringify(pageDetails); })('uuid');";

static NSString *const OPWebViewFillScript = @"document.collect=n;document.elementsByOPID={};\
function n(d,b){function e(a,f){var c=a[f];if('string'==typeof c)return c;c=a.getAttribute(f);return'string'==typeof c?c:null}function h(a){switch(l(a.type)){case 'checkbox':return a.checked?'✓':'';case 'hidden':a=a.value;if(!a||'number'!=typeof a.length)return'';254<a.length&&(a=a.substr(0,254)+'...SNIPPED');return a;default:return a.value}}function q(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){var c=a.text,c=c?l(c).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,\
''):null;return[c?c:null,a.value]}),{options:a}):null}function s(a){var f;for(a=a.parentElement||a.parentNode;a&&'td'!=l(a.tagName);)a=a.parentElement||a.parentNode;if(!a||void 0===a)return null;f=a.parentElement||a.parentNode;if('tr'!=f.tagName.toLowerCase())return null;f=f.previousElementSibling;if(!f||'tr'!=(f.tagName+'').toLowerCase()||f.cells&&a.cellIndex>=f.cells.length)return null;a=p(f.cells[a.cellIndex]);return a=r(a)}function x(a){var f=d.documentElement,c=a.getBoundingClientRect(),b=f.getBoundingClientRect(),\
e=c.left-f.clientLeft,f=c.top-f.clientTop;return a.offsetParent?0>e||e>b.width||0>f||f>b.height?t(a):(b=a.ownerDocument.elementFromPoint(e+3,f+3))?'label'===l(b.tagName)?b===y(a):b.tagName===a.tagName:!1:!1}function t(a){for(var f;a!==d&&a;a=a.parentNode)if(f=u.getComputedStyle?u.getComputedStyle(a,null):a.style,'none'===f.display||'hidden'==f.visibility)return!1;return a===d}function y(a){function f(a){return String.prototype.replace.call(a,\"'\",\"\\\\'\")}var c;if(f(a.id)&&(c=d.querySelector(\"label[for='\"+\
f(a.id)+\"']\"))||f(a.name)&&(c=d.querySelector(\"label[for='\"+f(a.name)+\"']\")))return p(c);for(;a&&a!=d;a=a.parentNode)if('label'===l(a.tagName))return p(a);return null}function g(a,f,c,d){void 0!==d&&d===c||null===c||void 0===c||(a[f]=c)}function l(a){return'string'===typeof a?a.toLowerCase():(''+a).toLowerCase()}var u=d.defaultView?d.defaultView:window,m=RegExp('(pin|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i'),D=Array.prototype.slice.call(d.querySelectorAll('form')).map(function(a,\
d){var c={},b='__form__'+d;a.opid=b;c.opid=b;g(c,'htmlName',e(a,'name'));g(c,'htmlID',e(a,'id'));g(c,'htmlAction',v(e(a,'action')));g(c,'htmlMethod',e(a,'method'));return c}),A=Array.prototype.slice.call(d.querySelectorAll('input, select')).map(function(a,f){var c={},b='__'+f,k=-1==a.maxLength?999:a.maxLength;d.elementsByOPID[b]=a;a.opid=b;c.opid=b;c.elementNumber=f;g(c,'maxLength',Math.min(k,999),999);c.visible=t(a);c.viewable=x(a);g(c,'htmlID',e(a,'id'));g(c,'htmlName',e(a,'name'));g(c,'htmlClass',\
e(a,'class'));if('hidden'!=l(a.type)){g(c,'label-tag',y(a));g(c,'label-data',e(a,'data-label'));g(c,'label-aria',e(a,'aria-label'));g(c,'label-top',s(a));b=[];for(k=a;k&&k.nextSibling;){k=k.nextSibling;if(w(k))break;z(b,k)}g(c,'label-right',b.join(''));b=[];B(a,b);b=b.reverse().join('');g(c,'label-left',b);g(c,'placeholder',e(a,'placeholder'))}g(c,'rel',e(a,'rel'));g(c,'type',l(e(a,'type')));g(c,'value',h(a));g(c,'checked',a.checked,!1);g(c,'autoCompleteType',a.getAttribute('x-autocompletetype')||\
a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'),'off');g(c,'selectInfo',q(a));g(c,'aria-hidden','true'==a.getAttribute('aria-hidden'),!1);g(c,'aria-disabled','true'==a.getAttribute('aria-disabled'),!1);g(c,'aria-haspopup','true'==a.getAttribute('aria-haspopup'),!1);g(c,'data-stripe',e(a,'data-stripe'));a.form&&(c.form=e(a.form,'opid'));b=(m.test(c.value)||m.test(c.htmlID)||m.test(c.htmlName)||m.test(c.placeholder)||m.test(c['label-tag'])||m.test(c['label-data'])||m.test(c['label-aria']))&&\
('text'==c.type||'password'==c.type&&!c.visible);g(c,'fakeTested',b,!1);return c});A.filter(function(a){return a.fakeTested}).forEach(function(a){var b=d.elementsByOPID[a.opid];b.getBoundingClientRect();!b||b&&'function'!==typeof b.click||b.click();b.focus();C(b,'keydown');C(b,'keyup');C(b,'keypress');b.click&&b.click();a.postFakeTestVisible=t(b);a.postFakeTestViewable=x(b);a=b.ownerDocument.createEvent('HTMLEvents');var c=b.ownerDocument.createEvent('HTMLEvents');C(b,'keydown');C(b,'keyup');C(b,\
'keypress');c.initEvent('input',!0,!0);b.dispatchEvent(c);a.initEvent('change',!0,!0);b.dispatchEvent(a);b.blur()});return{documentUUID:b,title:d.title,url:u.location.href,forms:function(a){var b={};a.forEach(function(a){b[a.opid]=a});return b}(D),fields:A,collectedTimestamp:(new Date).getTime()}};document.elementForOPID=E;function C(d,b){var e;e=d.ownerDocument.createEvent('KeyboardEvent');e.initKeyboardEvent?e.initKeyboardEvent(b,!0,!0):e.initKeyEvent&&e.initKeyEvent(b,!0,!0,null,!1,!1,!1,!1,0,0);d.dispatchEvent(e)}function p(d){return d.textContent||d.innerText}function r(d){var b=null;d&&(b=d.replace(/^\\s+|\\s+$|\\r?\\n.*$/mg,''),b=0<b.length?b:null);return b}function z(d,b){var e;e='';3===b.nodeType?e=b.nodeValue:1===b.nodeType&&(e=p(b));(e=r(e))&&d.push(e)}\
function w(d){var b;d&&void 0!==d?(b='select option input form textarea button table iframe body head script'.split(' '),d?(d=d?(d.tagName||'').toLowerCase():'',b=b.constructor==Array?0<=b.indexOf(d):d===b):b=!1):b=!0;return b}\
function B(d,b,e){var h;for(e||(e=0);d&&d.previousSibling;){d=d.previousSibling;if(w(d))return;z(b,d)}if(d&&0===b.length){for(h=null;!h;){d=d.parentElement||d.parentNode;if(!d)return;for(h=d.previousSibling;h&&!w(h)&&h.lastChild;)h=h.lastChild}w(h)||(z(b,h),0===b.length&&B(h,b,e+1))}}\
function E(d){var b;if(void 0===d||null===d)return null;try{var e=Array.prototype.slice.call(document.querySelectorAll('input, select')),h=e.filter(function(b){return b.opid==d});if(0<h.length)b=h[0],1<h.length&&console.warn('More than one element found with opid '+d);else{var q=parseInt(d.split('__')[1],10);isNaN(q)||(b=e[q])}}catch(s){console.error('An unexpected error occurred: '+s)}finally{return b}};var F=/^[\\/\\?]/;function v(d){if(!d)return null;if(0==d.indexOf('http'))return d;var b=window.location.protocol+'//'+window.location.hostname;window.location.port&&''!=window.location.port&&(b+=':'+window.location.port);d.match(F)||(d='/'+d);return b+d};\
(function(ownerDocument, script){ownerDocument.fill(script); return {'success': true}; })";

@end
