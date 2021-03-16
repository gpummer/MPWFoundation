//
//  MPWBinding.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWFoundation/MPWReference.h>
#import <MPWFoundation/MPWWriteStream.h>

@class MPWReference,MPWAbstractStore;
@protocol MPWReferencing;

@protocol MPWBinding

+(instancetype)bindingWithReference:aReference inStore:aStore;

@property (nonatomic, retain) id value;

-(void)delete;

-asScheme;

// hierarchy support

-(BOOL)hasChildren;
-(NSArray*)children;
-(NSURL*)URL;


@end



@interface MPWBinding : NSObject<MPWBinding,MPWReferencing,Streaming>

@property (nonatomic, strong) id <MPWReferencing> reference;
@property (nonatomic, strong) MPWAbstractStore *store;

-(NSString*)path;
-(id <MPWReferencing>)asReference;
-(BOOL)isBound;

@end
