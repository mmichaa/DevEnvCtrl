//
//  AppServiceData.h
//  DevEnvToggle
//
//  Created by Michael Nowak on 17.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/SecKeychain.h>

@interface AppServiceData : NSObject

@property NSDictionary *data;

- (id)initFromDictionary:(NSDictionary *)dictionary;

- (NSString *)label;
- (NSString *)job;
- (NSString *)path;
- (NSURL *)pathAsURL;
- (NSString *)plistPath;
- (NSURL *)plistPathAsURL;

-(NSDictionary *)diskimage;
-(NSString *)diskimageLabel;
-(NSString *)diskimagePath;
-(NSString *)diskimageBasename;
-(NSArray *)diskimageAttachOptions;
-(BOOL)diskimageAttachOptionsWithEncryption;
-(BOOL)diskimageAttach;
-(BOOL)diskimageDetach;

@end
