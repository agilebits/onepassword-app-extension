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

		let htmlFilePath = Bundle.main.path(forResource: "welcome", ofType: "html")
		var htmlString : String!
		do {
			htmlString = try String(contentsOfFile: htmlFilePath!, encoding: String.Encoding.utf8)
		}
		catch {
			print("Failed to obtain the html string from file \(String(describing: htmlFilePath)) with error: <\(String(describing: error))>")
		}

		self.webView.loadHTMLString(htmlString, baseURL: URL(string: "https://agilebits.com"))
	}

	@IBAction func fillUsing1Password(_ sender: AnyObject) -> Void {
		OnePasswordExtension.shared().fillItem(intoWebView: self.webView, for: self, sender: sender, showOnlyLogins: false) { (success, error) -> Void in
			if success == false {
				print("Failed to fill into webview: <\(String(describing: error))>")
			}
		}
	}

	@IBAction func goBack(_ sender: AnyObject) -> Void {
		let navigation = self.webView.goBack()

		if navigation == nil {
			let htmlFilePath = Bundle.main.path(forResource: "welcome", ofType: "html")
			var htmlString : String!
			do {
				htmlString = try String(contentsOfFile: htmlFilePath!, encoding: String.Encoding.utf8)
			}
			catch {
				print("Failed to obtain the html string from file \(String(describing: htmlFilePath)) with error: <\(String(describing: error))>")
			}

			self.webView.loadHTMLString(htmlString, baseURL: URL(string: "https://agilebits.com"))
		}
	}
	@IBAction func goForward(_ sender: AnyObject) -> Void {
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
		let lowercaseText = text.lowercased(with: NSLocale.current)
		var url: URL?

		let hasSpaces = lowercaseText.range(of: " ") != nil
		let hasDots = lowercaseText.range(of: ".") != nil

		let search: Bool = !hasSpaces || !hasDots
		if (search) {
			let hasScheme = lowercaseText.hasPrefix("http:") || lowercaseText.hasPrefix("https:")
			if (hasScheme) {
				url = URL(string: lowercaseText)
			}
			else {
				url = URL(string: "https://" + lowercaseText)
			}
		}

		if (url == nil) {
			let urlComponents = NSURLComponents()
			urlComponents.scheme = "https"
			urlComponents.host = "www.google.com"
			urlComponents.path = "/search"
			
			let queryItem = URLQueryItem(name: "q", value: text)
			urlComponents.queryItems = [queryItem]
			
			url = urlComponents.url
		}

		self.searchBar.text = url?.absoluteString
		self.searchBar.resignFirstResponder()

		let request = URLRequest(url: url!)
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

