//
//  FirstViewController.swift
//  ACME Browser Swift
//
//  Created by Rad on 2015-05-14.
//  Copyright (c) 2015 AgileBits Inc. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UISearchBarDelegate, WKNavigationDelegate {

	@IBOutlet weak var onepasswordFillButton: UIButton!
	@IBOutlet weak var webViewContainer: UIView!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet var webView: WKWebView!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.onepasswordFillButton.hidden = (false == OnePasswordExtension.sharedExtension().isAppExtensionAvailable())

		let configuration = WKWebViewConfiguration.new()
		
		self.webView = WKWebView(frame: self.webViewContainer.bounds, configuration: configuration)
		self.webView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
		self.webView.navigationDelegate = self
		self.webViewContainer.addSubview(self.webView)

		let htmlFilePath = NSBundle.mainBundle().pathForResource("welcome", ofType: "html")
		var htmlStringError: NSError?
		let htmlString: String? = String(contentsOfFile: htmlFilePath!, encoding:NSUTF8StringEncoding, error: &htmlStringError)
		if htmlString == nil {
			println("Failed to obtain the html string from file \(htmlFilePath) with error: <\(htmlStringError)>")
		}

		self.webView.loadHTMLString(htmlString!, baseURL: nil)
	}

	@IBAction func fillUsing1Password(sender: AnyObject) -> Void {
		OnePasswordExtension.sharedExtension().fillItemIntoWebView(self.webView, forViewController: self, sender: sender, showOnlyLogins: false) { (success, error) -> Void in
			if success == false {
				println("Failed to fill into webview: <\(error)>")
			}
		}
	}

	@IBAction func goBack(sender: AnyObject) -> Void {
		let navigation = self.webView.goBack()

		if navigation == nil {
			let htmlFile = NSBundle.mainBundle().pathForResource("welcome", ofType: "html")
			var error: NSError?
			let htmlString: String? = String(contentsOfFile: htmlFile!, encoding:NSUTF8StringEncoding, error: &error)
			if htmlString == nil {
				println("Failed to obtain the html string from file \(htmlFile) with error <\(error)>")
			}

			self.webView.loadHTMLString(htmlString!, baseURL: nil)
		}
	}
	@IBAction func goForward(sender: AnyObject) -> Void {
		self.webView.goForward()
	}

	// UISearchBarDelegate
	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		self.performSearch(searchBar.text)
	}

	func searchBarTextDidEndEditing(searchBar: UISearchBar) {
		self.performSearch(searchBar.text)
	}

	func handleSearch(searchBar: UISearchBar) {
		self.performSearch(searchBar.text)
	}

	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		self.performSearch(searchBar.text)
	}

	// Convenience
	func performSearch(text: String) {
		let lowercaseText = text.lowercaseStringWithLocale(NSLocale.currentLocale())
		var URL: NSURL?

		let hasSpaces = lowercaseText.rangeOfString(" ") != nil
		let hasDots = lowercaseText.rangeOfString(".") != nil

		let search: Bool = !hasSpaces || !hasDots;
		if (search) {
			var hasScheme = lowercaseText.hasPrefix("http:") || lowercaseText.hasPrefix("https:")
			if (hasScheme) {
				URL = NSURL(string: lowercaseText)
			}
			else {
				URL = NSURL(string: "https://".stringByAppendingString(lowercaseText))
			}
		}

		if (URL == nil) {
			let escapedText = lowercaseText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding);
			let googleSearch = "http://www.google.com/search?q="
			URL = NSURL(string: googleSearch.stringByAppendingString(escapedText!))
		}

		self.searchBar.text = URL?.absoluteString
		self.searchBar.resignFirstResponder()

		let request = NSURLRequest(URL: URL!);
		self.webView.loadRequest(request)
	}
	
	// WKNavigationDelegate

	func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		self.searchBar.text = webView.URL?.absoluteString

		if self.searchBar.text == "about:blank" {
			self.searchBar.text = ""
		}
	}
}

