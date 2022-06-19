//
//  SFTPStore.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 12.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

@interface SFTPStore : MPWAbstractStore


@property (nonatomic,assign) int verbosity;
@property (nonatomic,assign) int directoryUMask;
@property (nonatomic,assign) int fileUMask;

-(instancetype)initWithSession:newSession;
-(int)openSFTP;
-(void)disconnect;

@end

