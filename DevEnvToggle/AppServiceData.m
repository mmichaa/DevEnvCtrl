//
//  AppServiceData.m
//  DevEnvToggle
//
//  Created by Michael Nowak on 17.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import "AppServiceData.h"

@implementation AppServiceData

@synthesize data;
@synthesize cache;

+ (NSArray *)serviceDataFiles:(NSString *)directory
{
    NSError *error;
    NSArray *directoryEntries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
    NSMutableArray *serviceFiles = [NSMutableArray arrayWithCapacity:[directoryEntries count]];
    for (NSString *serviceFile in directoryEntries) {
        if ([[serviceFile pathExtension] isEqual: @"plist"]) {
            [serviceFiles addObject:[directory stringByAppendingPathComponent:serviceFile]];
        }
    }
    return serviceFiles;
}

+ (NSArray *)serviceDataInstall:(NSString *)directory
{
    NSError *error = nil;
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *plists = [bundle pathsForResourcesOfType:@"plist" inDirectory:nil];
    NSMutableArray *serviceFiles = [NSMutableArray arrayWithCapacity:[plists count]];
    for (NSString *source in plists) {
        NSString *destination = [directory stringByAppendingPathComponent:[source lastPathComponent]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:destination]) {
            [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:&error];
            if (error == nil) {
                [serviceFiles addObject:destination];
            }
        }
    }
    return serviceFiles;
}

+ (id)serviceDataWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

+ (id)serviceDataWithContentsOfFile:(NSString *)path
{
    return [[self alloc] initWithContentsOfFile:path];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        data = dictionary;
        cache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    return [self initWithDictionary:dictionary];
}

- (NSString *)label
{
    return [data valueForKey:@"label"];
}

- (NSString *)job
{
    return [data valueForKey:@"job"];
}

- (NSString *)path
{
    return [data valueForKey:@"path"];
}

- (NSURL *)pathAsURL
{
    return [NSURL fileURLWithPath:[self path] isDirectory:true];
}

- (NSString *)plistPath
{
    NSString *path = [cache valueForKey:@"plistPath"];
    if (path == nil) {
        NSArray *pathComponents = [NSArray arrayWithObjects:[self path], @"/", [self job], @".plist", nil];
        path = [pathComponents componentsJoinedByString:@""];
        [cache setValue:path forKey:@"plistPath"];
    }
    return path;
}

- (NSURL *)plistPathAsURL
{
    return [NSURL fileURLWithPath:[self plistPath] isDirectory:false];
}

- (BOOL)plistPathExsists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self plistPath]];
}

-(NSDictionary *)diskimage
{
    return [data valueForKey:@"diskimage"];
}

-(NSString *)diskimagePath
{
    NSDictionary *diskimage = [self diskimage];
    if (diskimage) {
        NSString *path = [cache valueForKey:@"diskimagePath"];
        if (path == nil) {
            path = [diskimage valueForKey:@"path"];
            if ([[path substringToIndex:1] isEqual:@"~"]) {
                path = [path stringByExpandingTildeInPath];
            }
            [cache setValue:path forKey:@"diskimagePath"];
        }
        return path;
    } else {
        return nil;
    }
}

-(NSString *)diskimageBasename
{
    NSString *path = [self diskimagePath];
    if (path) {
        NSString *basename = [cache valueForKey:@"diskimageBasename"];
        if (basename == nil) {
            basename = [[NSURL fileURLWithPath:[self diskimagePath] isDirectory:false] lastPathComponent];
            [cache setValue:basename forKey:@"diskimageBasename"];
        }
        return basename;
    } else {
        return nil;
    }
}

-(NSArray *)diskimageAttachOptions
{
    NSDictionary *diskimage = [self diskimage];
    if (diskimage) {
        return [diskimage valueForKey:@"options"];
    } else {
        return nil;
    }
}

-(NSString *)diskimageUUID
{
    NSDictionary *diskimage = [self diskimage];
    if (diskimage) {
        NSString *uuid = [cache valueForKey:@"diskimageUUID"];
        if (uuid == nil) {
            NSArray *args = [NSArray arrayWithObjects:@"isencrypted", @"-plist", [self diskimagePath], nil];
            NSTask *task = [NSTask new];
            NSPipe *pipeOut =[NSPipe pipe];
            [task setLaunchPath:@"/usr/bin/hdiutil"];
            [task setArguments:args];
            [task setStandardOutput:pipeOut];
            [task launch];
            NSFileHandle *output = [pipeOut fileHandleForReading];
            [task waitUntilExit];
            if ([task terminationStatus] == 0) {
                NSData *outData = [output readDataToEndOfFile];
                NSString *error;
                NSPropertyListFormat format;
                NSDictionary *outDict = [NSPropertyListSerialization propertyListFromData:outData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
                uuid = [outDict valueForKey:@"uuid"];
            } else {
                return nil;
            }
        }
        return uuid;
    } else {
        return nil;
    }
}

-(BOOL)diskimageAttachOptionsWithEncryption
{
    NSArray *options = [self diskimageAttachOptions];
    if (options) {
        if ([options indexOfObject:@"-encryption"] == NSNotFound) {
            return false;
        } else {
            return true;
        }
    } else {
        return false;
    }
}

-(NSString *)diskimageAttachEncryptionPassword
{
    NSString *pass = nil;
    NSString *serviceName = [self diskimageBasename];
    NSString *accountName = [self diskimageUUID];
    UInt32 passLen = 0;
    void *passData = nil;
    OSStatus error;
    error = SecKeychainUnlock(NULL, 0, NULL, FALSE);
    error = SecKeychainFindGenericPassword(NULL, (UInt32)[serviceName lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [serviceName UTF8String], (UInt32)[accountName lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [accountName UTF8String], &passLen, &passData, NULL);
    if (error == errSecSuccess) {
        pass = [[NSString alloc] initWithBytes:passData length:passLen encoding:NSUTF8StringEncoding];
        SecKeychainItemFreeContent(NULL, passData);
    }
    return pass;
}

-(BOOL)diskimageAttach
{
    NSArray *options = [self diskimageAttachOptions];
    NSString *pass = nil;
    NSMutableArray *args = [NSMutableArray arrayWithObjects:@"attach", nil];
    if (options) {
        [args addObjectsFromArray:options];
        if ([self diskimageAttachOptionsWithEncryption]) {
            pass = [self diskimageAttachEncryptionPassword];
            if (pass == nil) {
                return false;
            }
        }
    }
    [args addObject:[self diskimagePath]];
    NSTask *task = [NSTask new];
    NSPipe *pipeIn =[NSPipe pipe];
    NSPipe *pipeOut =[NSPipe pipe];
    [task setLaunchPath:@"/usr/bin/hdiutil"];
    [task setArguments:args];
    [task setStandardInput:pipeIn];
    [task setStandardOutput:pipeOut];
    [task launch];
    NSFileHandle *input = [pipeIn fileHandleForWriting];
    NSFileHandle *output = [pipeOut fileHandleForReading];
    if (pass) {
        NSData *passData = [pass dataUsingEncoding:NSUTF8StringEncoding];
        [input writeData:passData];
        NSData *nullData = [@"\0" dataUsingEncoding:NSUTF8StringEncoding];
        [input writeData:nullData];
    }
    [task waitUntilExit];
    if ([task terminationStatus] == 0) {
        NSData *outData = [output readDataOfLength:32];
        NSString *outString = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
        NSString *disk = [[outString componentsSeparatedByString:@" "] objectAtIndex:0];
        [cache setValue:disk forKey:@"disk"];
        return true;
    } else {
        return false;
    }
}

-(BOOL)diskimageDetach
{
    NSString *disk = [cache valueForKey:@"disk"];
    if (disk == nil) {
        if ([self diskimageAttach]) {
            disk = [cache valueForKey:@"disk"]; 
        } else {
            return false;
        }
    }
    NSTask *task = [NSTask new];
    NSArray *args = [NSArray arrayWithObjects:@"detach", disk, nil];
    [task setLaunchPath:@"/usr/bin/hdiutil"];
    [task setArguments:args];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] == 0) {
        return true;
    } else {
        return false;
    }
}

@end
