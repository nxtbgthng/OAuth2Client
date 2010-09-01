//
//  NXOAuth2PostBodyPart.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import <Foundation/Foundation.h>


@interface NXOAuth2PostBodyPart : NSObject {
	NSString		*contentHeaders;
	NSInputStream	*contentStream;
	unsigned long long	contentLength;
}

@property (readonly) NSString		*contentHeaders;
@property (readonly) NSInputStream	*contentStream;
@property (readonly) unsigned long long	contentLength;


/*!
 *	Convenience methods
 *
 *	Note: possible types for content are
 *	- NSString
 *	- NSURL (local file URL)
 *	- NSData
 *	- NXOAuth2FileStreamWrapper
 */
+ partWithName:(NSString *)name content:(id)content;
- (id)initWithName:(NSString *)name content:(id)content;

- (id)initWithHeaders:(NSString *)headers dataContent:(NSData *)data;
- (id)initWithName:(NSString *)name streamContent:(NSInputStream *)stream streamLength:(unsigned long long)streamLength;

- (id)initWithHeaders:(NSString *)headers streamContent:(NSInputStream *)stream length:(unsigned long long)length; //designated initializer

@end
