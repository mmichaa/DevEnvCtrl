//
//  AppServiceData_Tests.m
//  DevEnvCtrl
//
//  Created by Michael Nowak on 16.11.13.
//  Copyright (c) 2013 Michael Nowak. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "AppServiceData.h"

@interface AppServiceData_Tests : SenTestCase
{
    AppServiceData *subject;
}
@end

@implementation AppServiceData_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 
    [super tearDown];
}

- (void)testExample
{
    STAssertTrue(TRUE, @"WTF");
}

- (void)testPlistPath
{
    NSDictionary *dict;
    
    dict = @{@"path": @"~/Library/LaunchAgents", @"job": @"com.example.foobar"};
    subject = [AppServiceData serviceDataWithDictionary:dict];
    STAssertEqualObjects([subject plistPath], [@"~/Library/LaunchAgents/com.example.foobar.plist" stringByExpandingTildeInPath],
                         @"expcted to be build as expanded path + / + job + .plist");
}

- (void)testContextUser
{
    NSDictionary *dict;

    dict = @{@"path": @"~/Library/LaunchAgents"};
    subject = [AppServiceData serviceDataWithDictionary:dict];
    STAssertTrue([subject contextUser],
                 @"expected to be true for pathes starting with ~/");

    dict = @{@"path": @"/Library/LaunchAgents"};
    subject = [AppServiceData serviceDataWithDictionary:dict];
    STAssertFalse([subject contextUser],
                 @"expected to be false for pathes not starting with ~/");
}

- (void)testContextRoot
{
    NSDictionary *dict;
    
    dict = @{@"path": @"~/Library/LaunchAgents"};
    subject = [AppServiceData serviceDataWithDictionary:dict];
    STAssertFalse([subject contextRoot],
                 @"expected to be false for pathes starting with ~/");
    
    dict = @{@"path": @"/Library/LaunchAgents"};
    subject = [AppServiceData serviceDataWithDictionary:dict];
    STAssertTrue([subject contextRoot],
                  @"expected to be true for pathes not starting with ~/");
}

@end
