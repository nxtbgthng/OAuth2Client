//
//  NSMutableURLRequest+NXOAuth2.m
//  Soundcloud
//
//  Created by Ullrich Schäfer on 07.10.09.
//  Copyright 2009 nxtbgthng. All rights reserved.
//

#import "NSString+NXOAuth2.h"
#import "NSURL+NXOAuth2.h"

#import "NSMutableURLRequest+NXOAuth2.h"


@implementation NSMutableURLRequest (NXOAuth2)

- (NSDictionary *)parameters;
{
    NSString *encodedParameters;
    if ([[self HTTPMethod] isEqualToString:@"GET"] || [[self HTTPMethod] isEqualToString:@"DELETE"]) 
        encodedParameters = [[self URL] query];
	else 
	{
        // POST, PUT
        encodedParameters = [[[NSString alloc] initWithData:[self HTTPBody] encoding:NSASCIIStringEncoding] autorelease];
    }
    
    if ((encodedParameters == nil) || ([encodedParameters isEqualToString:@""]))
        return nil;
    
    NSArray *encodedParameterPairs = [encodedParameters componentsSeparatedByString:@"&"];
    NSMutableArray *requestParameters = [[NSMutableDictionary alloc] init];
    
    for (NSString *encodedPair in encodedParameterPairs) 
	{
        NSArray *encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
        [requestParameters setValue:[[encodedPairElements objectAtIndex:1] URLDecodedString]
							 forKey:[[encodedPairElements objectAtIndex:0] URLDecodedString]];
    }
	
    return [requestParameters autorelease];
}

- (void)setParameters:(NSDictionary *)parameters 
{
    NSMutableString *encodedParameterPairs = [NSMutableString string];
    
    int position = 1;
    for (NSString *key in [parameters allKeys]) 
	{
		NSString *value = [parameters valueForKey:key];
        [encodedParameterPairs appendFormat:@"%@=%@", [key URLEncodedString], [value URLEncodedString]];
        if (position < [parameters count])
            [encodedParameterPairs appendString:@"&"];
		
        position++;
    }
    
    if ([[self HTTPMethod] isEqualToString:@"GET"] || [[self HTTPMethod] isEqualToString:@"HEAD"] || [[self HTTPMethod] isEqualToString:@"DELETE"])
        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [[self URL] URLStringWithoutQuery], encodedParameterPairs]]];
    else 
	{
        // POST, PUT
        NSData *postData = [encodedParameterPairs dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        [self setHTTPBody:postData];
        [self setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
}

@end
