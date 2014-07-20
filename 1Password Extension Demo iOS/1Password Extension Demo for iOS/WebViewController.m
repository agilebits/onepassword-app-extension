//
//  WebViewController.m
//  1Password Extension Demo
//
//  Created by Dave Teare on 2014-07-19.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "WebViewController.h"

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
	[self loadURLString:@"https://mobile.twitter.com/login"];
}

#pragma mark - Convenience Methods

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


#pragma mark - UISearchBarDelegate -

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

#pragma mark - Actions -

- (IBAction)goBack:(id)sender {
	[self.webView goBack];
}

- (IBAction)goForward:(id)sender {
	[self.webView goForward];
}

- (IBAction)fillUsing1Password:(id)sender {
	[self.webView evaluateJavaScript:@"Array.prototype.forEach.call(document.querySelectorAll('header'), function(el){el.style.display='none'});" completionHandler:^(id result, NSError *error) {
		NSLog(@"DONE! %@", error);
	}];
}

@end
