//
//  NXOAuth2Constants.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//
//  Copyright 2010 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import "NXOAuth2Constants.h"


#pragma mark OAuth2 Errors

NSString * const NXOAuth2ErrorDomain = @"NXOAuth2ErrorDomain";

NSInteger const NXOAuth2InvalidRequestErrorCode            = -1001;
NSInteger const NXOAuth2InvalidClientErrorCode            = -1002;
NSInteger const NXOAuth2UnauthorizedClientErrorCode        = -1003;
NSInteger const NXOAuth2RedirectURIMismatchErrorCode    = -1004;
NSInteger const NXOAuth2AccessDeniedErrorCode            = -1005;
NSInteger const NXOAuth2UnsupportedResponseTypeErrorCode = -1006;
NSInteger const NXOAuth2InvalidScopeErrorCode            = -1007;

NSInteger const NXOAuth2CouldNotRefreshTokenErrorCode    = -2001;


#pragma mark HTTP Errors

NSString * const NXOAuth2HTTPErrorDomain = @"NXOAuth2HTTPErrorDomain";
// The error code represents the http status code


#pragma mark UserInfo Keys

NSString * const NXOAuth2AccountStoreErrorKey = @"NXOAuth2AccountStoreErrorKey";
NSString * const NXOAuth2ErrorResponseDataKey = @"NXOAuth2ErrorResponseDataKey";