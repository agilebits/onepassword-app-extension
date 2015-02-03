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
    __strong WKWebView *webView = self.webView;
    __strong UIView *webViewContainer = self.webViewContainer;
	webView = [[WKWebView alloc] initWithFrame:webViewContainer.bounds configuration:configuration];
	webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	webView.navigationDelegate = self;
	[webViewContainer addSubview:webView];

	NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"html"];
	NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
	[webView loadHTMLString:htmlString baseURL:nil];
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
    __strong UISearchBar *searchBar = self.searchBar;
	searchBar.text = webView.URL.absoluteString;

	if ([searchBar.text isEqualToString:@"about:blank"]) {
		searchBar.text = @"";
	}
}

@end
