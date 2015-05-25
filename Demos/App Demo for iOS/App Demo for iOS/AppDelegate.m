//
//  AppDelegate.m
//  1Password Extension Demo
//
//  Created by Rad Azzouz on 2014-07-14.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "AppDelegate.h"
#import <OnePasswordExtension/OnePasswordExtension.h>

@interface AppDelegate () <UIAlertViewDelegate>

@end

@implementation AppDelegate
            

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (NO == [[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"1Password is not installed" message:@"Get 1Password from the App Store" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Get 1Password", nil];
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
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/ca/app/1password-password-manager/id568903335?mt=8"]];
	}
}

@end
