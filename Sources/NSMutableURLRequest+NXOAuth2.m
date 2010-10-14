//
//  NSMutableURLRequest+NXOAuth2.m
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

#import "NSMutableURLRequest+NXOAuth2.h"


@implementation NSMutableURLRequest (NXOAuth2)

- (NSDictionary *)nxoauth2_parameters;
{
    NSString *encodedParameters;
	if ([[self HTTPMethod] isEqualToString:@"POST"] || [[self HTTPMethod] isEqualToString:@"PUT"]) {
        encodedParameters = [[[NSString alloc] initWithData:[self HTTPBody] encoding:NSASCIIStringEncoding] autorelease];
	} else {
        encodedParameters = [[self URL] query];
    }
	
    return [encodedParameters nxoauth2_parametersFromEncodedQueryString];
}

- (void)nxoauth2_setParameters:(NSDictionary *)parameters 
{
	if ([[self HTTPMethod] isEqualToString:@"POST"] || [[self HTTPMethod] isEqualToString:@"PUT"]) {
		NSString *parametersString = [NSString nxoauth2_stringWithEncodedQueryParameters:parameters];
        NSData *postData = [parametersString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        [self setHTTPBody:postData];
        [self setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    } else {
		[self setURL:[self.URL nxoauth2_URLByAddingParameters:parameters]];
	}
}

@end
