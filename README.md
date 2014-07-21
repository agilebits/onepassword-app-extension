# 1Password App Extension

Welcome! With just a few lines of code, your app can add 1Password support, enabling your users to:

1. Access their 1Password Logins to automatically fill your signin page
2. Use the Strong Password Generator to create unique passwords during registration
3. Quickly fill 1Password Logins directly into web views

Strong, unique passwords for all websites and every app is critical to everyone's security, for both users and companies. With direct 1Password integration, we can encourage all our users to avoid shortcuts, stay secure, and make the world a better place.


## Getting Started

Adding 1Password support to your app is easy. To demonstrate how it works, we have a sample app for iOS that showcases all of these 1Password features.


### Step 1: Download the Demo Project

To get started, download the 1Password Extension Demo project from https://github.com/AgileBits/opxdemo/archive/master.zip, or [clone it from GitHub](https://github.com/AgileBits/opxdemo).

Inside the downloaded folder, you'll find the resources needed to integrate with 1Password, such as images and scripts, as well as the `1Password Extension Demo for iOS` project. This project contains a sample ACME Browser app that demonstrates how to integrate with all the 1Password features. 


### Step 2: Install the Latest 1Password & XCode Betas

The sample project depends upon having the latest version of XCode 6, as well as the 1Password Beta installed on your iOS device. 

<!---
If you are developing for OS X, you can enable betas within the 1Password > Preferences > Updates window (as shown [here](i.agilebits.com/Preferences_197C0C6B.png)) and enabling the _Include beta builds_ checkbox. Mac App Store users should [download the webstore version](https://agilebits.com/downloads) in order to enable betas.
-->

To join the 1Password Beta, you will need to [enroll in the 1Password for iOS Beta program](https://agilebits.com/beta_signups/signup). Be sure to mention in your application that you are an app developer and planning to add 1Password support. 

Beta enrollment is a manual process so please allow a bit of time to hear back from us.


### Step 3: Run the Sample App

Before jumping into the code and wiring up your own app, let's ensure everything is setup correctly by running the sample ACME Browser app. 

Open `1Password Extension Demo iOS/1Password Extension Demo for iOS.xcodeproj` within XCode 6,and then select the `ACME Browser` target and set it to run your iOS device:

![](https://www.evernote.com/shard/s2/sh/0af10ef5-9926-4e63-a56c-152d45199cac/eaccf42b0298da5ae074997b3c3ac1ad/deep/0/Menubar-and-SignInViewController.m-and-main.m.png)

Since you will not have 1Password running within your iOS Simulator, it is important that you run on your device.

If all goes well, ACME Browser will launch and you'll be able to test the 1Password Extension features.

<!--- TODO: quick video here -->


## Integrating 1Password With Your App

Now let's open the hood and get our hands dirty so we can see how to add 1Password to your app. 

Be forewarned, however, that there is not much code to get dirty with. If you were looking for an SDK to waste days of your life on, you'll be sorely disappointed.


### Add 1Password Files to Your Project

Drag the Resources folder into your project.


### Scenario 1: Signin

Here we'll learn how to enable your existing users to fill their credentials into your signin form using 1Password. The workflow will look something like this:

![](http://i.agilebits.com/dt/IMG_0611_197C6912.png)
![](http://i.agilebits.com/dt/IMG_0612_197C68C2.png)
![](http://i.agilebits.com/dt/IMG_0613_197C693F.png)
![](http://i.agilebits.com/dt/IMG_0614_197C696B.png)

Here's how you can add the 1Password Signin workflow to your app:

#### 1. Add a 1Password Lookup Button

The first thing you'll need to do is add a UIButton to your signin page. Use an existing image from the `Resources/Images` folder.

One caveat to adding the button is you'll need to hide it if 1Password is not installed. Determining if the 1Password extension is available is a simple matter of asking UIApplication if it's capable of opening a custom URL Scheme: 

```
- (BOOL)is1PasswordExtensionAvailable {
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"onepassword-extension://fill"]];
}
```

Using this code you can hide the 1Password UIButton when 1Password is not installed. You can see the code for this in the `[SignInViewController viewWillAppear:]` method:

```
-(void)viewWillAppear:(BOOL)animated {
	[self.onepasswordSigninButton setHidden:![self is1PasswordExtensionAvailable]];
}
```

#### 2. Set the 1Password Button's Action

Wire up your 1Password Button to call the the button to an IBAction similar to this:

```
- (IBAction)findLoginFrom1Password:(id)sender {
	NSDictionary *item = @{ OPLoginURLStringKey : @"https://www.acmebrowser.com" }; 
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionFindLoginAction];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		// Process Result
	};

	[self presentViewController:controller animated:YES completion:nil];
}
```

This code creates an NSItemProvider and specifies that it wants to find an existing login within 1Password by specifying the `kUTTypeNSExtensionFindLoginAction` type identifier. To help the user quickly find the login they need, we pass in a URL string that our service is using. For example, if your app required a Twitter login, you would pass in @"https://twitter.com" for the `OPLoginURLStringKey`.

We then create an `UIActivityViewController`, initialize it with our `NSExtensionItem`, and then ask iOS to present the share sheet view controller.

#### 3. Wait

At this point, there is nothing for you to do but wait. The user will be presented with the share sheet and will need to select the 1Password extension. If it is the first time using the 1Password extension they will need to enable it by tapping the More button.

Once the user selects 1Password, a list of saved logins for your app will be shown (this is why it's so important for you to specify a good `OPLoginURLStringKey`) and the user will be able to select one. 

Once an item is selected, control will return to your `UIActivityViewController`'s  `completionWithItemsHandler`.

#### 4. Process the 1Password Result

Here's an example completion handler for your `UIActivityViewController`:

```
controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
	if (completed) {
		__strong typeof(self) strongSelf = weakSelf;
		for (NSExtensionItem *extensionItem in returnedItems) {
			[strongSelf processExtensionItem:extensionItem];
		}
	}
}
```

Apple's design makes it possible to return multiple `NSExtensionItem`, so we loop over all of them and process them in turn, calling the `processExtensionItem`:

```
- (void)processExtensionItem:(NSExtensionItem *)extensionItem {
	for (NSItemProvider *itemProvider in extensionItem.attachments) {
		[self processItemProvider:itemProvider];
	}
}
```

As you can see, each extension item is allowed to have multiple attachments, so we once again loop over each of them in turn, passing them into `processItemProvider`:

```
- (void)processItemProvider:(NSItemProvider *)itemProvider {
	if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		__weak typeof (self) miniMe = self;
		[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *login, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				__strong typeof(self) strongMe = miniMe;
				strongMe.usernameTextField.text = item[OPLoginUsernameKey];
				strongMe.passwordTextField.text = item[OPLoginPasswordKey];
			});
		}];
	}
}
```

Once we're done unwinding the multiple `NSExtensionItem`s and `NSItemProvider`s, we can find the data sent to use by 1Password within the `login` dictionary. This dictionary contains the keys `OPLoginUsernameKey` and `OPLoginPasswordKey` for the username and password values, respectively.

Extract the username and password values and update your UI accordingly.


### Scenario 2: New User Signup

Allow your users to generate strong, unique passwords when signing up to your service. 

Adding 1Password to your Signup Screen is very similar to adding 1Password to your Login Screen. The only difference is how you create the `NSExtensionItem` and `NSItemProvider`:

```
NSDictionary *item = @{
	OPLoginURLStringKey : @"https://www.acmebrowser.com",
	OPLoginTitleKey : @"ACME Browser",
	OPLoginUsernameKey : self.usernameTextField.text ? : @"",
	OPLoginPasswordKey : self.passwordTextField.text ? : @"",
	OPLoginNotesKey : @"Saved with the ACME app",
	OPLoginSectionTitleKey : @"User Details",
	OPLoginFieldsKey : @{
			@"firstname" : self.firstnameTextField.text ? : @"",
			@"lastname" : self.lastnameTextField.text ? : @""
	}
};

NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionSaveLoginAction];

NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
extensionItem.attachments = @[ itemProvider ];

UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
controller.completionWithItemsHandler = ...
[self presentViewController:controller animated:YES completion:nil];
```

First, you'll notice that we're passing in all the information the user entered to 1Password. This is because at the end of the password generation process, 1Password will create a brand new login and save it. It's not possible for 1Password to ask your app for this data later, so we pass in everything we can before showing the password generator screen.

Second, you'll notice we're using a new `kUTTypeNSExtensionSaveLoginAction` type identifier. This instructs 1Password that we're in a Save Login scenario. 

An important thing to notice is the `OPLoginURLStringKey` is set to the exact same value we used in the Signin scenario. This allows users to quickly find the login they saved for your app the next time they need to sign in.


### Scenario 3: Web View Support

The 1Password Extension is not limited to filling native UIs. With just a little bit of extra code, you can fill `UIWebView`s and `WKWebView`s as well.

#### Inspiration From Apple

We will not be creating a Safari Extension in this project, but the approach we used was heavily influenced by the implementation Apple used for Safari Extensions.

To enable interaction between an extension and the HTML page within Safari on iOS, Apple defined an extension preprocessing JavaScript protocol called ExtensionPreprocessingJS. By default the file is named `ExtensionPreprocessing.js` and it has these two methods:

```
ExtensionPreprocessingJS.prototype.run
ExtensionPreprocessingJS.prototype.finalize
```

The run method is run before calling the extension, giving you a chance to collect all the information you need from the window. Your extension works with this data and then sends Safari back a result, which is passed into the finalize method. 

Since the run and finalize methods are both running within the context of the page, your extension has the aboility to collect all the information it needs about the window, and modify the DOM accordingly.

The 1Password Safari Extension makes great use of the ExtensionPreprocessingJS design, and we'll need you to call our scripts at the appropriate times in order to integrate with your web views.

#### Step 1: Collect Page Information

Before invoking 1Password, collect information about the page by executing a piece of JavaScript within your web view:

```
- (IBAction)fillUsing1Password:(id)sender {
	NSString *collectPageInfoScript = [self loadUserScriptSourceNamed:@"collect"];
	[self.webView evaluateJavaScript:collectPageInfoScript completionHandler:^(NSString *result, NSError *error) {
		if (result) {
			[self findLoginIn1PasswordWithPageDetails:result];
		}
	}];
```

This code loads some JavaScript and asks our `WKWebView` to evaluate it and pass the results into our completion handler. If you are still using a UIWebView, you can use `stringByEvaluatingJavaScriptFromString:` instead. 

The collect fields script will return a simple NSString that you'll treat as an opaque token and pass it into the next step.

#### Step 2: Loading the 1Password Extension

Once the page information is collected, you can pass it into the 1Password Extension as follows:

```
- (void)findLoginIn1PasswordForURLString:(NSString *)URLString collectedPageDetails:(NSString *)collectedPageDetails {
	NSDictionary *item = @{ OPWebViewPageDetails: collectedPageDetails};
	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeNSExtensionFillWebViewAction];
	
	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];
	
	__weak typeof (self) miniMe = self;
	
	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];
	controller.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (!completed) {
			__strong typeof(self) strongMe = miniMe;
			for (NSExtensionItem *extensionItem in returnedItems) {
				[strongMe processExtensionItem:extensionItem];
			}
		}
	};
	
	[self presentViewController:controller animated:YES completion:nil];
}
```

This code should look very familiar as it's almost identical to what we did in the previous examples. The only real differences are we use the `kUTTypeNSExtensionFillWebViewAction` type identifier for our item provider, and we pass in the `OPWebViewPageDetails` dictionary instead of a simple `OPLoginURLStringKey`.

#### Step 3: Execute Fill Script

Once the user selects an item to fill, your completion handler will receive a JSON string defining how filling should take place. You once again have to do the dance of unraveling the multiple NSExtensionItems and NSItemProvider attachments, but you'll eventually find a provider that contains the information you need:

```
[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *item, NSError *error) {
	__weak typeof (self) miniMe = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		if (item) {
			NSString *fillScript = item[OPWebViewPageFillScript];
			[miniMe executeFillScript:fillScript];
		}
	});
}];
```

You can now pass the `fillScript` string into a JavaScript function that will handle all the filling for you:

```
- (void)executeFillScript:(NSString *)fillScript {
	NSMutableString *scriptSource = [[self loadUserScriptSourceNamed:@"fill"] mutableCopy];
	[scriptSource appendFormat:@"('%@');", fillScript];
	[self.webView evaluateJavaScript:scriptSource completionHandler:NULL];
}
```

The JavaScript source from the `fill.js` script library will parse the data returned by 1Password and fill all the fields that matched.


## Best Practices

* Ensure your URL is set to your actual service so your users can easily find their logins within the main 1Password app
* Use our provided icons so users are familiar with what it will do. Contact us if you'd like additional sizes or have other special requirements 
* Enable users to set 1Password as their default browser for external web links.


## Known Issues

* Web pages never finish loading when the debugger is attached. After installing an updated app, you need to kill the process from XCode and then restart ACME Browser directly from your device.
* You can only invoke the 1Password extension once per app launch. Subsequent calls to [UIActivityViewController presentViewController], will always have a nil `returnedItems` in the completion handler. radar://17669995


## References 

Apple Extension Guide
NSItemProvider, NSExtensionItem, UIActivityViewController class references.


## Contact Us

Contact us, please! We'd love to hear from you about how you integrated 1Password with you app, and how we can improve it further. 

You can reach us at support+opxdemo@agilebits.com, or if you prefer, [@1PasswordBeta](https://twitter.com/1PasswordBeta) on Twitter.

