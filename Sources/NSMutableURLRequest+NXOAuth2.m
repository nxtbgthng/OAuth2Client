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
	if ([[self HTTPMethod] isEqualToString:@"POST"] || [[self HTTPMethod] isEqualToString:@"PUT"]) {
        encodedParameters = [[[NSString alloc] initWithData:[self HTTPBody] encoding:NSASCIIStringEncoding] autorelease];
	} else {
        encodedParameters = [[self URL] query];
    }
	
    return [encodedParameters parametersFromEncodedQueryString];
}

- (void)setParameters:(NSDictionary *)parameters 
{
	if ([[self HTTPMethod] isEqualToString:@"POST"] || [[self HTTPMethod] isEqualToString:@"PUT"]) {
		NSString *parametersString = [NSString stringWithEncodedQueryParameters:parameters];
        NSData *postData = [parametersString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        [self setHTTPBody:postData];
        [self setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    } else {
		[self setURL:[self.URL URLByAddingParameters:parameters]];
	}
}

@end
