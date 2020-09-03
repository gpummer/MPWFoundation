//
//  AppDelegate.m
//  TestMPWFoundation
//
//  Created by Marcel Weiher on 12/7/16.
//
//

#import "ViewBuilderAppDelegate.h"
#import <Foundation/Foundation.h>
#import <MPWTest/MPWTestSuite.h>
#import <MPWTest/MPWLoggingTester.h>
#import <MPWTest/MPWClassMirror.h>

@interface ViewBuilderAppDelegate ()

@end

@implementation ViewBuilderAppDelegate


int runTests( NSArray *testSuiteNames , NSArray *testTypeNames,  BOOL verbose ,BOOL veryVerbose ) {
    NSLog(@"will run tests");
    MPWTestSuite* test;
    MPWLoggingTester* results;
    int exitCode=0;
    
    NSString *testListPath=[[NSBundle mainBundle] pathForResource:@"ClassesToTest"
                                                           ofType:@"plist"];
    NSData *namePlist=[NSData dataWithContentsOfFile:testListPath];

    NSArray *classNamesToTest=[NSPropertyListSerialization propertyListWithData:namePlist options:0 format:0 error:nil];

//    NSArray *classNamesToTest = @[ @"MPWFastInvocation" ];

    NSMutableArray *mirrors=[NSMutableArray array];
    for ( NSString *className in classNamesToTest ) {
        id mirror=[MPWClassMirror mirrorWithClass:NSClassFromString( className)];
        if (mirror) {
            [mirrors addObject:mirror];
        } else {
            NSLog(@"Couldn't create mirror for %@",className);
        }
    }
    
    test=[MPWTestSuite testSuiteWithName:@"all" classMirrors:mirrors testTypes:@[ @"testSelectors"]];

    
    
//    test=[MPWTestSuite testSuiteWithName:@"all" testCases:@[]];
    //	NSLog(@"test: %@",test);
    results=[[MPWLoggingTester alloc] init];
    [results setVerbose:veryVerbose];
    fprintf(stderr,"Will run %d tests\n",[test numberOfTests]);
    [results addToTotalTests:[test numberOfTests]];
    [test runTest:results];
    if ( !veryVerbose ){
        if ( verbose) {
            [results printAllResults];
        } else {
            [results printResults];
        }
    }
    if ( [results failureCount] >0 ) {
        exitCode=1;
    }
    exit(0);
    return exitCode;

}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    runTests( @[ @"MPWFoundation"], @[] , NO, NO);
    return YES;
}


@end
