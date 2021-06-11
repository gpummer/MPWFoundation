//
//  MPWURLBinding.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 20.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFileBinding.h>


@interface MPWURLBinding : MPWFileBinding {
	NSError	*error;
    BOOL inPOST;
    
    NSMutableData *responseData;
}

@end
