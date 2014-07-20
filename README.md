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

Now let's get our hands dirty, open the hood, and see how to add 1Password into your app. 

Be forewarned, however, that there is not much code to get dirty with. If you were looking for an SDK to waste days of your life on, you'll be sorely disappointed.


### Add 1Password Files to Your Project

Drag the Resources folder into your project


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



2. Wire the button to an IBaction similar to this. 
3. Create an Item Provider by providing the required info. This will instruct iOS to open the Share Sheet. (detail how to hide the other apps so just the actions show)
4. Create an Item Provider callback as follows:
5. Extract the username and password and insert them into your UITextField-s.

Note: if you are using a Web View to authorize users (for example, OAuth), you will want to follow the steps in _Scenario 3_ to integrate with Web Views.

### Scenario 2: New User Signup

Allow your users to generate strong, unique passwords when signing up to your service. 

0. Determine if 1Password is installed.
1. Add a UIButton to your view. Use an existing image from the Resources/Images folder.
2. Wire the button to an IBaction similar to this. 
3. Create an Item Provider by providing the required info. This will instruct iOS to open the Share Sheet. (detail how to hide the other apps so just the actions show)
4. Create an Item Provider callback as follows:
5. Extract the password and insert them into your UITextField-s.

### Scenario 3: Web View Support

Inspired by Apple's Safari Extension architecture. 

0. Determine if 1Password is installed.

Steps to integrate.


## Best Practices

* Ensure your URL is set to your actual service so your users can easily find their logins within the main 1Password app
* Use our provided icons so users are familiar with what it will do. Contact us if you'd like additional sizes or have other special requirements 
* Enable users to set 1Password as their default browser for external web links.

## Contact Us

Contact us, please! We'd love to hear from you about how you integrated 1Password with you app, and how we can improve it further. 

You can reach us at support+opxdemo@agilebits.com, or if you prefer, [@1PasswordBeta](https://twitter.com/1PasswordBeta) on Twitter.

