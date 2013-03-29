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
@property NSMutableDictionary *cache;

+ (NSArray *)serviceDataFiles:(NSString *)directory;
+ (BOOL)serviceDataInstall:(NSString *)directory;

+ (id)serviceDataWithDictionary:(NSDictionary *)dictionary;
+ (id)serviceDataWithContentsOfFile:(NSString *)path;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (id)initWithContentsOfFile:(NSString *)path;

- (NSString *)label;
- (NSString *)job;
- (NSString *)path;
- (NSURL *)pathAsURL;
- (NSString *)plistPath;
- (NSURL *)plistPathAsURL;
- (BOOL)plistPathExsists;

-(NSDictionary *)diskimage;
-(NSString *)diskimagePath;
-(NSString *)diskimageBasename;
-(NSArray *)diskimageAttachOptions;
-(NSString *)diskimageUUID;
-(BOOL)diskimageAttachOptionsWithEncryption;
-(BOOL)diskimageAttach;
-(BOOL)diskimageDetach;

@end
