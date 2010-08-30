//
//  NSURL+NXOAuth2.m
//  Soundcloud
//
//  Created by Ullrich Schäfer on 07.10.09.
//  Copyright 2009 nxtbgthng. All rights reserved.
//

#import "NSString+NXOAuth2.h"

#import "NSURL+NXOAuth2.h"


@implementation NSURL (SoundCloudAPI)

- (NSURL *)urlByAddingParameters:(NSDictionary *)parameterDictionary {
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

- (NSString *)URLStringWithoutQuery 
{
    NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}

@end
