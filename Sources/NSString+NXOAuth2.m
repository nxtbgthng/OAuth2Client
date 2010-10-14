//
//  NSString+NXOAuth2.m
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


@implementation NSString (NXOAuth2)

+ (NSString *)nxoauth2_stringWithUUID;
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	
    return [(NSString *)string autorelease];
}


#pragma mark Query String Helpers

+ (NSString *)nxoauth2_stringWithEncodedQueryParameters:(NSDictionary *)parameters;
{
	
	NSMutableArray *parameterPairs = [NSMutableArray array];
	for (NSString *key in [parameters allKeys]) {
		NSString *pair = [NSString stringWithFormat:@"%@=%@", [key nxoauth2_URLEncodedString], [[parameters objectForKey:key] nxoauth2_URLEncodedString]];
		[parameterPairs addObject:pair];
	}
	return [parameterPairs componentsJoinedByString:@"&"];
}

- (NSDictionary *)nxoauth2_parametersFromEncodedQueryString;
{
	NSArray *encodedParameterPairs = [self componentsSeparatedByString:@"&"];
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    
    for (NSString *encodedPair in encodedParameterPairs) {
        NSArray *encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
		if (encodedPairElements.count == 2) {
			[requestParameters setValue:[[encodedPairElements objectAtIndex:1] nxoauth2_URLDecodedString]
								 forKey:[[encodedPairElements objectAtIndex:0] nxoauth2_URLDecodedString]];
		}
    }
	return requestParameters;
}


#pragma mark URLEncoding

- (NSString *)nxoauth2_URLEncodedString 
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)self,
                                                                           NULL,
																		   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                           kCFStringEncodingUTF8);
    [result autorelease];
	return result;
}

- (NSString*)nxoauth2_URLDecodedString
{
	NSString *result = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
																						   (CFStringRef)self,
																						   CFSTR(""),
																						   kCFStringEncodingUTF8);
    [result autorelease];
	return result;	
}

@end
