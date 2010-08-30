//
//  NSString+NXOAuth2.h
//  Soundcloud
//
//  Created by Ullrich Schäfer on 07.10.09.
//  Copyright 2009 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NXOAuth2)

+ (NSString *)stringWithUUID;

+ (NSString *)stringWithEncodedQueryParameters:(NSDictionary *)parameters;
- (NSDictionary *)parametersFromEncodedQueryString;

- (NSString *)URLEncodedString;
- (NSString *)URLDecodedString;

@end
