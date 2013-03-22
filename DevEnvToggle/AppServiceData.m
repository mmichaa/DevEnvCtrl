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

- (id)initFromDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    [self setData:dictionary];
    return self;
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
    NSArray *pathComponents = [NSArray arrayWithObjects:[self path], @"/", [self job], @".plist", nil];
    return [pathComponents componentsJoinedByString:@""];
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

-(NSString *)diskimageLabel
{
    NSDictionary *diskimage = [self diskimage];
    if (diskimage) {
        return [diskimage valueForKey:@"label"];
    } else {
        return nil;
    }
}

-(NSString *)diskimagePath
{
    NSDictionary *diskimage = [self diskimage];
    if (diskimage) {
        return [diskimage valueForKey:@"path"];
    } else {
        return nil;
    }
}

-(NSString *)diskimageBasename
{
    NSString *path = [self diskimagePath];
    if (path) {
        return [[NSURL fileURLWithPath:[self diskimagePath] isDirectory:false] lastPathComponent];
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
    SecKeychainRef *keychain = nil;
    SecKeychainCopyDefault(keychain);
    NSString *pass = nil;
    NSString *serviceName = [self diskimageBasename];
    UInt32 passLen = 0;
    void *passData = nil;
    OSStatus error = SecKeychainFindGenericPassword(keychain, (UInt32)[serviceName length], [serviceName cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, &passLen, &passData, NULL);
    if (error == noErr) {
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
        [[self diskimage] setValue:disk forKey:@"disk"];
        return true;
    } else {
        return false;
    }
}

-(BOOL)diskimageDetach
{
    NSTask *task = [NSTask new];
    NSMutableArray *args = [NSMutableArray arrayWithObjects:@"detach", nil];
    [args addObject:[[self diskimage] valueForKey:@"disk"]];
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
