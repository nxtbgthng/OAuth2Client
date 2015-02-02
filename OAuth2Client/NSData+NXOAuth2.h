//
//  NSData+NXOAuth2.h
//  OAuth2Client
//
//  Created by Thomas Kollbach on 18.05.11
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>


@interface NSData (NXOAuth2)


#pragma mark Digest

- (NSData *)nx_SHA1Digest;
- (NSString *)nx_SHA1Hexdigest;

@end
