//
//  AppDelegate.m
//  TestMPWFoundation
//
//  Created by Marcel Weiher on 12/7/16.
//
//

#import "AppDelegate.h"
#import <MPWTest/MPWTestSuite.h>
#import <MPWTest/MPWLoggingTester.h>
#import <MPWTest/MPWClassMirror.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


int runTests( NSArray *testSuiteNames , NSMutableArray *testTypeNames,  BOOL verbose ,BOOL veryVerbose ) {
    NSMutableArray *testsuites=[NSMutableArray array];
    MPWTestSuite* test;
    MPWLoggingTester* results;
    int exitCode=0;
    
//    if ( [testTypeNames count] == 0 ) {
//        testTypeNames=[testTypeNames arrayByAddingObject:@"testSelectors"];
//    }
//    for ( id suitename in testSuiteNames ) {
//        id suite = [MPWTestSuite testSuiteForLocalFramework:suitename testTypes:testTypeNames];
//        //			NSLog(@"suite name= %@",suitename);
//        //			NSLog(@"suite = %@",suite);
//        if ( suite ) {
//            [testsuites addObject:suite];
//        } else {
//            NSLog(@"couldn't load framework: %@",suitename);
//        }
//        
//    }
    NSArray *classNamesToTest=
    @[
      @"MPWPoint",
      @"MPWStream",
      @"MPWPipe",
      @"MPWDelayStream",
      @"MPWFastInvocation",
      ];
    NSMutableArray *mirrors=[NSMutableArray array];
    for ( NSString *className in classNamesToTest ) {
        [mirrors addObject:[MPWClassMirror mirrorWithClass:NSClassFromString( className)]];
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
    return exitCode;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    runTests( @[ @"MPWFoundation"], @[] , NO, NO);
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
