//
//  1Password App Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"
#import <MobileCoreServices/MobileCoreServices.h>

// Available App Extension Actions
NSString *const kUTTypeAppExtensionFindLoginAction = @"org.appextension.find-login-action";
NSString *const kUTTypeAppExtensionSaveLoginAction = @"org.appextension.save-login-action";
NSString *const kUTTypeAppExtensionFillWebViewAction = @"org.appextension.fill-webview-action";

// Login Dictionary keys
NSString *const AppExtensionURLStringKey = @"url_string";
NSString *const AppExtensionUsernameKey = @"username";
NSString *const AppExtensionPasswordKey = @"password";
NSString *const AppExtensionTitleKey = @"login_title";
NSString *const AppExtensionNotesKey = @"notes";
NSString *const AppExtensionSectionTitleKey = @"section_title";
NSString *const AppExtensionFieldsKey = @"fields";

// WebView Dictionary keys
NSString *const AppExtensionWebViewPageFillScript = @"fillScript";
NSString *const AppExtensionWebViewPageDetails = @"pageDetails";

// Password Generator options
NSString *const AppExtensionGeneratedPasswordMinLengthKey = @"password_min_length";
NSString *const AppExtensionGeneratedPasswordMaxLengthKey = @"password_max_length";

// Errors
NSString *const OPAppExtensionErrorDomain = @"OnePasswordExtension";
int const OPAppExtensionCannotContactExtensionErrorCode = 1;
int const OPAppExtensionMissingDataErrorCode = 2;
int const OPAppExtensionFailedScriptErrorCode = 3;
int const OPAppExtensionUnexpectedDataErrorCode = 4;

@implementation OnePasswordExtension

#pragma mark - Public Methods

static OnePasswordExtension *__sharedExtension;
+ (OnePasswordExtension *)sharedExtension {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__sharedExtension = [OnePasswordExtension new];
	});
	
	return __sharedExtension;
}

- (BOOL)isAppExtensionAvailable {
    if (NSClassFromString(@"NSItemProvider") == nil) {
        return NO; // App Extension is not available on iOS < 8.0
    }
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"org-appextension-feature-password-management://"]];
}

- (void)findLoginForURLString:(NSString *)URLString forViewController:(UIViewController *)forViewController completion:(void (^)(NSDictionary *loginDict, NSError *error))completion {
#ifdef __IPHONE_8_0
	NSDictionary *item = @{ AppExtensionURLStringKey: URLString };
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeAppExtensionFindLoginAction];
	
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
	
	__weak typeof (self) miniMe = self;
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	
	// Exclude unneeded UIActivityTypes
	activityViewController.excludedActivityTypes = @[ UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo, UIActivityTypeAirDrop ];
	
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		
		if (!completed || returnedItems.count == 0) {
			NSMutableDictionary *userInfo = [NSMutableDictionary new];
			userInfo[NSLocalizedDescriptionKey] = @"Error contacting the 1Password Extension";
			if (activityError) userInfo[NSUnderlyingErrorKey] = activityError;

			NSError *error = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionCannotContactExtensionErrorCode userInfo:userInfo];

			if (completion) {
				if ([NSThread isMainThread]) {
					if (completion) {
						completion(nil, error);
					}
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (completion) {
							completion(nil, error);
						}
					});
				}
			}
			
			return;
		}

		__strong typeof(self) strongMe = miniMe;
		[strongMe processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDict, NSError *error) {
			if (completion) {
				if ([NSThread isMainThread]) {
					if (completion) {
						completion(loginDict, error);
					}
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (completion) {
							completion(loginDict, error);
						}
					});
				}
			}
		}];
	};
	
	[forViewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

- (void)storeLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)forViewController completion:(void (^)(NSDictionary *, NSError *))completion {
#ifdef __IPHONE_8_0
	NSMutableDictionary *newLoginAttributesDict = [NSMutableDictionary new];
	newLoginAttributesDict[AppExtensionURLStringKey] = URLString;
	[newLoginAttributesDict addEntriesFromDictionary:loginDetailsDict]; // TODO: change 1P to use separate dicts
	[newLoginAttributesDict addEntriesFromDictionary:passwordGenerationOptions];
	
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:newLoginAttributesDict typeIdentifier:kUTTypeAppExtensionSaveLoginAction];
	
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
	
	__weak typeof (self) miniMe = self;
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	
	// Exclude unneeded UIActivityTypes
	activityViewController.excludedActivityTypes = @[ UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo, UIActivityTypeAirDrop ];
	
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		
		if (!completed || returnedItems.count == 0) {
			NSMutableDictionary *userInfo = [NSMutableDictionary new];
			userInfo[NSLocalizedDescriptionKey] = @"Error contacting the 1Password Extension";
			if (activityError) userInfo[NSUnderlyingErrorKey] = activityError;
			
			NSError *error = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionCannotContactExtensionErrorCode userInfo:userInfo];
			
			if (completion) {
				if ([NSThread isMainThread]) {
					if (completion) {
						completion(nil, error);
					}
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (completion) {
							completion(nil, error);
						}
					});
				}
			}
			
			return;
		}
		
		__strong typeof(self) strongMe = miniMe;
		[strongMe processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDict, NSError *error) {
			if (completion) {
				if ([NSThread isMainThread]) {
					if (completion) {
						completion(loginDict, error);
					}
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (completion) {
							completion(loginDict, error);
						}
					});
				}
			}
		}];
	};
	
	[forViewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

- (void)fillLoginIntoWebView:(id)webView forViewController:(UIViewController *)forViewController completion:(void (^)(BOOL success, NSError *error))completion {
#ifdef __IPHONE_8_0
	if ([webView isKindOfClass:[WKWebView class]]) {
		[self fillLoginIntoWKWebView:webView forViewController:forViewController completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
	else if ([webView isKindOfClass:[UIWebView class]]) {
		[self fillLoginIntoUIWebView:webView webViewController:forViewController completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
	else {
		[NSException raise:@"Invalid argument: web view must be an instance of WKWebView or UIWebView." format:@""];
	}
#endif
}

#pragma mark - App Extension ItemProvider Callback
#ifdef __IPHONE_8_0
- (void)processExtensionItem:(NSExtensionItem *)extensionItem completion:(void (^)(NSDictionary *loginDict, NSError *error))completion {
	if (extensionItem.attachments.count == 0) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item had no attachments." };
		NSError *error = [[NSError alloc] initWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionMissingDataErrorCode userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}
	
	NSItemProvider *itemProvider = extensionItem.attachments[0];
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *loginDict, NSError *itemProviderError) {
			
			NSError *error = nil;
			if (!loginDict) {
				NSMutableDictionary *userInfo = [NSMutableDictionary new];
				userInfo[NSLocalizedDescriptionKey] = @"Error loading item provider data.";
				if (itemProviderError) userInfo[NSUnderlyingErrorKey] = itemProviderError;

				error = [[NSError alloc] initWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionUnexpectedDataErrorCode userInfo:userInfo];
			}
			if (completion) {
				completion(loginDict, error);
			}
		}];
	}
}


#pragma mark - Web view integration

- (void)fillLoginIntoWKWebView:(WKWebView *)webView forViewController:(UIViewController *)forViewController completion:(void (^)(BOOL success, NSError *error))completion {
	__weak typeof (self) miniMe = self;
	[webView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *error) {
		if (!result) {
			NSLog(@"Error executing collect page info script: <%@>", error);

			NSMutableDictionary *userInfo = [NSMutableDictionary new];
			userInfo[NSLocalizedDescriptionKey] = @"Error executing collect page info script";
			if (error) {
				userInfo[NSUnderlyingErrorKey] = error;
			}

			NSError *collectScriptError = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionFailedScriptErrorCode userInfo:userInfo];
			if (completion) {
				completion(NO, collectScriptError);
			}
			return;
		}
		
		__strong typeof(self) strongMe = miniMe;
		[strongMe findLoginIn1PasswordWithURLString:webView.URL.absoluteString collectedPageDetails:result forWebViewController:forViewController withWebView:webView completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}];
}

- (void)fillLoginIntoUIWebView:(UIWebView *)webView webViewController:(UIViewController *)forViewController completion:(void (^)(BOOL success, NSError *error))completion {
	NSString *collectedPageDetails = [webView stringByEvaluatingJavaScriptFromString:OPWebViewCollectFieldsScript];
	[self findLoginIn1PasswordWithURLString:webView.request.URL.absoluteString collectedPageDetails:collectedPageDetails forWebViewController:forViewController withWebView:webView completion:^(BOOL success, NSError *error) {
		if (completion) {
			completion(success, error);
		}
	}];
}

- (void)findLoginIn1PasswordWithURLString:URLString collectedPageDetails:(NSString *)collectedPageDetails forWebViewController:(UIViewController *)forViewController withWebView:(id)webView completion:(void (^)(BOOL success, NSError *error))completion {
	
	NSDictionary *item = @{ AppExtensionURLStringKey : URLString,
							AppExtensionWebViewPageDetails : collectedPageDetails };
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeAppExtensionFillWebViewAction];
	
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
	
	__weak typeof (self) miniMe = self;
	
	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	
	// Excluding all available UIActivityTypes so that on the 1Password Extension is visible
	controller.excludedActivityTypes = @[ UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo, UIActivityTypeAirDrop ];
	
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (!completed || returnedItems.count == 0) {
			NSLog(@"Error contacting the 1Password Extension: <%@>", activityError);

			NSMutableDictionary *userInfo = [NSMutableDictionary new];
			userInfo[NSLocalizedDescriptionKey] = @"Error contacting the 1Password Extension";
			if (activityError) {
				userInfo[NSUnderlyingErrorKey] = activityError;
			}

			NSError *extensionError = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionCannotContactExtensionErrorCode userInfo:userInfo];
			if (completion) {
				completion(NO, extensionError);
			}

			return;
		}
		
		__strong typeof(self) strongMe = miniMe;
		[strongMe processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDict, NSError *error) {
			if (!loginDict) {
				NSLog(@"Error loading login dict for webview: %@", error);

				NSMutableDictionary *userInfo = [NSMutableDictionary new];
				userInfo[NSLocalizedDescriptionKey] = @"Error loading login dict for webview";
				if (error) {
					userInfo[NSUnderlyingErrorKey] = error;
				}

				NSError *loadError = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionMissingDataErrorCode userInfo:userInfo];
				if (completion) {
					completion(NO, loadError);
				}

				return;
			}
			
			__strong typeof(self) strongMe2 = miniMe;
			NSString *fillScript = loginDict[AppExtensionWebViewPageFillScript];
			if ([NSThread isMainThread]) {
				[strongMe2 executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *error) {
					if (completion) {
						completion(success, error);
					}
				}];
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					[strongMe2 executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *error) {
						if (completion) {
							completion(success, error);
						}
					}];
				});
			}
		}];
	};
	
	[forViewController presentViewController:controller animated:YES completion:nil];
}

- (void)executeFillScript:(NSString *)fillScript inWebView:(id)webView completion:(void (^)(BOOL success, NSError *error))completion {
	if (!fillScript) {
		NSLog(@"Fill script from the 1Password Extension is null");

		NSMutableDictionary *userInfo = [NSMutableDictionary new];
		userInfo[NSLocalizedDescriptionKey] = @"Fill script from the 1Password Extension is null";
		NSError *fillScriptError = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionFailedScriptErrorCode userInfo:userInfo];
		if (completion) {
			completion(NO, fillScriptError);
		}

		return;
	}
	
	NSMutableString *scriptSource = [OPWebViewFillScript mutableCopy];
	[scriptSource appendFormat:@"('%@');", fillScript];

	if ([webView isKindOfClass:[UIWebView class]]) {
		NSString *result = [((UIWebView *)webView) stringByEvaluatingJavaScriptFromString:scriptSource];
		if (!result) {
			NSLog(@"Failed to evaluate the fill script");

			NSMutableDictionary *userInfo = [NSMutableDictionary new];
			userInfo[NSLocalizedDescriptionKey] = @"Failed to evaluate the fill script";
			NSError *evaluateError = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionFailedScriptErrorCode userInfo:userInfo];
			if (completion) {
				completion(NO, evaluateError);
			}

			return;
		}
	}
	else if ([webView isKindOfClass:[WKWebView class]]){
		[((WKWebView *)webView) evaluateJavaScript:scriptSource completionHandler:^(NSString *result, NSError *error) {
			if (!result) {
				NSLog(@"Failed to evaluate the fill script: <%@>", error);

				NSMutableDictionary *userInfo = [NSMutableDictionary new];
				userInfo[NSLocalizedDescriptionKey] = @"Failed to evaluate the fill script";
				if (error) {
					userInfo[NSUnderlyingErrorKey] = error;
				}

				NSError *evaluateError = [NSError errorWithDomain:OPAppExtensionErrorDomain code:OPAppExtensionFailedScriptErrorCode userInfo:userInfo];
				if (completion) {
					completion(NO, evaluateError);
				}

				return;
			}
			
			NSLog(@"Result from execute fill script: %@", result);
		}];
	}
	else {
		[NSException raise:@"Invalid argument: web view must be an instance of WKWebView or UIWebView." format:@""];
	}
}
#endif
#pragma mark - WebView field collection and filling scripts

NSString *const OPWebViewCollectFieldsScript = @"var f;document.collect=l;function l(a,b){var c=Array.prototype.slice.call(a.querySelectorAll('input, select'));f=b;c.forEach(p);return c.filter(function(a){q(a,['select','textarea'])?a=!0:q(a,'input')?(a=(a.getAttribute('type')||'').toLowerCase(),a=!('button'===a||'submit'===a||'reset'==a||'file'===a||'hidden'===a||'image'===a)):a=!1;return a}).map(s)}function s(a,b){var c=a.opid,d=a.id||a.getAttribute('id')||null,g=a.name||null,z=a['class']||a.getAttribute('class')||null,A=a.rel||a.getAttribute('rel')||null,B=String.prototype.toLowerCase.call(a.type||a.getAttribute('type')),C=a.value,D=-1==a.maxLength?999:a.maxLength,E=a.getAttribute('x-autocompletetype')||a.getAttribute('autocompletetype')||a.getAttribute('autocomplete')||null,k;k=[];var h,n;if(a.options){h=0;for(n=a.options.length;h<n;h++)k.push([t(a.options[h].text),a.options[h].value]);k={options:k}}else k=null;h=u(a);n=v(a);var H=w(a),I=t(a.getAttribute('data-label')),J=t(a.getAttribute('aria-label')),K=t(a.placeholder),M=x(a),m;m=[];for(var e=a;e&&e.nextSibling;){e=e.nextSibling;if(y(e))break;F(m,e)}m=t(m.join(''));e=[];G(a,e);var e=t(e.reverse().join('')),r;a.form?(a.form.opid=a.form.opid||L.a(),a.form.opdata=a.form.opdata||{htmlName:a.form.getAttribute('name'),htmlID:a.form.getAttribute('id'),htmlAction:N(a.form.getAttribute('action')),htmlMethod:a.form.getAttribute('method'),opid:a.form.opid},r=a.form.opdata):r=null;return{opid:c,elementNumber:b,htmlID:d,htmlName:g,htmlClass:z,rel:A,type:B,value:C,maxLength:D,autoCompleteType:E,selectInfo:k,visible:h,viewable:n,'label-tag':H,'label-data':I,'label-aria':J,placeholder:K,'label-top':M,'label-right':m,'label-left':e,form:r}}function p(a,b){a.opid='__'+f+'__'+b+'__'};function x(a){var b;for(a=a.parentElement||a.parentNode;a&&'td'!=(a?(a.tagName||'').toLowerCase():'');)a=a.parentElement||a.parentNode;if(!a||void 0===a)return null;b=a.parentElement||a.parentNode;if(!q(b,'tr'))return null;b=b.previousElementSibling;if(!q(b,'tr')||b.cells&&a.cellIndex>=b.cells.length)return null;a=b.cells[a.cellIndex];return t(a.innerText||a.textContent)}function w(a){var b=a.id,c=a.name,d=a.ownerDocument;if(void 0===b&&void 0===c)return null;b=O(String.prototype.replace.call(b,\"'\",\"\\\\'\"));c=O(String.prototype.replace.call(c,\"'\",\"\\\\'\"));if(b=d.querySelector(\"label[for='\"+b+\"']\")||d.querySelector(\"label[for='\"+c+\"']\"))return t(b.innerText||b.textContent);do{if('label'===(''+a.tagName).toLowerCase())return t(a.innerText||a.textContent);a=a.parentNode}while(a&&a!=d);return null};function t(a){var b=null;a&&(b=a.toLowerCase().replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,''),b=0<b.length?b:null);return b}function F(a,b){var c;c='';3===b.nodeType?c=b.nodeValue:1===b.nodeType&&(c=b.innerText||b.textContent);(c=t(c))&&a.push(c)}function y(a){return a&&void 0!==a?q(a,'select option input form textarea iframe button'.split(' ')):!0}function G(a,b,c){var d;for(c||(c=0);a&&a.previousSibling;){a=a.previousSibling;if(y(a))return;F(b,a)}if(a&&0===b.length){for(d=null;!d;){a=a.parentElement||a.parentNode;if(!a)return;for(d=a.previousSibling;d&&!y(d)&&d.lastChild;)d=d.lastChild}y(d)||(F(b,d),0===b.length&&G(d,b,c+1))}}function q(a,b){var c;if(!a)return!1;c=a?(a.tagName||'').toLowerCase():'';return b.constructor==Array?0<=b.indexOf(c):c===b}function v(a){var b,c,d,g;if(!a||!a.offsetParent)return!1;c=a.ownerDocument.documentElement;d=a.getBoundingClientRect();g=c.getBoundingClientRect();b=d.left-c.clientLeft;c=d.top-c.clientTop;if(0>b||b>g.width||0>c||c>g.height)return u(a);if(b=a.ownerDocument.elementFromPoint(b+3,c+3)){if('label'===(b.tagName||'').toLowerCase())return g=String.prototype.replace.call(a.id,\"'\",\"\\\\'\"),c=String.prototype.replace.call(a.name,\"'\",\"\\\\'\"),a=a.ownerDocument.querySelector(\"label[for='\"+g+\"']\")||a.ownerDocument.querySelector(\"label[for='\"+c+\"']\"),b===a;if(b.tagName===a.tagName)return!0}return!1}function u(a){var b=a;a=(a=a.ownerDocument)?a.defaultView:{};for(var c;b&&b!==document;){c=a.getComputedStyle?a.getComputedStyle(b,null):b.style;if('none'===c.display||'hidden'==c.visibility)return!1;b=b.parentNode}return b===document}function O(a){return a?a.replace(/([:\\\\.'])/g,'\\\\$1'):null};var P=/^[\\/\\?]/;function N(a){if(!a)return null;if(0==a.indexOf('http'))return a;var b=window.location.protocol+'//'+window.location.hostname;window.location.port&&''!=window.location.port&&(b+=':'+window.location.port);a.match(P)||(a='/'+a);return b+a}var L=new function(){return{a:function(){function a(){return(65536*(1+Math.random())|0).toString(16).substring(1).toUpperCase()}return[a(),a(),a(),a(),a(),a(),a(),a()].join('')}}}; (function collect(uuid) { var fields = document.collect(document, uuid); return { 'url': document.baseURI, 'fields': fields }; })('uuid');";

NSString *const OPWebViewFillScript = @"var e=!0,h=!0;document.fill=k;function k(a){var b,c=[],d=a.properties,f=1,g;d&&d.delay_between_operations&&(f=d.delay_between_operations);if(null!=a.savedURL&&0===a.savedURL.indexOf('https://')&&'http:'==document.location.protocol&&(b=confirm('This page is not protected. Any information you submit can potentially be seen by others. This login was originally saved on a secure page, so it is possible you are being tricked into revealing your login information.\\n\\nDo you still wish to fill this login?'),!1==b))return;g=function(a,b){var d=a[0];void 0===d?b():('delay'===d.operation?f=d.parameters[0]:c.push(l(d)),setTimeout(function(){g(a.slice(1),b)},f))};if(b=a.options)h=b.animate,e=b.markFilling;a.hasOwnProperty('script')&&(b=a.script,g(b,function(){c=Array.prototype.concat.apply(c,void 0);a.hasOwnProperty('autosubmit')&&setTimeout(function(){autosubmit(a.autosubmit,d.allow_clicky_autosubmit)},AUTOSUBMIT_DELAY);'object'==typeof protectedGlobalPage&&protectedGlobalPage.a('fillItemResults',{documentUUID:documentUUID,fillContextIdentifier:a.fillContextIdentifier,usedOpids:c},function(){})}))}var t={fill_by_opid:m,fill_by_query:n,click_on_opid:p,click_on_query:q,touch_all_fields:r,simple_set_value_by_query:s,delay:null};function l(a){var b;if(!a.hasOwnProperty('operation')||!a.hasOwnProperty('parameters'))return null;b=a.operation;return t.hasOwnProperty(b)?t[b].apply(this,a.parameters):null}function m(a,b){var c;return(c=u(a))?(v(c,b),c.opid):null}function n(a,b){var c;c=document.querySelectorAll(a);return Array.prototype.map.call(c,function(a){v(a,b);return a.opid},this)}function s(a,b){var c,d=[];c=document.querySelectorAll(a);Array.prototype.forEach.call(c,function(a){void 0!==a.value&&(a.value=b,d.push(a.opid))});return d}function p(a){a=u(a);w(a);'function'===typeof a.click&&a.click();return a?a.opid:null}function q(a){a=document.querySelectorAll(a);return Array.prototype.map.call(a,function(a){w(a);'function'===typeof a.click&&a.click();'function'===typeof a.focus&&a.focus();return a.opid},this)}function r(){x()};var y={'true':!0,y:!0,1:!0,yes:!0,'✓':!0},z=200;function v(a,b){var c;if(a&&null!==b&&void 0!==b)switch(e&&a.form&&!a.form.opfilled&&(a.form.opfilled=!0),a.type?a.type.toLowerCase():null){case 'checkbox':c=b&&1<=b.length&&y.hasOwnProperty(b.toLowerCase())&&!0===y[b.toLowerCase()];a.checked===c||A(a,function(a){a.checked=c});break;case 'radio':!0===y[b.toLowerCase()]&&a.click();break;default:a.value==b||A(a,function(a){a.value=b})}}function A(a,b){B(a);b(a);C(a);D(a)&&(a.className+=' com-agilebits-onepassword-extension-animated-fill',setTimeout(function(){a&&a.className&&(a.className=a.className.replace(/(\\s)?com-agilebits-onepassword-extension-animated-fill/,''))},z))};function E(a,b){var c;c=a.ownerDocument.createEvent('KeyboardEvent');c.initKeyboardEvent?c.initKeyboardEvent(b,!0,!0):c.initKeyEvent&&c.initKeyEvent(b,!0,!0,null,!1,!1,!1,!1,0,0);a.dispatchEvent(c)}function B(a){w(a);a.focus();E(a,'keydown');E(a,'keyup');E(a,'keypress')}function C(a){var b=a.ownerDocument.createEvent('HTMLEvents'),c=a.ownerDocument.createEvent('HTMLEvents');E(a,'keydown');E(a,'keyup');E(a,'keypress');c.initEvent('input',!0,!0);a.dispatchEvent(c);b.initEvent('change',!0,!0);a.dispatchEvent(b);a.blur()}function w(a){!a||a&&'function'!==typeof a.click||a.click()}function F(){var a=RegExp('(pin|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i');return Array.prototype.slice.call(document.querySelectorAll(\"input[type='text']\")).filter(function(b){return b.value&&a.test(b.value)},this)}function x(){F().forEach(function(a){B(a);a.click&&a.click();C(a)})}function D(a){var b;if(b=h)a:{b=a;for(var c=a.ownerDocument,c=c?c.defaultView:{},d;b&&b!==document;){d=c.getComputedStyle?c.getComputedStyle(b,null):b.style;if('none'===d.display||'hidden'==d.visibility){b=!1;break a}b=b.parentNode}b=b===document}return b?-1!=='email text password number tel url'.split(' ').indexOf(a.type||''):!1}function u(a){var b,c,d;if(a)for(d=document.querySelectorAll('input, select'),b=0,c=d.length;b<c;b++)if(d[b].opid==a)return d[b];return null}; (function execute_fill_script(scriptJSON) { var script = null, error = null; try { script = JSON.parse(scriptJSON);} catch (e) { error = e; } if (!script) { return { 'success': false, 'error': 'Unable to parse fill script JSON. Javascript exception: ' + error }; } document.fill(script); return {'success': true}; })";

@end