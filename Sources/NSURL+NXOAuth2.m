//
//  NSURL+NXOAuth2.m
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

#import "NSURL+NXOAuth2.h"
#import "NXOAuth2Constants.h"

@implementation NSURL (NXOAuth2)

- (NSURL *)nxoauth2_URLByAddingParameters:(NSDictionary *)parameterDictionary {
    if (!parameterDictionary || [parameterDictionary count] == 0) {
        return self;
    }

    NSString *newParameterString = [NSString nxoauth2_stringWithEncodedQueryParameters:parameterDictionary];
    
    NSString *absoluteString = [self absoluteString];
    if ([absoluteString rangeOfString:@"?"].location == NSNotFound) {    // append parameters?
        absoluteString = [NSString stringWithFormat:@"%@?%@", absoluteString, newParameterString];
    } else {
        absoluteString = [NSString stringWithFormat:@"%@&%@", absoluteString, newParameterString];
    }

    return [NSURL URLWithString:absoluteString];
}

- (NSString *)nxoauth2_valueForQueryParameterKey:(NSString *)key;
{
    //self may not contain a scheme
    //for instance Google API redirect url may look like urn:ietf:wg:oauth:2.0:oob
    //NSURL requires a valid scheme or query will return nil
    NSString *absoluteString = self.absoluteString;
    if ([absoluteString rangeOfString:@"://"].location == NSNotFound) {
        absoluteString = [NSString stringWithFormat:@"http://%@", absoluteString];
    }    
    NSURL *qualifiedURL = [NSURL URLWithString:absoluteString];
    
    NSString *queryString = [qualifiedURL query];
    NSDictionary *parameters = [queryString nxoauth2_parametersFromEncodedQueryString];
    return [parameters objectForKey:key];
}

- (NSURL *)nxoauth2_URLWithoutQueryString;
{
    return [NSURL URLWithString:[self nxoauth2_URLStringWithoutQueryString]];
}

- (NSString *)nxoauth2_URLStringWithoutQueryString;
{
    NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}

- (NSError*) nxoauth2_redirectURLError
{
    NSURL* redirectURL = self;
    NSInteger errorCode = 0;
    NSDictionary *userInfo = nil;
    NSString *errorString = [redirectURL nxoauth2_valueForQueryParameterKey:@"error"];
    if (errorString) {
        NSString *localizedError = nil;
        
        if ([errorString caseInsensitiveCompare:@"invalid_request"] == NSOrderedSame) {
            errorCode = NXOAuth2InvalidRequestErrorCode;
            localizedError = NSLocalizedString(@"Invalid request to OAuth2 Server", @"NXOAuth2InvalidRequestErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"invalid_client"] == NSOrderedSame) {
            errorCode = NXOAuth2InvalidClientErrorCode;
            localizedError = NSLocalizedString(@"Invalid OAuth2 Client", @"NXOAuth2InvalidClientErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"unauthorized_client"] == NSOrderedSame) {
            errorCode = NXOAuth2UnauthorizedClientErrorCode;
            localizedError = NSLocalizedString(@"Unauthorized Client", @"NXOAuth2UnauthorizedClientErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"redirect_uri_mismatch"] == NSOrderedSame) {
            errorCode = NXOAuth2RedirectURIMismatchErrorCode;
            localizedError = NSLocalizedString(@"Redirect URI mismatch", @"NXOAuth2RedirectURIMismatchErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"access_denied"] == NSOrderedSame) {
            errorCode = NXOAuth2AccessDeniedErrorCode;
            localizedError = NSLocalizedString(@"Access denied", @"NXOAuth2AccessDeniedErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"unsupported_response_type"] == NSOrderedSame) {
            errorCode = NXOAuth2UnsupportedResponseTypeErrorCode;
            localizedError = NSLocalizedString(@"Unsupported response type", @"NXOAuth2UnsupportedResponseTypeErrorCode description");
            
        } else if ([errorString caseInsensitiveCompare:@"invalid_scope"] == NSOrderedSame) {
            errorCode = NXOAuth2InvalidScopeErrorCode;
            localizedError = NSLocalizedString(@"Invalid scope", @"NXOAuth2InvalidScopeErrorCode description");
        }
        
        if (localizedError) {
            userInfo = [NSDictionary dictionaryWithObject:localizedError forKey:NSLocalizedDescriptionKey];
        }
    }
    return [NSError errorWithDomain:NXOAuth2ErrorDomain
                               code:errorCode
                           userInfo:userInfo];
}

@end
