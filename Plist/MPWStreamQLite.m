//
//  MPWStreamQLite.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.06.20.
//

#import "MPWStreamQLite.h"
#import "MPWPListBuilder.h"
#import "MPWFlattenStream.h"
#import "MPWObjectBuilder.h"

#include <sqlite3.h>

@interface MPWStreamQLite()

@property (nonatomic, strong) NSString *databasePath;

@end

@interface MPWSQLiteWriter()
-initWithDB:(sqlite3*)db statement:(NSString*)sql;
@end


@implementation MPWSQLiteWriter
{
    sqlite3_stmt *insert_stmt;
    sqlite3_stmt *begin_transaction;
    sqlite3_stmt *end_transaction;
    sqlite3 *db;
}

-initWithDB:(sqlite3*)theDb statement:(NSString*)sql
{
    if( nil != (self=[super init]) ) {
        int rc1=0,rc2=0,rc3=0;
        db=theDb;
        rc1 = sqlite3_prepare_v2(db, [sql UTF8String], -1, &insert_stmt, 0);
        if ( !rc1 ) {
            rc2 = sqlite3_prepare_v2(db, "BEGIN TRANSACTION", -1, &begin_transaction, 0);
        }
        if ( !rc1 && !rc2 ) {
            rc3 = sqlite3_prepare_v2(db, "END TRANSACTION", -1, &end_transaction, 0);
        }
        if ( !(rc1==0 && rc2==0 && rc3==0)) {
            NSLog(@"preparing INSERT statments failed rc1=%d rc2=%d rc3=%d",rc1,rc2,rc3);
            NSLog(@"error: %s",(sqlite3_errmsg(db)));
        }
    }
    return self;
}

-(void)writeDictionary:(NSDictionary *)dict
{
    [self beginDictionary];
    for ( NSString *key in [dict allKeys]) {
        [self writeObject:dict[key] forKey:key];
    }
    [self endDictionary];
}


-(void)beginArray {
    sqlite3_step(begin_transaction);
    sqlite3_reset(begin_transaction);
}

-(void)endArray {
    sqlite3_step(end_transaction);
    sqlite3_reset(end_transaction);
}

-(void)writeObject:anObject forKey:(NSString*)aKey
{
//    NSLog(@"MPWSQLiteWriter writeObject: '%@'/%@ forKey: %@",anObject,[anObject class],aKey);
    NSString *sql_key=[@":" stringByAppendingString:aKey];
    int paramIndex=sqlite3_bind_parameter_index(insert_stmt, [sql_key UTF8String]);
    //    NSLog(@"index for key '%@' -> '%@' is %d",aKey,sql_key,paramIndex);
    NSData *utf8data=[[[anObject stringValue] dataUsingEncoding:NSUTF8StringEncoding] retain];
    sqlite3_bind_text(insert_stmt, paramIndex, [utf8data bytes],  (int)[utf8data length],0 );
}

-(void)writeInteger:(long)anInt forKey:(NSString*)aKey
{
//    NSLog(@"MPWSQLiteWriter writeInteger: %ld forKey: %@",anInt,aKey);
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
        if ( !(rc1==101 && rc2==0 && rc3==0) ) {
            NSLog(@"rc of step,clear,reset: %d %d %d",rc1,rc2,rc3);
            NSLog(@"error: %@",@(sqlite3_errmsg(db)));
        }
    }
}



//-(SEL)streamWriterMessage
//{
//    return @selector(writeOnSQLiteStream:);
//}

@end

@implementation MPWStreamQLite
{
    sqlite3 *db;
}

+(instancetype)open:(NSString*)newpath
{
    MPWStreamQLite *db=[[[self alloc] initWithPath:newpath] autorelease];
    if ([db open]==0) {
        return db;
    } else {
        [self release];
        return nil;
    }
}

+(instancetype)memory
{
    return [self open:@":memory:"];
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
                    int coltype=sqlite3_column_type(res, i);
                    switch ( coltype ) {
                        case SQLITE_INTEGER:
                        {
                            long value=sqlite3_column_int64(res, i);
                            [self.builder writeObject:@(value) forKey:keys[i]];
                            break;
                        }
                        default:
                        {
                            const char *text=(const char*)sqlite3_column_text(res, i);
                            if (text) {
                                NSString *value=@(text);
                                [self.builder writeObject:value forKey:keys[i]];
                            }
                        }
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

-(MPWSQLiteWriter*)insert:(NSString*)sql
{
    return [[[MPWSQLiteWriter alloc] initWithDB:db statement:sql] autorelease];
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

+(void)testInsert
{
    MPWStreamQLite *db=[self memory];
    EXPECTNOTNIL(db, @"got a db");
    [db query:@"CREATE TABLE Tester (a INT,b INT, c VARCHAR(50))"];
    db.builder=[MPWPListBuilder builder];
    [db query:@"select * from Tester"];
    INTEXPECT([db.builder.result count],0,@"no results");
    MPWSQLiteWriter *writer=[db insert:@"insert into Tester (a,b,c) VALUES (:an,:b,:c)"];
    [writer beginDictionary];
    [writer writeInteger:2 forKey:@"an"];
    [writer writeInteger:3 forKey:@"b"];
    [writer writeObject:@"hello" forKey:@"c"];
    [writer endDictionary];

    [writer beginDictionary];
    [writer writeInteger:4 forKey:@"an"];
    [writer writeInteger:5 forKey:@"b"];
    [writer writeObject:@"world" forKey:@"c"];
    [writer endDictionary];

    db.builder=[MPWPListBuilder builder];
    [db query:@"select * from Tester"];
    NSArray<NSDictionary*> *result=db.builder.result;
    INTEXPECT(result.count,2,@"number of rows");
    IDEXPECT(result.firstObject[@"a"],@(2),@"first.a");
    IDEXPECT(result.firstObject[@"b"],@(3),@"first.b");
    IDEXPECT(result.firstObject[@"c"],@"hello",@"first.c");
    IDEXPECT(result.lastObject[@"a"],@(4),@"last.a");
    IDEXPECT(result.lastObject[@"b"],@(5),@"last.b");
    IDEXPECT(result.lastObject[@"c"],@"world",@"last.c");
}

+(void)testInsertDict
{
    MPWStreamQLite *db=[self memory];
    EXPECTNOTNIL(db, @"got a db");
    [db query:@"CREATE TABLE Tester (a INT,b INT, c VARCHAR(50))"];
    db.builder=[MPWPListBuilder builder];
    [db query:@"select * from Tester"];
    INTEXPECT([db.builder.result count],0,@"no results");
    MPWSQLiteWriter *writer=[db insert:@"insert into Tester (a,b,c) VALUES (:a,:b,:c)"];
    [writer writeObject:@{ @"a": @(2), @"b": @(4), @"c": @"More"  }];

    db.builder=[MPWPListBuilder builder];
    [db query:@"select * from Tester"];
    NSArray<NSDictionary*> *result=db.builder.result;
    INTEXPECT(result.count,1,@"results");
    IDEXPECT(result.firstObject[@"a"],@(2),@"first.a");
    IDEXPECT(result.firstObject[@"b"],@(4),@"first.b");
    IDEXPECT(result.firstObject[@"c"],@"More",@"first.c");
}

+(NSArray*)testSelectors
{
   return @[
       @"testOpenChinookAndReadCorrectNumberOfArtists",
       @"testReadTracks",
       @"testInsert",
       @"testInsertDict",
			];
}

@end



@implementation MPWSQLTable {
    NSString *sqlForInsert;
    NSString *sqlForCreate;
}

lazyAccessor(NSString, sqlForInsert, setSqlForInsert, computeSQLForInsert )
lazyAccessor(NSString, sqlForCreate, setSqlForCreate, computeSQLForCreate )



-(NSString*)computeSQLForInsertWithKeys:(NSArray<NSString*>*)sqlKeys
{
    NSMutableString *sql=[NSMutableString string];
    MPWByteStream *s=[MPWByteStream streamWithTarget:sql];
    [s printFormat:@"INSERT INTO %@ (",[self name]];
    BOOL first=YES;
    for ( NSString *key in sqlKeys ) {
        [s printFormat:@"%s%@",first?"":", ",key];
        first=NO;
    }
    first=YES;
    [s printFormat:@") VALUES ("];
    for ( NSString *key in sqlKeys ) {
        [s printFormat:@"%s:%@",first?"":", ",key];
        first=NO;
    }
    [s printFormat:@");"];
    return sql;
}

-(NSString*)computeSQLForInsert
{
    return [self computeSQLForInsertWithKeys: [self.tableClass sqlInsertKeys]];
}

-(NSString*)computeSQLForCreate
{
    NSString *classSpecificSQL=[self.tableClass sqlForCreate];
    return [NSString stringWithFormat:@"CREATE TABLE %@ %@ ",[self name],classSpecificSQL];
}

-(void)create
{
    [self.db query:[self sqlForCreate]];
}

-(void)insert:array
{
    MPWSQLiteWriter *writer = [self.db insert: [self sqlForInsert]];
    [writer writeObject:array];
}

-(NSArray*)objectsForQuery:(NSString*)query
{
    MPWObjectBuilder *builder = [[[MPWObjectBuilder alloc] initWithClass: self.tableClass] autorelease];
    [self.db setBuilder:builder];
    [self.db query:query];
    return [[self.db builder] result];
}

-select
{
    return [self objectsForQuery:[NSString stringWithFormat:@"select * from %@",self.name]];
}

-selectWhere:query
{
    return [self objectsForQuery:[NSString stringWithFormat:@"select * from %@ where %@",self.name,query]];
}

@end

@implementation MPWSQLTable(testing)

+(void)testSQLForInsert
{
    MPWSQLTable *table=[[MPWSQLTable new] autorelease];
    table.name=@"tasks";
    NSString *insertSQL=[table computeSQLForInsertWithKeys:@[ @"id", @"title", @"completed"]];
    IDEXPECT(insertSQL,@"INSERT INTO tasks (id, title, completed) VALUES (:id, :title, :completed);",@"SQL for insert");
}

+(NSArray*)testSelectors
{
    return @[
        @"testSQLForInsert",
    ];
}

@end

