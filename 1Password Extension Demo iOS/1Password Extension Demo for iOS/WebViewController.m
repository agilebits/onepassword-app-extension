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

@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) WKWebView *webView;

@end

@implementation WebViewController

#pragma mark - Life Cycle

-(void)viewDidLoad {
	WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
	[self addUserScriptsToUserContentController:configuration.userContentController];
	
	self.webView = [[WKWebView alloc] initWithFrame:self.webViewContainer.bounds configuration:configuration];
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.webView.navigationDelegate = self;
	[self.webViewContainer addSubview:self.webView];
}

-(void)viewDidAppear:(BOOL)animated {
	[self loadURLString:@"https://mobile.twitter.com/session/new"];
}

#pragma mark - Actions

- (IBAction)goBack:(id)sender {
	[self.webView goBack];
}

- (IBAction)goForward:(id)sender {
	[self.webView goForward];
}

- (IBAction)fillUsing1Password:(id)sender {
	NSMutableString *collectPageInfoScript = [[self loadUserScriptSourceNamed:@"collect_lib.min"] mutableCopy];
	[collectPageInfoScript appendString:[self loadUserScriptSourceNamed:@"collect"]];
	
	NSLog(@"collectPageInfoScript=<%@>", collectPageInfoScript);
	
	[self.webView evaluateJavaScript:collectPageInfoScript completionHandler:^(NSString *result, NSError *error) {
		
		if (!result) {
			NSLog(@"Error executing collect page info script: %@", error);
			return;
		}
		
		NSLog(@"Collected page information: <%@>", result);
		
		[self lookupLoginIn1PasswordForURLString:@"https://twitter.com" collectedPageDetails:result];
		
// TESTING w/o extension		[self executeFillScriptWithUsername:@"RadTweeter" password:@"SuperPassword!!!!!"];
	}];
}

#pragma mark - Extension Share Sheet

- (void)lookupLoginIn1PasswordForURLString:(NSString *)URLString collectedPageDetails:(NSString *)collectedPageDetails {
	NSDictionary *item = @{ OPLoginURLStringKey: URLString,
							@"pageDetails": collectedPageDetails};
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionFillWebViewAction];
	
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
	
	__weak typeof (self) miniMe = self;
	
	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		
		// NOTE: returnedItems is nil after the second call. radar://17669995
		
		if (!completed) {
			NSLog(@"Error contacting 1Password Extension: %@", activityError);
			return;
		}
		
		for (NSExtensionItem *extensionItem in returnedItems) {
			[miniMe processExtensionItem:extensionItem];
		}
	};
	
	[self presentViewController:controller animated:YES completion:nil];
}


#pragma mark - Item Provider Callback

- (void)processItemProvider:(NSItemProvider *)itemProvider {
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		__weak typeof (self) weakSelf = self;
		[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *item, NSError *error) {
			if (!item) {
				NSLog(@"Failed to parse item provider result: <%@>", error);
				return;
			}
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				NSString *fillScript = item[@"fillScript"];
				
				NSLog(@"Fill script from 1P: <%@>", fillScript);
				
				[weakSelf executeFillScript:fillScript];
			});
		}];
	}
}

- (void)processExtensionItem:(NSExtensionItem *)extensionItem {
	for (NSItemProvider *itemProvider in extensionItem.attachments) {
		[self processItemProvider:itemProvider];
	}
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


#pragma mark - Convenience Methods

- (void)executeFillScript:(NSString *)fillScript {
	NSLog(@"Fill script from 1Password: <%@>", fillScript);
	
	NSMutableString *scriptSource = [[self loadUserScriptSourceNamed:@"fill_lib.min"] mutableCopy];
	[scriptSource appendFormat:@"%@('%@');", [self loadUserScriptSourceNamed:@"fill"], fillScript];
	[self.webView evaluateJavaScript:scriptSource completionHandler:^(NSString *result, NSError *error) {
		if (!result) {
			NSLog(@"ERROR evaulating fill script: %@", error);
			return;
		}
		
		NSLog(@"Result from execute fill script: %@", result);
	}];
}

- (NSString *)rudimentaryFillScriptForUsername:(NSString *)username password:(NSString *)password {
	NSString *simpleFillScript = [NSString stringWithFormat:@"{\"script\":[{\"operation\":\"fill_by_query\",\"parameters\":[\"input[type=email],input[type=text]\",\"%@\"]},{\"operation\":\"fill_by_query\",\"parameters\":[\"input[type=password]\",\"%@\"]}]}", username, password];
	
	return simpleFillScript;
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
		NSLog(@"Error loading %@: %@", scriptURL, error);
		return nil;
	}
	
	return scriptString;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	self.searchBar.text = webView.URL.absoluteString;
}

@end
