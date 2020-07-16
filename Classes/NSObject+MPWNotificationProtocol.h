//
//  NSObject+MPWNotificationProtocol.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 4/17/18.
//  Copyright Marcel Weiher 2018
//
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/Protocol.h>

@import ObjectiveC.Protocol;



@protocol MPWNotificationProtocol
-(void)installProtocolNotifications;        // compiler requires >= 1 messages in protocol, so put this here
@end

@interface NSObject (MPWNotificationProtocol) <MPWNotificationProtocol>

-(void)registerMessage:(SEL)aMessage forNotificationName:(NSString*)notificationName;
-(void)registerNotificationMessage:(SEL)aMessage;



@end

void sendProtocolNotification( Protocol *aProtocol, id anObject );
NSString *notificatioNameFromProtocol(Protocol *aProtocol );

#if !TARGET_OS_IPHONE
//@interface Protocol : NSObject  @end
@interface NSObject(notifications)

-(void)notify:anObject;
-(void)notify;
-(BOOL)isNotificationProtocol;

@end
#endif
