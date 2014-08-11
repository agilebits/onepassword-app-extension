//
//  LoginInformation.m
//  App Demo for iOS
//
//  Created by Rad on 2014-08-11.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "LoginInformation.h"

@implementation LoginInformation

static LoginInformation *__sharedLoginInformation = nil;

+ (LoginInformation *)sharedLoginInformation {
	if (!__sharedLoginInformation) {
		__sharedLoginInformation = [[LoginInformation alloc] init];
	}
	return __sharedLoginInformation;
}

- (instancetype)init {
	if (self = [super init]) {
		self.username = @"";
	}
	return self;
}

@end
