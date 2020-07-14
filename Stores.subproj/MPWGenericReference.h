//
//  MPWGenericReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/22/18.
//

#import <MPWReference.h>

@interface MPWGenericReference : MPWReference <MPWReferencing,MPWReferenceCreation,NSCopying>

-(void)setPath:(NSString*)path;         // legacy/compatibility
-(NSString*)identifierName;
-(BOOL)isRoot;

@end


@interface MPWReferenceTests : NSObject {}
@end

@interface NSString(referencing)

-asReference;

@end

