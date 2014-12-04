//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"

// Version
#define VERSION_NUMBER @(110)
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

	__weak __typeof__ (self) miniMe = self;

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

		__strong __typeof__(self) strongMe = miniMe;
		[strongMe processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
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

	__weak __typeof__ (self) miniMe = self;

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
		
		__strong __typeof__(self) strongMe = miniMe;
		[strongMe processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
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

	__weak __typeof__ (self) miniMe = self;
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

		__strong __typeof__(self) strongMe = miniMe;
		[strongMe processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
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
	__weak __typeof__ (self) miniMe = self;
	[webView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *error) {
		if (!result) {
			NSLog(@"1Password Extension failed to collect web page fields: %@", error);
			if (completion) {
				completion(NO,[OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:error]);
			}

			return;
		}
		
		__strong __typeof__(self) strongMe = miniMe;
		[strongMe findLoginIn1PasswordWithURLString:webView.URL.absoluteString collectedPageDetails:result forWebViewController:viewController sender:sender withWebView:webView completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
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

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : collectedPageDetails };

	__weak __typeof__ (self) miniMe = self;

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

		__strong __typeof__(self) strongMe = miniMe;
		[strongMe processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *processExtensionItemError) {
			if (!loginDictionary) {
				if (completion) {
					completion(NO, processExtensionItemError);
				}

				return;
			}
			
			__strong __typeof__(self) strongMe2 = miniMe;
			NSString *fillScript = loginDictionary[AppExtensionWebViewPageFillScript];
			[strongMe2 executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
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
	[scriptSource appendFormat:@"(document, '%@');", fillScript];
	
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

static NSString *const OPWebViewCollectFieldsScript = @"document.collect=p;document.elementsByOPID={};\
function p(d,b){function f(a){var c,e;if(!a)return'';if(a._idCache)return a._idCache;if('BODY'==a.tagName)return a.tagName;e=a.parentNode.childNodes;for(c=0;c<=e.length;c++)if(e[c]==a)return c=f(a.parentNode)+'/'+a.tagName+'['+c+']',a._idCache=c;return''}function g(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){return[k(a.text),a.value]}),{options:a}):null}function q(a){var c;for(a=a.parentElement||a.parentNode;a&&'td'!=m(a.tagName);)a=a.parentElement||a.parentNode;if(!a||\
void 0===a)return null;c=a.parentElement||a.parentNode;if('tr'!=c.tagName.toLowerCase())return null;c=c.previousElementSibling;if(!c||'tr'!=(c.tagName+'').toLowerCase()||c.cells&&a.cellIndex>=c.cells.length)return null;a=c.cells[a.cellIndex];return k(a.innerText||a.textContent)}function r(a){var c=d.documentElement,e=a.getBoundingClientRect(),b=c.getBoundingClientRect(),f=e.left-c.clientLeft,c=e.top-c.clientTop;return a.offsetParent?0>f||f>b.width||0>c||c>b.height?t(a):(b=a.ownerDocument.elementFromPoint(f+\
3,c+3))?'label'===m(b.tagName)?b===w(a):b.tagName===a.tagName:!1:!1}function t(a){for(var c;a!==d&&a;a=a.parentNode)if(c=u.getComputedStyle?u.getComputedStyle(a,null):a.style,'none'===c.display||'hidden'==c.visibility)return!1;return a===d}function w(a){var c=d.querySelector(\"label[for='\"+String.prototype.replace.call(a.id,\"'\",\"\\\\'\")+\"']\")||d.querySelector(\"label[for='\"+String.prototype.replace.call(a.name,\"'\",\"\\\\'\")+\"']\");if(c)return c.innerText;for(;a&&a!=d;a=a.parentNode)if('label'===m(a.tagName))return a.innerText;\
return null}function k(a){return(a=a?m(a).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,''):null)?a:null}function h(a,c,e){null!==e&&void 0!==e&&(a[c]=e)}function m(a){return'string'===typeof a?a.toLowerCase():(''+a).toLowerCase()}var u=d.defaultView?d.defaultView:window,l=RegExp('(pin|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i'),B=Array.prototype.slice.call(d.querySelectorAll('form')).map(function(a,c){var e={},d='__form__'+c;a.opid=\
d;e.opid=d;h(e,'htmlName',a.name);h(e,'htmlID',a.id);h(e,'htmlAction',s(a.action));h(e,'htmlMethod',a.method);return e}),y=Array.prototype.slice.call(d.querySelectorAll('input, select')).map(function(a,c){var e={},b='__'+c;d.elementsByOPID[b]=a;a.opid=b;e.opid=b;e.elementNumber=c;e.maxLength=-1==a.maxLength?999:a.maxLength;e.visible=t(a);e.viewable=r(a);e.parentId=f(a.parentNode);h(e,'htmlID',a.id||a.getAttribute('id'));h(e,'htmlName',a.name);h(e,'htmlClass',a['class']||a.getAttribute('class'));h(e,\
'label-tag',k(w(a)));h(e,'label-data',k(a.getAttribute('data-label')));h(e,'label-aria',k(a.getAttribute('aria-label')));h(e,'label-top',q(a));for(var b=[],n=a;n&&n.nextSibling;){n=n.nextSibling;if(v(n))break;x(b,n)}b=k(b.join(''));h(e,'label-right',b);b=[];z(a,b);b=k(b.reverse().join(''));h(e,'label-left',b);h(e,'placeholder',k(a.placeholder));h(e,'rel',a.rel||a.getAttribute('rel'));h(e,'type',m(a.type||a.getAttribute('type')));a:switch(m(a.type)){case 'checkbox':b=a.checked?'✓':'';break a;default:b=\
a.value}h(e,'value',b);h(e,'checked',a.checked);h(e,'autoCompleteType',a.getAttribute('x-autocompletetype')||a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'));h(e,'selectInfo',g(a));a.form&&(e.form=a.form.opid);b=(l.test(e.value)||l.test(e.htmlID)||l.test(e.htmlName)||l.test(e.placeholder)||l.test(e['label-tag'])||l.test(e['label-data'])||l.test(e['label-aria']))&&('text'==e.type||'password'==e.type&&!e.visible);e.fakeTested=b;return e});y.filter(function(a){return a.fakeTested}).forEach(function(a){var c=\
d.elementsByOPID[a.opid];c.getBoundingClientRect();!c||c&&'function'!==typeof c.click||c.click();c.focus();A(c,'keydown');A(c,'keyup');A(c,'keypress');c.click&&c.click();a.postFakeTestVisible=t(c);a.postFakeTestViewable=r(c);a=c.ownerDocument.createEvent('HTMLEvents');var b=c.ownerDocument.createEvent('HTMLEvents');A(c,'keydown');A(c,'keyup');A(c,'keypress');b.initEvent('input',!0,!0);c.dispatchEvent(b);a.initEvent('change',!0,!0);c.dispatchEvent(a);c.blur()});return{documentUUID:b,url:u.location.href,\
forms:function(a){var c={};a.forEach(function(a){c[a.opid]=a});return c}(B),fields:y,collectedTimestamp:(new Date).getTime()}};document.elementForOPID=C;function A(d,b){var f;f=d.ownerDocument.createEvent('KeyboardEvent');f.initKeyboardEvent?f.initKeyboardEvent(b,!0,!0):f.initKeyEvent&&f.initKeyEvent(b,!0,!0,null,!1,!1,!1,!1,0,0);d.dispatchEvent(f)}function x(d,b){var f;f='';3===b.nodeType?f=b.nodeValue:1===b.nodeType&&(f=b.innerText||b.textContent);var g=null;f&&(g=f.toLowerCase().replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,''),g=0<g.length?g:null);(f=g)&&d.push(f)}\
function v(d){var b;d&&void 0!==d?(b='select option input form textarea iframe button'.split(' '),d?(d=d?(d.tagName||'').toLowerCase():'',b=b.constructor==Array?0<=b.indexOf(d):d===b):b=!1):b=!0;return b}function z(d,b,f){var g;for(f||(f=0);d&&d.previousSibling;){d=d.previousSibling;if(v(d))return;x(b,d)}if(d&&0===b.length){for(g=null;!g;){d=d.parentElement||d.parentNode;if(!d)return;for(g=d.previousSibling;g&&!v(g)&&g.lastChild;)g=g.lastChild}v(g)||(x(b,g),0===b.length&&z(g,b,f+1))}}\
function C(d){var b;try{var f=Array.prototype.slice.call(document.querySelectorAll('input, select')),g=f.filter(function(b){return b.opid==d});if(0<g.length)b=g[0],1<g.length&&console.warn('More than one element found with opid '+d);else{var q=parseInt(d.split('__')[1],10);isNaN(q)||(b=f[q])}}catch(r){console.error('An unexpected error occurred: '+r)}finally{return b}};var D=/^[\\/\\?]/;function s(d){if(!d)return null;if(0==d.indexOf('http'))return d;var b=window.location.protocol+'//'+window.location.hostname;window.location.port&&''!=window.location.port&&(b+=':'+window.location.port);d.match(D)||(d='/'+d);return b+d};\
(function collect(uuid) { var pageDetails = document.collect(document, uuid); return pageDetails; })('uuid');";

static NSString *const OPWebViewFillScript = @"var f=!0,h=!0;document.fill=k;\
function k(a){var b,c=[],d=a.properties,e=1,g;d&&d.delay_between_operations&&(e=d.delay_between_operations);if(null!=a.savedURL&&0===a.savedURL.indexOf('https://')&&'http:'==document.location.protocol&&(b=confirm('1Password warning: This is an unsecured HTTP page, and any information you submit can potentially be seen and changed by others. This Login was originally saved on a secure (HTTPS) page.\\n\\nDo you still wish to fill this login?'),0==b))return;g=function(a,b){var d=a[0];void 0===d?b():('delay'===\
d.operation?e=d.parameters[0]:c.push(l(d)),setTimeout(function(){g(a.slice(1),b)},e))};if(b=a.options)h=b.animate,f=b.markFilling;a.hasOwnProperty('script')&&(b=a.script,g(b,function(){c=Array.prototype.concat.apply(c,void 0);a.hasOwnProperty('autosubmit')&&'function'==typeof autosubmit&&setTimeout(function(){autosubmit(a.autosubmit,d.allow_clicky_autosubmit)},AUTOSUBMIT_DELAY);'object'==typeof protectedGlobalPage&&protectedGlobalPage.a('fillItemResults',{documentUUID:documentUUID,fillContextIdentifier:a.fillContextIdentifier,\
usedOpids:c},function(){})}))}var t={fill_by_opid:m,fill_by_query:n,click_on_opid:p,click_on_query:q,touch_all_fields:r,simple_set_value_by_query:s,delay:null};function l(a){var b;if(a.hasOwnProperty('operation')&&a.hasOwnProperty('parameters'))b=a.operation,a=a.parameters;else if('[object Array]'===Object.prototype.toString.call(a))b=a[0],a=a.splice(1);else return null;return t.hasOwnProperty(b)?t[b].apply(this,a):null}function m(a,b){var c;return(c=u(a))?(v(c,b),c.opid):null}\
function n(a,b){var c;c=document.querySelectorAll(a);return Array.prototype.map.call(c,function(a){v(a,b);return a.opid},this)}function s(a,b){var c,d=[];c=document.querySelectorAll(a);Array.prototype.forEach.call(c,function(a){void 0!==a.value&&(a.value=b,d.push(a.opid))});return d}function p(a){a=u(a);if(!a)return null;w(a);'function'===typeof a.click&&a.click();return a?a.opid:null}\
function q(a){a=document.querySelectorAll(a);return Array.prototype.map.call(a,function(a){w(a);'function'===typeof a.click&&a.click();'function'===typeof a.focus&&a.focus();return a.opid},this)}function r(){x()};var y={'true':!0,y:!0,1:!0,yes:!0,'✓':!0},z=200;function v(a,b){var c;if(a&&null!==b&&void 0!==b)switch(f&&a.form&&!a.form.opfilled&&(a.form.opfilled=!0),a.type?a.type.toLowerCase():null){case 'checkbox':c=b&&1<=b.length&&y.hasOwnProperty(b.toLowerCase())&&!0===y[b.toLowerCase()];a.checked===c||A(a,function(a){a.checked=c});break;case 'radio':!0===y[b.toLowerCase()]&&a.click();break;default:a.value==b||A(a,function(a){a.value=b})}}\
function A(a,b){B(a);b(a);C(a);D(a)&&(a.className+=' com-agilebits-onepassword-extension-animated-fill',setTimeout(function(){a&&a.className&&(a.className=a.className.replace(/(\\s)?com-agilebits-onepassword-extension-animated-fill/,''))},z))};document.elementForOPID=u;function E(a,b){var c;c=a.ownerDocument.createEvent('KeyboardEvent');c.initKeyboardEvent?c.initKeyboardEvent(b,!0,!0):c.initKeyEvent&&c.initKeyEvent(b,!0,!0,null,!1,!1,!1,!1,0,0);a.dispatchEvent(c)}function B(a){w(a);a.focus();E(a,'keydown');E(a,'keyup');E(a,'keypress')}\
function C(a){var b=a.ownerDocument.createEvent('HTMLEvents'),c=a.ownerDocument.createEvent('HTMLEvents');E(a,'keydown');E(a,'keyup');E(a,'keypress');c.initEvent('input',!0,!0);a.dispatchEvent(c);b.initEvent('change',!0,!0);a.dispatchEvent(b);a.blur()}function w(a){!a||a&&'function'!==typeof a.click||a.click()}\
function F(){var a=RegExp('(pin|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i');return Array.prototype.slice.call(document.querySelectorAll(\"input[type='text']\")).filter(function(b){return b.value&&a.test(b.value)},this)}function x(){F().forEach(function(a){B(a);a.click&&a.click();C(a)})}\
function D(a){var b;if(b=h)a:{b=a;for(var c=a.ownerDocument,c=c?c.defaultView:{},d;b&&b!==document;){d=c.getComputedStyle?c.getComputedStyle(b,null):b.style;if('none'===d.display||'hidden'==d.visibility){b=!1;break a}b=b.parentNode}b=b===document}return b?-1!=='email text password number tel url'.split(' ').indexOf(a.type||''):!1}\
function u(a){var b;try{var c=Array.prototype.slice.call(document.querySelectorAll('input, select')),d=c.filter(function(b){return b.opid==a});if(0<d.length)b=d[0],1<d.length&&console.warn('More than one element found with opid '+a);else{var e=parseInt(a.split('__')[1],10);isNaN(e)||(b=c[e])}}catch(g){console.error('An unexpected error occurred: '+g)}finally{return b}};\
(function(ownerDocument, script){ownerDocument.fill(JSON.parse(script)); return {'success': true}; })";

@end
