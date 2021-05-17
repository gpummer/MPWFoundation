//
//  MPWFilter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/2/18.
//

#import <MPWFoundation/MPWWriteStream.h>


typedef id (*IMP_2_id_args)(id, SEL, id,id);


#define    FORWARD(object)    if (  targetWriteObject ) { targetWriteObject( _target, @selector(writeObject:sender:), object ,self); } else { [_target writeObject:object sender:self]; }


@interface MPWFilter : MPWWriteStream <StreamSource>
{
    id _target;
    IMP_2_id_args    targetWriteObject;
}


+(instancetype)streamWithTarget:aTarget;
-(instancetype)initWithTarget:aTarget;

-(void)flush:(int)n;
-(void)close:(int)n;

-(void)setFinalTarget:newTarget;
-(void)forward:anObject;
-finalTarget;
-processObject:anObject;

+defaultTarget;

-(void)insertStream:aStream;

-firstObject;       // dummy for testing
-lastObject;        // dummy for testing

@end
