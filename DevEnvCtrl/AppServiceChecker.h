//
//  AppServiceChecker.h
//  DevEnvCtrl
//
//  Created by Michael Nowak on 28.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <Security/SecCertificate.h>
#import <Security/SecCode.h>
#import <Security/SecStaticCode.h>
#import <Security/SecCodeHost.h>
#import <Security/SecRequirement.h>

@interface AppServiceChecker : NSObject

+ (NSDictionary *)serviceHelperJobDictionary;
+ (NSURL *)installedHelperURL;
+ (NSDictionary *)installedHelperInfoDictionary;
+ (NSURL *)currentHelperURL;
+ (NSDictionary *)currentHelperInfoDictionary;

+ (BOOL)checkCodeValidity;
+ (BOOL)checkVersionValidity;

@end
