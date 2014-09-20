//
//  LoginInformation.h
//  App Demo for iOS
//
//  Created by Rad on 2014-08-11.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginInformation : NSObject

@property (nonatomic, strong) NSString *username;

+ (LoginInformation *)sharedLoginInformation;

@end
