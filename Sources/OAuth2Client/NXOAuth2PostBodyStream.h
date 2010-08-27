//
//  NXOAuth2PostBodyStream.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXOAuth2PostBodyStreamMonitorDelegate.h"


@interface NXOAuth2PostBodyStream : NSInputStream {
	NSString		*boundary;
	
    NSArray			*contentStreams;
    NSInputStream	*currentStream;	// assigned (is retained by contentStreams)
    NSUInteger		streamIndex;
	
	unsigned long long numBytesRead;
	unsigned long long numBytesTotal;
	
	NSObject<NXOAuth2PostBodyStreamMonitorDelegate> *monitorDelegate;	// assigned
}

- (id)initWithParameters:(NSDictionary *)postParameters;

@property (readonly) NSString *boundary;
@property (readonly) unsigned long long length;
@property (assign) NSObject<NXOAuth2PostBodyStreamMonitorDelegate>* monitorDelegate;

@end


