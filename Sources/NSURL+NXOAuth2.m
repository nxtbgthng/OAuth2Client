//
//  NSURL+NXOAuth2.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 07.10.09.
//
//  Copyright 2010 nxtbgthng. All rights reserved. 
//
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import "NSString+NXOAuth2.h"

#import "NSURL+NXOAuth2.h"


@implementation NSURL (NXOAuth2)

- (NSURL *)URLByAddingParameters:(NSDictionary *)parameterDictionary {
	if (!parameterDictionary || [parameterDictionary count] == 0) {
		return self;
	}

	NSString *newParameterString = [NSString stringWithEncodedQueryParameters:parameterDictionary];
	
	NSString *absoluteString = [self absoluteString];
	if ([absoluteString rangeOfString:@"?"].location == NSNotFound) {	// append parameters?
		absoluteString = [NSString stringWithFormat:@"%@?%@", absoluteString, newParameterString];
	} else {
		absoluteString = [NSString stringWithFormat:@"%@&%@", absoluteString, newParameterString];
	}

	return [NSURL URLWithString:absoluteString];
}

- (NSString *)valueForQueryParameterKey:(NSString *)key;
{
	NSString *queryString = [self query];
	NSDictionary *parameters = [queryString parametersFromEncodedQueryString];
	return [parameters objectForKey:key];
}

- (NSURL *)URLWithoutQueryString;
{
	return [NSURL URLWithString:[self URLStringWithoutQueryString]];
}

- (NSString *)URLStringWithoutQueryString;
{
    NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}

@end
