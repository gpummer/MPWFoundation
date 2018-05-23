//
//  MPWGenericReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/22/18.
//

#import "MPWReference.h"

@interface MPWGenericReference : MPWReference

-(instancetype)initWithPathComponents:(NSArray*)pathComponents scheme:(NSString*)scheme;
-(instancetype)initWithPath:(NSString*)pathName;

@end