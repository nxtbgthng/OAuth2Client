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
	if (!parameterDictionary
		|| [parameterDictionary count] == 0) {
		return self;
	}
	
	NSString *absoluteString = [self absoluteString];

	NSMutableArray *parameterPairs = [NSMutableArray array];
	for (NSString *key in [parameterDictionary allKeys]) {
		NSString *pair = [NSString stringWithFormat:@"%@=%@", key, [[parameterDictionary objectForKey:key] URLEncodedString]];
		[parameterPairs addObject:pair];
	}
	NSString *queryString = [parameterPairs componentsJoinedByString:@"&"];
	
	NSRange parameterRange = [absoluteString rangeOfString:@"?"];
	if (parameterRange.location == NSNotFound) {
		absoluteString = [NSString stringWithFormat:@"%@?%@", absoluteString, queryString];
	} else {
		absoluteString = [NSString stringWithFormat:@"%@&%@", absoluteString, queryString];
	}

	return [NSURL URLWithString:absoluteString];
}

- (NSString *)valueForQueryParameterKey:(NSString *)aKey;
{
	NSString *queryString = [self query];
	NSArray *keyValuePairs = [queryString componentsSeparatedByString:@"&"];
	for (NSString *keyValueString in keyValuePairs) {
		NSArray *keyValuePair = [keyValueString componentsSeparatedByString:@"="];
		if (keyValuePair.count != 2)
			continue;
		NSString *key = [keyValuePair objectAtIndex:0];
		NSString *value = [keyValuePair objectAtIndex:1];
		if ([aKey isEqualToString:key])
			return value;
	}
	return nil;
}

- (NSString *)URLStringWithoutQuery 
{
    NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}

@end
