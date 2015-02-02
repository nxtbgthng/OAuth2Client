//
//  NSURL+NXOAuth2.h
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

@interface NSURL (NXOAuth2)

- (NSURL *)nxoauth2_URLByAddingParameters:(NSDictionary *)parameters;

/*!
 * returns the value of the first parameter on the query string that matches the key
 * returns nil if key was not found
 */
- (NSString *)nxoauth2_valueForQueryParameterKey:(NSString *)key;

- (NSURL *)nxoauth2_URLWithoutQueryString;
- (NSString *)nxoauth2_URLStringWithoutQueryString;

@end
