//
//  ACMEUITests.m
//  ACMEUITests
//
//  Created by Rad Azzouz on 2015-08-18.
//  Copyright © 2015 AgileBits. All rights reserved.
//

#import <XCTest/XCTest.h>

#define __WAIT__ [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3]];

@interface ACMEUITests : XCTestCase

@end

/*!
 You need to have 1Password installed on your test device with the following configuration:
 
 Security setting:
 "Lock On Exit" enabled and the PIN Code should be "1111"
 
 Required Items:
 Make sure that you have no matching Logins in your vault for "acme.com"
 
 Tests must me executed in order.
 */
@implementation ACMEUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1StoreLogin {
	[XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
	
	XCUIApplication *app = [[XCUIApplication alloc] init];
	[app.buttons[@"Sign up"] tap];
	
	XCUIElement *firstNameTextField = app.textFields[@"First Name"];
	[firstNameTextField tap];
	[app.textFields[@"First Name"] typeText:@"Rad"];
	
	XCUIElement *lastNameTextField = app.textFields[@"Last Name"];
	[lastNameTextField tap];
	[lastNameTextField typeText:@"Azzouz"];
	
	XCUIElement *usernameTextField = app.textFields[@"Username"];
	[usernameTextField tap];
	[usernameTextField typeText:@"radazzouz"];
	
	XCUIElement *passwordSecureTextField = app.secureTextFields[@"Password"];
	[passwordSecureTextField tap];
	[passwordSecureTextField typeText:@"1234"];
	[app.buttons[@"onepassword button"] tap];
	[app.sheets.collectionViews.collectionViews.buttons[@"1Password"] tap];
	
	XCUIElement *button = app.buttons[@"1."];
	[button tap];
	[button tap];
	[button tap];
	[button tap];
	
	__WAIT__
	
	XCUIElementQuery *elementsQuery = app.scrollViews.otherElements;
	[elementsQuery.textFields[@"Username or email"] tap];
	[elementsQuery.buttons[@"Generate New Password"] tap];
	[app.navigationBars[@"1Password"].buttons[@"Save"] tap];
	
	__WAIT__

	NSString *newPassword = passwordSecureTextField.value;
	XCTAssertTrue(NO == [@"1234" isEqualToString:newPassword], @"Passwords should be different.");
}

- (void)test2ChangePassword {
	XCUIApplication *app = [[XCUIApplication alloc] init];
	[app.buttons[@"Sign in"] tap];
	[app.buttons[@"Change Password"] tap];
	[app.buttons[@"onepassword button"] tap];
	[app.sheets.collectionViews.collectionViews.buttons[@"1Password"] tap];
	
	XCUIElement *button = app.buttons[@"1."];
	[button tap];
	[button tap];
	[button tap];
	[button tap];

	__WAIT__
	
	[app.tables.buttons[@"Generate New Password"] tap];
	[app.navigationBars[@"OPItemDetailView"].buttons[@"Done"] tap];

	__WAIT__

	NSString *oldPassword = app.secureTextFields[@"Old Password"].value;
	NSString *newPassword = app.secureTextFields[@"New Password"].value;
	NSString *confirmPassword = app.secureTextFields[@"Confirm Password"].value;
	
	XCTAssertTrue(oldPassword.length > 0, @"A valid old username is required.");
	XCTAssertTrue(newPassword.length > 0, @"A valid new password is required.");
	XCTAssertTrue(confirmPassword.length > 0, @"A valid confirmation password is required.");
	
	// This would've been a good test case, but since the old, new and the confirm passwords are all "••••••••••••••••••••••••••••••", we can not use it.
	// XCTAssertTrue(NO == [oldPassword isEqualToString:newPassword], @"Passwords should be different.");
}

- (void)test3FindLogin {
	XCUIApplication *app = [[XCUIApplication alloc] init];
	[app.buttons[@"onepassword button"] tap];
	[app.sheets.collectionViews.collectionViews.buttons[@"1Password"] tap];
	
	XCUIElement *button = app.buttons[@"1."];
	[button tap];
	[button tap];
	[button tap];
	[button tap];
	
	__WAIT__

	[app.tables.staticTexts[@"ACME"] tap];
	
	__WAIT__

	NSString *username = app.textFields[@"Username or email"].value;
	NSString *password = app.secureTextFields[@"Password"].value;
	
	XCTAssertTrue(username.length > 0, @"A valid username is required.");
	XCTAssertTrue(password.length > 0, @"A valid password is required.");
}

@end
