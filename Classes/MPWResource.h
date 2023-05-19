//
//  MPWResource.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11/25/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWResource : NSObject {
	id			source;
	NSData		*rawData;
	NSString	*MIMEType;
	id			_value;
    NSError     *error;
}

objectAccessor_h(NSData*, rawData, setRawData )
objectAccessor_h(NSString*, MIMEType, setMIMEType )
objectAccessor_h(NSError*, error, setError)
idAccessor_h( source, setSource )


@end
