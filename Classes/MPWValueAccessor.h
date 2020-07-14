//
//  MPWValueAccessor.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import <MPWObject.h>



@interface MPWValueAccessor : MPWObject
{
    @public
    IMP value;
}

+valueForName:(NSString*)name;
-initWithName:(NSString*)name;
-valueForTarget:aTarget;
-(void)setValue:newValue forTarget:aTarget;
-(NSString*)name;
-value;
-(void)setValue:newValue;
-(long)integerValue;
-(void)setIntValue:(long)newValue;
-(void)setIntValue:(long)newValue forTarget:aTarget;

-target;
-(void)bindToTarget:aTarget;
-(void)bindToClass:aClass;

#define GETVALUE(accessor) (accessor->value( accessor, @selector(value)))


@end
