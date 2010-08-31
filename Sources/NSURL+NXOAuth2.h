//
//  NSURL+NXOAuth2.h
//  Soundcloud
//
//  Created by Ullrich Schäfer on 07.10.09.
//  Copyright 2009 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (NXOAuth2)

- (NSURL *)URLByAddingParameters:(NSDictionary *)parameters;

/*!
 * returns the value of the first parameter on the query string that matches the key
 * returns nil if key was not found
 */
- (NSString *)valueForQueryParameterKey:(NSString *)key;

- (NSURL *)URLWithoutQueryString;
- (NSString *)URLStringWithoutQueryString;

@end
