//
//  WebViewController.swift
//  WebView Demo for iOS Swift
//
//  Created by Rad Azzouz on 2015-05-14.
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
		self.onepasswordFillButton.isHidden = (false == OnePasswordExtension.shared().isAppExtensionAvailable())

		let configuration = WKWebViewConfiguration()
		
		self.webView = WKWebView(frame: self.webViewContainer.bounds, configuration: configuration)
		self.webView.autoresizingMask = UIViewAutoresizing(arrayLiteral: .flexibleHeight, .flexibleWidth)
		self.webView.navigationDelegate = self
		self.webViewContainer.addSubview(self.webView)

		let htmlFilePath = Bundle.main.pathForResource("welcome", ofType: "html")
		var htmlString : String!
		do {
			htmlString = try String(contentsOfFile: htmlFilePath!, encoding: String.Encoding.utf8)
		}
		catch {
			print("Failed to obtain the html string from file \(htmlFilePath) with error: <\(error)>")
		}

		self.webView.loadHTMLString(htmlString, baseURL: URL(string: "https://agilebits.com"))
	}

	@IBAction func fillUsing1Password(sender: AnyObject) -> Void {
		OnePasswordExtension.shared().fillItem(intoWebView: self.webView, for: self, sender: sender, showOnlyLogins: false) { (success, error) -> Void in
			if success == false {
				print("Failed to fill into webview: <\(error)>")
			}
		}
	}

	@IBAction func goBack(sender: AnyObject) -> Void {
		let navigation = self.webView.goBack()

		if navigation == nil {
			let htmlFilePath = Bundle.main.pathForResource("welcome", ofType: "html")
			var htmlString : String!
			do {
				htmlString = try String(contentsOfFile: htmlFilePath!, encoding: String.Encoding.utf8)
			}
			catch {
				print("Failed to obtain the html string from file \(htmlFilePath) with error: <\(error)>")
			}

			self.webView.loadHTMLString(htmlString, baseURL: URL(string: "https://agilebits.com"))
		}
	}
	@IBAction func goForward(sender: AnyObject) -> Void {
		self.webView.goForward()
	}

	// UISearchBarDelegate
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		self.performSearch(text: searchBar.text)
	}

	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		self.performSearch(text: searchBar.text)
	}

	func handleSearch(searchBar: UISearchBar) {
		self.performSearch(text: searchBar.text)
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		self.performSearch(text: searchBar.text)
	}

	// Convenience
	func performSearch(text: String!) {
		let lowercaseText = text.lowercased(with:Locale.current())
		var URL: NSURL?

		let hasSpaces = lowercaseText.range(of: " ") != nil
		let hasDots = lowercaseText.range(of: ".") != nil

		let search: Bool = !hasSpaces || !hasDots
		if (search) {
			let hasScheme = lowercaseText.hasPrefix("http:") || lowercaseText.hasPrefix("https:")
			if (hasScheme) {
				URL = NSURL(string: lowercaseText)
			}
			else {
				URL = NSURL(string: "https://".appending(lowercaseText))
			}
		}

		if (URL == nil) {
			let URLComponents = NSURLComponents()
			URLComponents.scheme = "https"
			URLComponents.host = "www.google.com"
			URLComponents.path = "/search"
			
			let queryItem = NSURLQueryItem(name: "q", value: text)
			URLComponents.queryItems = [queryItem as URLQueryItem]
			
			URL = URLComponents.url as NSURL?
		}

		self.searchBar.text = URL?.absoluteString
		self.searchBar.resignFirstResponder()

		let request = URLRequest(url: (URL?.absoluteURL)!)
		self.webView.load(request)
	}
	
	// WKNavigationDelegate

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		self.searchBar.text = webView.url?.absoluteString

		if self.searchBar.text == "about:blank" {
			self.searchBar.text = ""
		}
	}
}

