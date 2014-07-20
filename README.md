# 1Password App Extension

Welcome! With just a few lines of code, your app can add 1Password support, enabling your users to:

1. Access their 1Password Logins to automatically fill your signin page
2. Use the Strong Password Generator to create unique passwords during registration
3. Quickly fill 1Password Logins directly into web views

Strong, unique passwords for all websites and every app is critical to everyone's security, for both users and companies. With direct 1Password integration, we can encourage all our users to avoid shortcuts, stay secure, and make the world a better place.


## Getting Started

Adding 1Password support to your app is easy. To demonstrate how it works, we have a sample app for iOS that showcases all of these 1Password features.


### Step 1: Download the Demo Project

To get started, download the 1Password Extension Demo project from https://github.com/AgileBits/opxdemo/archive/master.zip, or simply clone it.

Inside the downloaded folder, you'll find the `1Password Extension Demo for iOS` project. This project contains a sample ACME Browser app that integrates all of the 1Password features. 


### Step 2: Install the Latest 1Password & XCode Betas

The sample projects both depend upon having the latest 1Password Beta installed. 

If you are developing for OS X, you can enable betas within the 1Password > Preferences > Updates window (as shown [here](i.agilebits.com/Preferences_197C0C6B.png)) and enabling the _Include beta builds_ checkbox. Mac App Store users should [download the webstore version](https://agilebits.com/downloads) in order to enable betas.

If you are developing for iOS, please [enroll in the 1Password for iOS Beta program](https://agilebits.com/beta_signups/signup). Be sure to mention in the comments that you are an app developer and planning to add 1Password support.

You will also need the latest version of XCode 6. 

### Step 3: Run the Sample App

Before jumping into the code, let's ensure everything is setup correctly by running the sample ACME  Browser app. 

- Open the xxxxxx.xcodeproj, 
- Screenshot the run target, plus device
- Remind people again that it must be the device
- Video


## Adding 1Password to Your App

### Add 1Password Files to Your Project

Drag the Resources folder into your project

### Scenario 1: Signin

Allow existing users to fill their credentials into your signin form. 

0. Determine if 1Password is installed.
1. Add a UIButton to your view. Use an existing image from the Resources/Images folder.
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

