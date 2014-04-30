//
//  MPWBlockInvocable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWBlockInvocable.h"
#import "NSNil.h"

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};



const char *blocksig( void *block_arg )
{
    struct Block_struct *block=(struct Block_struct*)block_arg;
    struct Block_descriptor *descriptor=block->descriptor;
    if ( descriptor) {
        if ( block->flags & BLOCK_HAS_COPY_DISPOSE) {
            return (descriptor->signature);
        } else {
            return (const char*)descriptor->copy_helper;
        }
    }
    return NULL;
}

@implementation MPWBlockInvocable

static struct Block_descriptor sdescriptor= {
		0, 64, NULL, NULL
};

-(id)invokeWithArgs:(va_list)args
{
	return self;
}

-(const char*)ctypes
{
    return blocksig(self);
}

-(NSString*)types
{
    const char *ctypes=[self ctypes];
    return ctypes ? [NSString stringWithCString:ctypes encoding:NSASCIIStringEncoding] : nil;
}

static id blockFun( id self, ... ) {
	va_list args;
	va_start( args, self );
	id result=[self invokeWithArgs:args];
	va_end( args );
	return result;
}

-(IMP)invokeMapper
{
	return (IMP)blockFun;
}

-init
{
	self=[super init];
	if ( self ) {
		invoke=(IMP)[self invokeMapper];
		descriptor=&sdescriptor;
        flags=1;
//		flags|=(1 << 28);   // is global
        flags|=(1 << 24);  // we are a heap block
	}
	return self;
}

-(id)retain
{
    flags++;
    return self;
}

-(oneway void)release
{
    if ( (--flags &0xffff) <= 0 ) {
        [self dealloc];
    }
}

-(NSUInteger)retainCount
{
    return flags&0xffff;
}

-(NSArray*)formalParameters
{
    return @[];
}

-(const char*)typeSignature
{
    return "@@";
}

-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters
{
    return nil;
}

-invokeWithTarget:target args:(va_list)args
{
	//	return [target evaluateScript:script];
	id formalParameters = [self formalParameters];
	id parameters=[NSMutableArray array];
	int i;
	const char *sig_in=[self typeSignature];
    char signature[30];
    const char *source=sig_in;
    char *dest=signature;
    while ( *source ) {
        if ( !isdigit(*source)  ) {
            *dest++=*source;
        }
        source++;
    }
    *dest++=0;
    
	id returnVal;
    //	NSLog(@"selector: %s",selname);
    //	NSLog(@"signature: %s",signature);
    //	NSLog(@"target: %@",target);
	for (i=0;i<[formalParameters count];i++ ) {
        //		NSLog(@"param[%d]: %c",i,signature[i+3]);
		switch ( signature[i+3] ) {
				id theArg;
			case '@':
			case '#':
				theArg = va_arg( args, id );
                //				NSLog(@"object arg: %@",theArg);
				if ( theArg == nil ) {
					theArg=[NSNil nsNil];
				}
				[parameters addObject:theArg];
				break;
			case 'c':
			case 'C':
			case 's':
			case 'S':
			case 'i':
			case 'I':
			{
				int intArg = va_arg( args, int );
                //				NSLog(@"int param: %d",intArg );
				[parameters addObject:[NSNumber numberWithInt:intArg]];
				break;
			}
			case 'f':
			case 'F':
				[parameters addObject:[NSNumber numberWithFloat:va_arg( args, double )]];
				break;
			default:
				va_arg( args, void* );
				[parameters addObject:[NSString stringWithFormat:@"unhandled parameter at %d '%c'",i,signature[i+3]]];
		}
	}
	returnVal = [self invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters];
	if ( signature[0] == 'i' ) {
#ifdef __x86_64__
		returnVal=(id)[returnVal longLongValue];
#else
		returnVal=(id)[returnVal intValue];
#endif
	}
	return returnVal;
}


@end

#if NS_BLOCKS_AVAILABLE

#import "DebugMacros.h"

@interface MPWBlockInvocableTest : MPWBlockInvocable
{
}
@end


@implementation MPWBlockInvocableTest

typedef int (^intBlock)(int arg );


-(id)invokeWithArgs:(va_list)args
{
	return (id)(va_arg( args, long ) * 3);
}

+(void)testBlockInvoke
{
	id blockObj = [[[self alloc] init] autorelease];
	INTEXPECT( ((intBlock)blockObj)( 3 ), 9, @"block(3) ");
}
    
+(void)testNSBlockTypes
{
    intBlock myBlock=^(int arg){ return 3; };
    const char *csig = blocksig( myBlock);
    NSString *sig=[NSString stringWithCString:csig encoding:NSASCIIStringEncoding];
    IDEXPECT(sig, @"i12@?0i8", @"signature of int->int block");
}


+(void)testBlockCopy
{
	id blockObj = [[[self alloc] init] autorelease];
    intBlock firstBlock=(intBlock)blockObj;
    intBlock copiedBlock=Block_copy(firstBlock);
	INTEXPECT( ((intBlock)copiedBlock)( 3 ), 9, @"block(3) ");
    Block_release(copiedBlock);
}

+testSelectors
{
	return [NSArray arrayWithObjects:
            @"testBlockInvoke",
            @"testNSBlockTypes",
            @"testBlockCopy",
			nil];
}

@end

#endif
