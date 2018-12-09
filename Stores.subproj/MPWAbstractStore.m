//
//  MPWAbstractStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWAbstractStore.h"
#import "MPWGenericReference.h"
#import "NSNil.h"
#import "MPWByteStream.h"
#import "MPWWriteStream.h"

@implementation MPWAbstractStore

+(instancetype)store
{
    return [[[self alloc] init] autorelease];
}

+(instancetype)mapStore:(id)storeDescription
{
    if ( [storeDescription respondsToSelector:@selector(store)]) {
        storeDescription=[storeDescription store];
    } else if ( [storeDescription isKindOfClass:[NSArray class]]) {
        storeDescription=[self mapStores:storeDescription].firstObject;
    }
    return storeDescription;
}

+(NSArray*)mapStores:(NSArray*)storeDescriptions
{
 //   NSMutableOrderedSet *stores=[NSMutableOrderedSet orderedSetWithCapacity:storeDescriptions.count];
    NSMutableArray *stores=[NSMutableArray arrayWithCapacity:storeDescriptions.count];
    id previous=nil;
    for ( id storeDescription in storeDescriptions) {
        if ( previous ) {
            [stores addObject:previous];
        }
        if ( [storeDescription isKindOfClass:[NSArray class]] ) {
            NSMutableArray<MPWStorage> *substores=(id)[NSMutableArray array];
            for ( NSArray *subdescription in storeDescription) {
                MPWAbstractStore *substore=[self mapStore:subdescription];
                [substores addObject:substore];
            }
            [previous setSourceStores:substores];
        } else if ( [storeDescription isKindOfClass:[NSDictionary class]] ) {
            NSDictionary *descriptionDict=(NSDictionary*)storeDescription;
            NSMutableDictionary *storeDict=[NSMutableDictionary dictionary];
            for  (NSString *key in descriptionDict.allKeys ) {
                id subDescription=[descriptionDict objectForKey:key];
                [storeDict setObject:[self mapStore:subDescription] forKey:key];
            }
            [previous setStoreDict:storeDict];
        } else {
            if ( [storeDescription respondsToSelector:@selector(store)]) {
                storeDescription=[storeDescription store];
            }
            if ( previous && [storeDescription respondsToSelector:@selector(setSourceStores:)]) {
                [previous setSourceStores:(NSArray<MPWStorage>*)@[ storeDescription ]];
            }
            previous=storeDescription;

        }
    }
    if ( previous ) {
        [stores addObject:previous];
    }

    return stores;
}

+(instancetype)stores:(NSArray*)storeDescriptions
{
    return [self mapStores:storeDescriptions].firstObject;
}


-objectForReference:(MPWReference*)aReference
{
    return nil;
}

-(void)setObject:theObject forReference:(MPWReference*)aReference
{
    return ;
}

-(void)mergeObject:theObject forReference:(id <MPWReferencing>)aReference
{
    [self setObject:theObject forReference:aReference];
}

-(void)deleteObjectForReference:(MPWReference*)aReference
{
    return ;
}

-(BOOL)hasChildren:(MPWReference*)aReference
{
    return NO;
}

-objectForKeyedSubscript:key
{
    return [self objectForReference:key];
}

-(void)setObject:(id)theObject forKeyedSubscript:(nonnull id<NSCopying>)key
{
    [self setObject:theObject forReference:(id <MPWReferencing>)key];
}

-(BOOL)isLeafReference:(MPWReference*)aReference
{
    return YES;
}

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    return @[];
}

-(MPWReference*)referenceForPath:(NSString*)path
{
    return [MPWGenericReference referenceWithPath:path];
}

-(NSURL*)URLForReference:(MPWGenericReference*)aReference
{
    return [aReference URL];
}


-(NSString*)generatedName
{
    return [NSString stringWithFormat:@"\"%@\"",[[NSStringFromClass(self.class) componentsSeparatedByString:@"."] lastObject]];
}

-(NSString*)displayName
{
    return self.name ?: self.generatedName;
}

-(void)reportError:(NSError *)error
{
    if (error) {
        [self.errors writeObject:error];
    }
}

-(void)graphViz:(MPWByteStream*)aStream
{
    [aStream printFormat:@"%@\n",[self displayName]];
}

-(NSString*)graphViz
{
    MPWByteStream *s=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [self graphViz:s];
    return (NSString*)s.target;
}

-(void)setSourceStores:(NSArray<MPWStorage> *)stores
{
   
}

-(void)setStoreDict:(NSDictionary*)storeDict
{
}


@end

@implementation MPWAbstractStore(legacy)

-evaluateIdentifier:anIdentifer withContext:aContext
{
    id value = [self objectForReference:anIdentifer];
    
    if ( [value respondsToSelector:@selector(isNotNil)]  && ![value isNotNil] ) {
        value=nil;
    }
    return value;
}

-get:(NSString*)uriString parameters:uriParameters
{
    return [self objectForReference:[self referenceForPath:uriString]];
}

-get:uri
{
    return [self get:uri parameters:nil];
}


@end


#import "DebugMacros.h"

@implementation MPWAbstractStore(testing)


+(void)testConstructingReferences
{
    MPWAbstractStore *store=[MPWAbstractStore store];
    id <MPWReferencing> r1=[store referenceForPath:@"somePath"];
    IDEXPECT(r1.path, @"somePath", @"can construct a reference");
}

+(void)testGettingURLs
{
    MPWAbstractStore *store=[MPWAbstractStore store];
    id <MPWReferencing> r1=[store referenceForPath:@"somePath"];
    IDEXPECT([[store URLForReference:r1] absoluteString] , @"somePath", @"can get a URL from a reference");
}


+(NSArray*)testSelectors {  return @[
                                     @"testConstructingReferences",
                                     @"testGettingURLs",
                                     ]; }

@end
