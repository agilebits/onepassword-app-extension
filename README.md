# 1Password App Extension

Welcome! With just a few lines of code, your app can add 1Password support, enabling your users to:

1. Access their 1Password Logins to automatically fill your signin page
2. Use the Strong Password Generator to create unique passwords during registration
3. Quickly fill 1Password Logins directly into web views

Allowing your users to use strong, unique passwords has never been easier.

<!--- TODO: quick video here -->


## TL;DR; Just Give Me the Code

You might be looking at this 13KB README and think integrating with 1Password is very complicated. Nothing could be further from the truth! 

If you're the type that just wants the code, here it is!

* [OnePasswordExtension.h](https://raw.githubusercontent.com/AgileBits/onepassword-app-extension/task/wrap-into-api/OnePasswordExtension.h?token=110676__eyJzY29wZSI6IlJhd0Jsb2I6QWdpbGVCaXRzL29uZXBhc3N3b3JkLWFwcC1leHRlbnNpb24vdGFzay93cmFwLWludG8tYXBpL09uZVBhc3N3b3JkRXh0ZW5zaW9uLmgiLCJleHBpcmVzIjoxNDA3MjQzNDI5fQ%3D%3D--4d8c0511d8ed1a56e9f8169ddbca8599389f6b35)
* [OnePasswordExtension.m](https://raw.githubusercontent.com/AgileBits/onepassword-app-extension/task/wrap-into-api/OnePasswordExtension.m?token=110676__eyJzY29wZSI6IlJhd0Jsb2I6QWdpbGVCaXRzL29uZXBhc3N3b3JkLWFwcC1leHRlbnNpb24vdGFzay93cmFwLWludG8tYXBpL09uZVBhc3N3b3JkRXh0ZW5zaW9uLm0iLCJleHBpcmVzIjoxNDA3MjQzMzIxfQ%3D%3D--bcfe80febb3d31fb19b695d23e2c54611441a550)

Simply include these two files in your project, add a [1Password login image](https://github.com/AgileBits/onepassword-app-extension/tree/task/wrap-into-api/Resources/1Password.xcassets) to your view, and set its action to call the appropriate OnePasswordExtension method, and you're all set!


## Running the Sample Apps

Adding 1Password support to your app is easy. To demonstrate how it works, we have two sample apps for iOS that showcase all of the 1Password features. 


### Step 1: Download the Source Code and Sample Apps

To get started, download the 1Password Extension project from https://github.com/AgileBits/onepassword-extension/archive/master.zip, or [clone it from GitHub](https://github.com/AgileBits/onepassword-extension).

Inside the downloaded folder, you'll find the resources needed to integrate with 1Password, such as images, scripts, and sample code. The sample code includes two apps from ACME Corporation: one that demonstrates how to integrate the 1Password Login and Signup features, as well as a web browser that showcases the WebView Filling feature. 


### Step 2: Install the Latest 1Password & XCode Betas

The sample project depends upon having the latest version of XCode 6, as well as the 1Password Beta installed on your iOS device. 

<!---
If you are developing for OS X, you can enable betas within the 1Password > Preferences > Updates window (as shown [here](i.agilebits.com/Preferences_197C0C6B.png)) and enabling the _Include beta builds_ checkbox. Mac App Store users should [download the webstore version](https://agilebits.com/downloads) in order to enable betas.
-->

To join the 1Password Beta, you will need to [enroll in the 1Password for iOS Beta program](https://agilebits.com/beta_signups/signup). Be sure to mention in your application that you are an app developer and planning to add 1Password support.

Beta enrollment is a manual process so please allow a bit of time to hear back from us.


### Step 3: Run the Apps

Open `1Password Extension Demos` XCode workspace from within the `Demos` folder with XCode 6, and then select the `ACME` target and set it to run your iOS device:

<img src="http://i.agilebits.com/dt/Menubar_and_SignInViewController_m_and_README_md_—_onepassword-extension__git__master__197DEA31.png" width="405" height="150">

Since you will not have 1Password running within your iOS Simulator, it is important that you run on your device.

If all goes well, The ACME app will launch and you'll be able to test the 1Password App Extension. Change the scheme to ACME Browser to test the web view filling feature.

If the 1Password icons are missing, it likely means you do not have the 1Password Beta installed.


## Integrating 1Password With Your App

Once you've verified your setup by testing the sample applications, it is time to get your hands dirty and see exactly how to add 1Password into your app. 

Be forewarned, however, that there is not much code to get dirty with. If you were looking for an SDK to waste days of your life on, you'll be sorely disappointed. 


### Add 1Password Files to Your Project

First add the images, scripts, and header file that you'll need by dragging the contents of the 1Password Extension's `Resources` folder into your project. We suggest placing them into a `1Password Extension` group under Supporting Files.

<img src="http://cl.ly/image/2g3B1r2O2z0L/Image%202014-07-29%20at%209.19.36%20AM.png" width="520" height="474"/>

### Scenario 1: Native App Login

Here we'll learn how to enable your existing users to fill their credentials into your native app's login form. If your application is using a WebView to login (i.e. OAuth), you'll want to follow the web view integration steps in Scenario 3.

The first step is to add a UIButton to your login page. Use an existing 1Password image from the _1Password.xcassets_ catalog so users recognize the button.

You'll need to hide this button, (or educate users on the benefits of strong, unique passwords) if no password manager is installed. You can use `is1PasswordExtensionAvailable` to determine availablity and hide the button if it isn't. For example:

```objective-c
-(void)viewDidLoad {
	[self.onepasswordSigninButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}
```

Note that `isAppExtensionAvailable` looks to see if any app is installed that supports the generic `org-appextension-feature-password-management` feature. Any application that supports password management actions can be used. 

Next we need to wire up the action for this button to this method in your UIViewController:

```objective-c
- (IBAction)findLoginFrom1Password:(id)sender {
	__weak typeof (self) miniMe = self;
	[[OnePasswordExtension sharedExtension] findLoginForURLString:@"https://www.acme.com" forViewController:self completion:^(NSDictionary *loginDict, NSError *error) {
		if (!loginDict) {
			NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
			return;
		}
		
		__strong typeof(self) strongMe = miniMe;
		strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey];
		strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey];
	}];
}
```

Aside from the [weak/strong self dance](http://dhoerl.wordpress.com/2013/04/23/i-finally-figured-out-weakself-and-strongself/), this code is pretty straight forward:

1. Provide a URLString that uniquely identifies your service. For example, if your app required a Twitter login, you would pass in @"https://twitter.com". See _Best Practices_ for details.
2. Pass in the UIViewController that you want the share sheet to be presented upon.
3. Provide a completion block that will be called when the user finishes their selection. This block is guarenteed to be called on the main thread.
4. Extract the needed information from the login dictionary and update your UI elements. 


### Scenario 2: New User Signup

Allow your users to access 1Password directly from your signup page so they can generate strong, unique passwords. 1Password will also save the login for future use, allowing users to easily log into your app on their other devices.

Adding 1Password to your Signup Screen is very similar to adding 1Password to your Login Screen:

```objective-c
- (IBAction)saveLoginTo1Password:(id)sender {
	NSDictionary *newLoginDetails = @{
		AppExtensionTitleKey: @"ACME",
		AppExtensionUsernameKey: self.usernameTextField.text ? : @"",
		AppExtensionPasswordKey: self.passwordTextField.text ? : @"",
		AppExtensionNotesKey: @"Saved with the ACME app",
		AppExtensionSectionTitleKey: @"ACME Browser",
		AppExtensionFieldsKey: @{
			  @"firstname" : self.firstnameTextField.text ? : @"",
			  @"lastname" : self.lastnameTextField.text ? : @""
			  // Add as many string fields as you please.
		}
	};
	
	NSDictionary *passwordGenerationOptions = @{
		AppExtensionGeneratedPasswordMinLengthKey: @(6),
		AppExtensionGeneratedPasswordMaxLengthKey: @(50)
	};
	__weak typeof (self) miniMe = self;

	[[OnePasswordExtension sharedExtension] storeLoginForURLString:@"https://www.acme.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self completion:^(NSDictionary *loginDict, NSError *error) {

		if (!loginDict) {
			NSLog(@"Error invoking 1Password App Extension for generate password: %@", error);
			return;
		}

		__strong typeof(self) strongMe = miniMe;
		strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey] ? : strongMe.usernameTextField.text;
		strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey] ? : strongMe.usernameTextField.text;
	}];
}
```

You'll notice that we're passing in a lot more information into 1Password than just the URLStringKey used in the sign in example. This is because at the end of the password generation process, 1Password will create a brand new login and save it. It's not possible for 1Password to ask your app for additional information later on, so we pass in everything we can before showing the password generator screen.

An important thing to notice is the `OPLoginURLStringKey` is set to the exact same value we used in the login scenario. This allows users to quickly find the login they saved for your app the next time they need to sign in.


### Scenario 3: Web View Support

The 1Password Extension is not limited to filling native UIs. With just a little bit of extra effort, users can fill `UIWebView`s and `WKWebView`s within your application as well. 

Add a button to your UI with its action assigned to this method in your web view's UIViewController:

```objective-c
- (IBAction)fillUsing1Password:(id)sender {
	[[OnePasswordExtension sharedExtension] fillLoginIntoWebView:self.webView forViewController:self];
}
```

1Password will take care of all the details of collecting information about the currently displayed page, allow the user to select the desired login, and then fill the web form details within the page.


## Best Practices

* Use the same URLString during Registration and Login.
* Ensure your URLString is set to your actual service so your users can easily find their logins within the main 1Password app.
* You should only ask for login information of your own service or one specific to your app. Giving a URL for a service which you do not own or support may seriously break the customer's trust in your service/app.
* Use app://bundleIdentifier (e.g. app://com.apple.Safari) if you don't have a website for your app.
* Use the provided icons so users are familiar with what it will do. Contact us if you'd like additional sizes or have other special requirements.
* Enable users to set 1Password as their default browser for external web links.
* Provide us an icon to use for the Rich Icon service so the user can see your lovely icon while creating new items.
* On the signup page, pre-validate fields before calling 1Password. For example, display a message if the username is not available so the user can fix it before activating 1Password.


## References 

If you open up OnePasswordExtension.m and start poking around, you'll be interested in these references.

* [Apple Extension Guide](https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/index.html#//apple_ref/doc/uid/TP40014214)
* [NSItemProvider](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSItemProvider_Class/index.html#//apple_ref/doc/uid/TP40014351), [NSExtensionItem](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSExtensionItem_Class/index.html#//apple_ref/doc/uid/TP40014375), and [UIActivityViewController](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIActivityViewController_Class/index.html#//apple_ref/doc/uid/TP40011976) class references.


## Contact Us

Contact us, please! We'd love to hear from you about how you integrated 1Password within your app, how we can further improve things, and add your app to [apps that integrate with 1Password](http://blog.agilebits.com/2013/04/03/ios-apps-1password-integrated-support/). 

You can reach us at support+appex@agilebits.com, or if you prefer, [@1PasswordBeta](https://twitter.com/1PasswordBeta) on Twitter.

