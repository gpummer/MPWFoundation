//
//  MPWStreamQLite.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.06.20.
//

#import "MPWStreamQLite.h"
#import "MPWPListBuilder.h"
#include <sqlite3.h>

@interface MPWStreamQLite()

@property (nonatomic, strong) NSString *databasePath;

@end

@implementation MPWStreamQLite
{
    sqlite3 *db;
    sqlite3_stmt *insert_stmt;

}

+(instancetype)open:(NSString*)newpath
{
    MPWStreamQLite *db=[[[self alloc] initWithPath:newpath] autorelease];
    [db open];
    return db;
}

-(instancetype)initWithPath:(NSString*)newpath
{
    self=[super init];
    self.databasePath = newpath;
    return self;
}

-(int)query:(NSString*)sql
{
    sqlite3_stmt *res;
    int rc = sqlite3_prepare_v2(db, [sql UTF8String], -1, &res, 0);
    @autoreleasepool {
        [self.builder beginArray];
        int step;
        int numCols=sqlite3_column_count(res);
        NSString* keys[numCols];
        for (int i=0;i<numCols;i++) {
            keys[i]=@(sqlite3_column_name(res, i));
        }
        while ( SQLITE_ROW == (step = sqlite3_step(res))) {
            @autoreleasepool {
                [self.builder beginDictionary];
                for (int i=0; i<numCols;i++) {
                    const char *text=(const char*)sqlite3_column_text(res, i);
                    if (text) {
                        NSString *value=@(text);
                        [self.builder writeObject:value forKey:keys[i]];
                    }
                }
                [self.builder endDictionary];
            }
        }
        sqlite3_finalize(res);
        [self.builder endArray];
    }
    return rc;
}

-(int)insert:(NSString*)sql
{
    int rc = sqlite3_prepare_v2(db, [sql UTF8String], -1, &insert_stmt, 0);
    return rc;
}

-(void)beginDictionary {

}

-(void)beginArray {

}

-(void)endArray {

}

-(void)writeObject:anObject forKey:(NSString*)aKey
{
    NSString *sql_key=[@":" stringByAppendingString:aKey];
    int paramIndex=sqlite3_bind_parameter_index(insert_stmt, [sql_key UTF8String]);
//    NSLog(@"index for key '%@' -> '%@' is %d",aKey,sql_key,paramIndex);
    NSData *utf8data=[[[anObject stringValue] dataUsingEncoding:NSUTF8StringEncoding] retain];
    sqlite3_bind_text(insert_stmt, paramIndex, [utf8data bytes],  (int)[utf8data length],0 );
}

-(void)writeInteger:(long)anInt forKey:(NSString*)aKey
{
    NSString *sql_key=[@":" stringByAppendingString:aKey];
    int paramIndex=sqlite3_bind_parameter_index(insert_stmt, [sql_key UTF8String]);
//    NSLog(@"index for key '%@' -> '%@' is %d",aKey,sql_key,paramIndex);
    sqlite3_bind_int64(insert_stmt, paramIndex, anInt);
}

-(void)endDictionary
{
    if ( insert_stmt) {
        int rc1=sqlite3_step(insert_stmt);
        int rc2=sqlite3_clear_bindings(insert_stmt);
        int rc3=sqlite3_reset(insert_stmt);
        NSLog(@"rc of step,clear,reset: %d %d %d",rc1,rc2,rc3);
    }
}

-(int)open
{
    return sqlite3_open([self.databasePath UTF8String], &db);
}

-(void)close
{
    if (db) {
        sqlite3_close(db);
        db=NULL;
    }
}

-(NSString*)error
{
    return @(sqlite3_errmsg(db));
}

-(void)dealloc
{
    [self close];
    [_databasePath release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStreamQLite(testing) 

+_chinookDB
{
    NSString *path=[[NSBundle bundleForClass:self] pathForResource:@"chinook" ofType:@"db"];
    MPWStreamQLite *db = [self open:path];
    MPWPListBuilder *builder=[MPWPListBuilder builder];
    db.builder = builder;
    return db;
}

+(void)testOpenChinookAndReadCorrectNumberOfArtists
{
    MPWStreamQLite *db=[self _chinookDB];
    [db query:@"select * from artists"];
    NSArray *artists=[db.builder result];
    INTEXPECT(artists.count, 275, @"number of artists");
}

+(void)testReadTracks
{
    MPWStreamQLite *db=[self _chinookDB];
    [db query:@"select * from tracks"];
    NSArray<NSDictionary*> *tracks=[db.builder result];
    INTEXPECT(tracks.count, 3503, @"number of tracks");
    IDEXPECT( tracks.lastObject[@"Composer"] , @"Philip Glass", @"composer of last track");
    IDEXPECT( tracks.lastObject[@"Name"] , @"Koyaanisqatsi", @"name of last track");
    IDEXPECT( tracks.firstObject[@"Composer"] , @"Angus Young, Malcolm Young, Brian Johnson", @"composer of first track");
}


+(NSArray*)testSelectors
{
   return @[
       @"testOpenChinookAndReadCorrectNumberOfArtists",
       @"testReadTracks",
			];
}

@end
