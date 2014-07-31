//
//  AppDelegate.m
//  WebView filling for iOS
//
//  Created by Rad on 2014-07-21.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "AppDelegate.h"
#import "OnePasswordExtension.h"

#import <MessageUI/MFMailComposeViewController.h>

@interface AppDelegate () <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"1Password Beta is not installed" message:@"Email support+appex@agilebits.com for beta access" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Email", nil];
		[alertView show];
	}

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == alertView.firstOtherButtonIndex) {
		MFMailComposeViewController* composeViewController = [[MFMailComposeViewController alloc] init];
		composeViewController.mailComposeDelegate = self;
		[composeViewController setToRecipients:@[ @"support+appex@agilebits.com" ]];
		[composeViewController setSubject:@"App Extension"];

		UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
		UIViewController *rootViewController = window.rootViewController;
		[rootViewController presentViewController:composeViewController animated:YES completion:nil];
	}
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[controller dismissViewControllerAnimated:YES completion:nil];
}

@end
