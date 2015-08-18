//
//  ACMEUITests.m
//  ACMEUITests
//
//  Created by Rad Azzouz on 2015-08-18.
//  Copyright © 2015 AgileBits. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ACMEUITests : XCTestCase

@end

/*!
 Note that you need to have 1Password installed on your test device with the following configuration:
 
 Security setting:
 "Lock On Exit" enabled and the PIN Code should be "1111"
 
 Required Items:
 Make sure that you have a Login item  in your vault with named "ACME - Test" and make sure that its username and password are valid (non-empty strings)
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

- (void)testStoreLogin {
	// Use recording to get started writing UI tests.
	// Use XCTAssert and related functions to verify your tests produce the correct results.
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
	
	XCUIElementQuery *elementsQuery = app.scrollViews.otherElements;
	[elementsQuery.textFields[@"Username or email"] tap];
	[elementsQuery.buttons[@"Generate New Password"] tap];
	[app.navigationBars[@"1Password"].buttons[@"Save"] tap];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSString *newPassword = passwordSecureTextField.value;
		XCTAssertTrue(NO == [@"1234" isEqualToString:newPassword], @"Passwords should be different.");
	});
}

- (void)testChangePassword {
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

	[app.tables.buttons[@"Generate New Password"] tap];
	[app.navigationBars[@"OPItemDetailView"].buttons[@"Done"] tap];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSString *oldPassword = app.secureTextFields[@"Old Password"].value;
		NSString *newPassword = app.secureTextFields[@"New Password"].value;
		
		XCTAssertTrue(NO == [oldPassword isEqualToString:newPassword], @"Passwords should be different.");
	});
}

- (void)testFindLogin {
	XCUIApplication *app = [[XCUIApplication alloc] init];
	[app.buttons[@"onepassword button"] tap];
	[app.sheets.collectionViews.collectionViews.buttons[@"1Password"] tap];
	
	XCUIElement *button = app.buttons[@"1."];
	[button tap];
	[button tap];
	[button tap];
	[button tap];
	[app.tables.staticTexts[@"ACME - Test"] tap];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSString *username = app.textFields[@"Username or email"].value;
		NSString *password = app.secureTextFields[@"Password"].value;
		
		XCTAssertTrue(username.length > 0, @"A valid username is required.");
		XCTAssertTrue(password.length > 0, @"A valid password is required.");
	});
}

@end
