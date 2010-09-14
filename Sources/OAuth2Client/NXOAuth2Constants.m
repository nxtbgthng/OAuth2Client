//
//  NXOAuth2Constants.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import "NXOAuth2Constants.h"


#pragma mark OAuth2 Errors

NSString * const NXOAuth2ErrorDomain = @"NXOAuth2ErrorDomain";

NSInteger const NXOAuth2RedirectURIMismatchErrorCode = -2001;
NSInteger const NXOAuth2UserDeniedErrorCode = -2002;


#pragma mark HTTP Errors

NSString * const NXOAuth2HTTPErrorDomain = @"NXOAuth2HTTPErrorDomain";

// The error code represents the http status code
