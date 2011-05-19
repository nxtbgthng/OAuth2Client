//
//  NSData+NXOAuth2.m
//  OAuth2Client
//
//  Created by Thomas Kollbach on 18.05.11
//
//  Copyright 2011 nxtbgthng. All rights reserved. 
//
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#import "NSData+NXOAuth2.h"

@implementation NSData (NXOAuth2)


#pragma mark Digest

- (NSData *)nx_SHA1Digest;
{
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(self.bytes, (CC_LONG)self.length, digest);
	
	return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

- (NSString *)nx_SHA1Hexdigest;
{
	NSData *binDigest = [self nx_SHA1Digest];
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	[binDigest getBytes:digest length:CC_SHA1_DIGEST_LENGTH];
	
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	
	for (NSUInteger i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", digest[i]];
	}	
	
	return [[output copy] autorelease];
}


@end
