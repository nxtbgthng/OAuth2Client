//
//  NSString+NXOAuth2.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 07.10.09.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>


@interface NSString (NXOAuth2)

+ (NSString *)nxoauth2_stringWithUUID;

+ (NSString *)nxoauth2_stringWithEncodedQueryParameters:(NSDictionary *)parameters;
- (NSDictionary *)nxoauth2_parametersFromEncodedQueryString;

- (NSString *)nxoauth2_URLEncodedString;
- (NSString *)nxoauth2_URLDecodedString;

@end
