//
//  MPWSQLTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import "MPWSQLTable.h"
#import "AccessorMacros.h"
#import "MPWByteStream.h"
#import "MPWStreamQLite.h"
#import "MPWObjectBuilder.h"
#import "MPWSQLColumnInfo.h"
#import <sqlite3.h>

@implementation MPWSQLTable {
    NSString *sqlForInsert;
    NSString *sqlForCreate;
    sqlite3_stmt *insert_stmt;
    sqlite3_stmt *begin_transaction;
    sqlite3_stmt *end_transaction;
    sqlite3 *sqlitedb;
}

lazyAccessor(NSString, sqlForInsert, setSqlForInsert, computeSQLForInsert )
lazyAccessor(NSString, sqlForCreate, setSqlForCreate, computeSQLForCreate )

-(void)setSourceDB:(MPWStreamQLite*)sourceDB
{
    self.db = sourceDB;
    sqlitedb = [sourceDB sqliteDB];
    [self createInsertStatement];
}

-initWithSqliteDB:(sqlite3*)theDb
{
    if( nil != (self=[super init]) ) {
        [self createInsertStatement];
    }
    return self;
}

-(instancetype)initWithDB:(MPWStreamQLite*)theDB statement:(NSString*)sql
{
    return [self initWithSqliteDB:[theDB sqliteDB] statement:sql];
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
            NSLog(@"error: %@",@(sqlite3_errmsg(sqlitedb)));
        }
    }
}

-(void)createInsertStatement
{
    if ( !insert_stmt) {
        int rc1,rc2=0,rc3=0;
        rc1 = sqlite3_prepare_v2(sqlitedb, [[self computeSQLForInsert] UTF8String], -1, &insert_stmt, 0);
        rc2 = sqlite3_prepare_v2(sqlitedb, "BEGIN TRANSACTION", -1, &begin_transaction, 0);
        rc3 = sqlite3_prepare_v2(sqlitedb, "END TRANSACTION", -1, &end_transaction, 0);
        if ( !(rc1==0 && rc2==0 && rc3==0)) {
            NSLog(@"preparing INSERT statments failed rc1=%d rc2=%d rc3=%d",rc1,rc2,rc3);
            NSLog(@"error: %s",(sqlite3_errmsg(sqlitedb)));
        }
    }
    
}

+(NSArray*)sqlInsertKeys { return @[]; }

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
    id keys = [[[self schema] collect] name];
    return [self computeSQLForInsertWithKeys: keys];
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
    [self writeObject:array];
}

-(NSArray*)objectsForQuery:(NSString*)query builder:(MPWPListBuilder*)builder
{
    [self.db setBuilder:builder];
    [self.db query:query];
    return [[self.db builder] result];
}

-(MPWPListBuilder*)defaultBuilder
{
    return self.tableClass ? [[[MPWObjectBuilder alloc] initWithClass: self.tableClass] autorelease] :
    [MPWPListBuilder builder];
}

-(NSArray*)objectsForQuery:(NSString*)query
{
    return [self objectsForQuery:query builder:[self defaultBuilder]];
}

-(NSInteger)count
{
    return [[[[self objectsForQuery:[NSString stringWithFormat:@"select count(*) from %@",self.name] builder:[MPWPListBuilder builder]] firstObject] at:@"count(*)"] longValue];
}


-(NSArray<MPWSQLColumnInfo*>*)schema
{
    NSArray *resultSet = [self objectsForQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)",self.name] builder:[[[MPWObjectBuilder alloc] initWithClass: [MPWSQLColumnInfo class]] autorelease]];
    return resultSet;
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

+(void)testGetTableSchema
{
    MPWStreamQLite *db=[MPWStreamQLite _chinookDB];
    MPWSQLTable *artists=[db tables][@"artists"];
    NSArray *schema=[artists schema];
    INTEXPECT(schema.count,2,@"columns");
    MPWSQLColumnInfo *nameColumn=schema.lastObject;
    MPWSQLColumnInfo *idColumn=schema.firstObject;
    IDEXPECT(idColumn.name, @"ArtistId", @"name of id column");
    IDEXPECT(idColumn.type, @"INTEGER", @"type of id column");
    EXPECTTRUE(idColumn.pk, @"ArtistId is primary key");
    EXPECTTRUE(idColumn.notnull, @"ArtistId not null");
    IDEXPECT(nameColumn.name, @"Name", @"name of 'name' column");
    IDEXPECT(nameColumn.type, @"NVARCHAR(120)", @"type of 'name' column");
    EXPECTFALSE(nameColumn.pk, @"name is primary key");
    EXPECTFALSE(nameColumn.notnull, @"name not null");
}

+(void)testCount
{
    MPWStreamQLite *db=[MPWStreamQLite _chinookDB];
    MPWSQLTable *artists=[db tables][@"artists"];
    INTEXPECT( artists.count, 275, @"number of artists");
}

+(NSArray*)testSelectors
{
    return @[
        @"testSQLForInsert",
        @"testGetTableSchema",
        @"testCount",
    ];
}

@end