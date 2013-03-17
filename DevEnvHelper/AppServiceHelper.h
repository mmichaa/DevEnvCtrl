//
//  AppServiceHelper.h
//  DevEnvToggle
//
//  Created by Michael Nowak on 17.03.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppServiceHelper : NSObject

- (BOOL)status:(NSString *)job;
- (BOOL)start:(NSString *)job;
- (BOOL)stop:(NSString *)job;

@end
