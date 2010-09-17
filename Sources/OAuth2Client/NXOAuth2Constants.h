//
//  NXOAuth2Constants.h
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import <Foundation/Foundation.h>


#pragma mark OAuth2 Errors

extern NSString * const NXOAuth2ErrorDomain;					// domain

extern NSInteger const NXOAuth2RedirectURIMismatchErrorCode;	// -2001
extern NSInteger const NXOAuth2UserDeniedErrorCode;				// -2002


#pragma mark HTTP Errors

extern NSString * const NXOAuth2HTTPErrorDomain;				// domain

// The error code represents the http status code


#pragma mark Notifications

extern NSString * const NXOAuth2DidStartConnection;
extern NSString * const NXOAuth2DidEndConnection;