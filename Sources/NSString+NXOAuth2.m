//
//  NSString+NXOAuth2.m
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

#import "NSString+NXOAuth2.h"


@implementation NSString (NXOAuth2)

+ (NSString *)nxoauth2_stringWithUUID;
{
    CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
    NSString *result = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID);
    CFRelease(theUUID);
    return result;
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

- (NSString *)nxoauth2_URLEncodedString;
{
    return (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, //Allocator
                                                                                  (__bridge CFStringRef)self, //Original String
                                                                                  NULL, //Characters to leave unescaped
                                                                                  CFSTR("!*'();:@&=+$,/?%#[]"), //Legal Characters to be escaped
                                                                                  kCFStringEncodingUTF8); //Encoding
}

- (NSString *)nxoauth2_URLDecodedString;
{
    return (__bridge_transfer NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                  (__bridge CFStringRef)self,
                                                                                                  CFSTR(""),
                                                                                                  kCFStringEncodingUTF8);
}

@end
