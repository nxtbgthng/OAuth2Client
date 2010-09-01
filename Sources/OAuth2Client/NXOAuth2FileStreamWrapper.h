//
//  NXOAuth2FileStreamWrapper.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import <Foundation/Foundation.h>


@interface NXOAuth2FileStreamWrapper : NSObject {
	NSInputStream		*stream;
	unsigned long long	contentLength;
}
@property (readonly) NSInputStream *stream;
@property (readonly) unsigned long long contentLength;

+ (id)wrapperWithStream:(NSInputStream *)stream contentLength:(unsigned long long)contentLength;
- (id)initWithStream:(NSInputStream *)stream contentLength:(unsigned long long)contentLength;


@end
