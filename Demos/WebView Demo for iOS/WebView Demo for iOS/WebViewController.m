//
//  WebViewController.m
//  1Password Extension Demo
//
//  Created by Dave Teare on 2014-07-19.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "WebViewController.h"

#import "OnePasswordExtension.h"

@interface WebViewController() <UISearchBarDelegate, WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet UIButton *onepasswordFillButton;
@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) WKWebView *webView;

@end

@implementation WebViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
	[self.onepasswordFillButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];

	WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
	self.webView = [[WKWebView alloc] initWithFrame:self.webViewContainer.bounds configuration:configuration];
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.webView.navigationDelegate = self;
	[self.webViewContainer addSubview:self.webView];

	NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"html"];
	NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
	[self.webView loadHTMLString:htmlString baseURL:nil];
}

#pragma mark - Actions

- (IBAction)fillUsing1Password:(id)sender {
	[[OnePasswordExtension sharedExtension] fillLoginIntoWebView:self.webView forViewController:self sender:sender completion:^(BOOL success, NSError *error) {
		if (!success) {
			NSLog(@"Failed to fill login in webview: <%@>", error);
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

#pragma mark - Convenience Methods

- (void)loadURLString:(NSString *)URLString {
	if (![URLString hasPrefix:@"http"]) {
		URLString = [NSString stringWithFormat:@"https://%@", URLString];
	}
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[self.webView loadRequest:request];
	
	self.searchBar.text = URLString;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	self.searchBar.text = webView.URL.absoluteString;

	if ([self.searchBar.text isEqualToString:@"about:blank"]) {
		self.searchBar.text = @"";
	}
}

@end
