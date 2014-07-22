//
//  WebViewController.m
//  1Password Extension Demo
//
//  Created by Dave Teare on 2014-07-19.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "WebViewController.h"

#import "OPExtensionConstants.h"

@interface WebViewController() <UISearchBarDelegate, WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet UIButton *onepasswordFillButton;
@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) WKWebView *webView;

@end

@implementation WebViewController

#pragma mark - Life Cycle

-(void)viewDidLoad {
	[self.onepasswordFillButton setHidden:![self is1PasswordExtensionAvailable]];

	WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
	[self addUserScriptsToUserContentController:configuration.userContentController];

	self.webView = [[WKWebView alloc] initWithFrame:self.webViewContainer.bounds configuration:configuration];
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.webView.navigationDelegate = self;
	[self.webViewContainer addSubview:self.webView];

	NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"html"];
	NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
	[self.webView loadHTMLString:htmlString baseURL:nil];
}

- (BOOL)is1PasswordExtensionAvailable {
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"onepassword-extension://fill"]];
}

#pragma mark - Invoking the 1Password Extension 

- (void)findLoginIn1PasswordWithCollectedPageDetails:(NSString *)collectedPageDetails {
	NSDictionary *item = @{ OPLoginURLStringKey : self.searchBar.text,
							OPWebViewPageDetails : collectedPageDetails };
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionFillWebViewAction];
	
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	__weak typeof (self) miniMe = self;

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];

	// Excluding all available UIActivityTypes so that on the 1Password Extension is visible
	controller.excludedActivityTypes = @[ UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo, UIActivityTypeAirDrop ];

	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		// NOTE: returnedItems is nil after the second call. radar://17669995
		if (completed) {
			__strong typeof(self) strongMe = miniMe;
			for (NSExtensionItem *extensionItem in returnedItems) {
				[strongMe processExtensionItem:extensionItem];
			}
		}
		else {
			NSLog(@"Error contacting the 1Password Extension: <%@>", activityError);
		}
	};

	[self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - ItemProvider Callback

- (void)processItemProvider:(NSItemProvider *)itemProvider {
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		__weak typeof (self) miniMe = self;
		[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *item, NSError *error) {
			// We need to have 0.5 delay to allow the fillscript to fill the webviews form
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				if (item) {
					NSString *fillScript = item[OPWebViewPageFillScript];
					[miniMe executeFillScript:fillScript];
				}
				else {
					NSLog(@"Failed to parse item provider result: <%@>", error);
				}
			});
		}];
	}
}

- (void)processExtensionItem:(NSExtensionItem *)extensionItem {
	for (NSItemProvider *itemProvider in extensionItem.attachments) {
		[self processItemProvider:itemProvider];
	}
}

#pragma mark - Actions

- (IBAction)fillUsing1Password:(id)sender {
	NSMutableString *collectPageInfoScript = [[self loadUserScriptSourceNamed:@"collect_lib.min"] mutableCopy];
	[collectPageInfoScript appendString:[self loadUserScriptSourceNamed:@"collect"]];
	[self.webView evaluateJavaScript:collectPageInfoScript completionHandler:^(NSString *result, NSError *error) {
		if (result) {
			[self findLoginIn1PasswordWithCollectedPageDetails:result];
		}
		else {
			NSLog(@"Error executing collect page info script: <%@>", error);
		}
	}];
}

- (IBAction)goBack:(id)sender {
	WKNavigation *navigation = [self.webView goBack];

	if (!navigation) {
		NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"html"];
		NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
		[self.webView loadHTMLString:htmlString baseURL:nil];

	}
}

- (IBAction)goForward:(id)sender {
	[self.webView goForward];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self loadURLString:searchBar.text];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[self loadURLString:searchBar.text];
}

- (void)handleSearch:(UISearchBar *)searchBar {
	[self loadURLString:searchBar.text];
	[searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	[self loadURLString:searchBar.text];
	[searchBar resignFirstResponder];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	self.searchBar.text = webView.URL.absoluteString;
}

#pragma mark - Convenience Methods

- (void)executeFillScript:(NSString *)fillScript {
	if (!fillScript) {
		NSLog(@"Fill script from the 1Password Extension is null");
		return;
	}

	NSMutableString *scriptSource = [[self loadUserScriptSourceNamed:@"fill_lib.min"] mutableCopy];

	[scriptSource appendFormat:@"%@('%@');", [self loadUserScriptSourceNamed:@"fill"], fillScript];

	[self.webView evaluateJavaScript:scriptSource completionHandler:^(NSString *result, NSError *error) {
		if (!result) {
			NSLog(@"Failed to evaulate the fill script: <%@>", error);
			return;
		}

		NSLog(@"Result from execute fill script: %@", result);
	}];
}

- (void)loadURLString:(NSString *)URLString {
	if (![URLString hasPrefix:@"http"]) {
		URLString = [NSString stringWithFormat:@"https://%@", URLString];
	}

	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[self.webView loadRequest:request];

	self.searchBar.text = URLString;
}

- (void)addUserScriptsToUserContentController:(WKUserContentController *)userContentController {
	// TODO: WKUserScript is never called. Radar #
	NSString *autosaveScriptString = @"Array.prototype.forEach.call(document.querySelectorAll('header'), function(el){el.style.display='none'});"; // [self loadUserScriptSourceNamed:@"autosave"];
	WKUserScript *autosaveUserScript = [[WKUserScript alloc] initWithSource:autosaveScriptString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
	[userContentController addUserScript:autosaveUserScript];
}

- (NSString *)loadUserScriptSourceNamed:(NSString *)filename {
	NSError *error = nil;
	NSURL *scriptURL = [[NSBundle mainBundle] URLForResource:filename withExtension:@"js"];
	NSString *scriptString = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:&error];

	if (!scriptString) {
		NSLog(@"Error loading %@: <%@>", scriptURL, error);
		return nil;
	}

	return scriptString;
}

@end
