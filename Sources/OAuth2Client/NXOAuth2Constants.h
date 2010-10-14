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

// Error Codes from http://tools.ietf.org/html/draft-ietf-oauth-v2-10#section-3.2.1

/*
 * The request is missing a required parameter, includes an
 * unsupported parameter or parameter value, or is otherwise
 * malformed.
 */
extern NSInteger const NXOAuth2InvalidRequestErrorCode;			// -1001

/*
 * The client identifier provided is invalid.
 */
extern NSInteger const NXOAuth2InvalidClientErrorCode;			// -1002

/*
 * The client is not authorized to use the requested response
 * type.
 */
extern NSInteger const NXOAuth2UnauthorizedClientErrorCode;		// -1003

/*
 * The redirection URI provided does not match a pre-registered
 * value.
 */
extern NSInteger const NXOAuth2RedirectURIMismatchErrorCode;	// -1004

/*
 * The end-user or authorization server denied the request.
 */
extern NSInteger const NXOAuth2AccessDeniedErrorCode;			// -1005

/*
 * The requested response type is not supported by the
 * authorization server.
 */
extern NSInteger const NXOAuth2UnsupportedResponseTypeErrorCode;// -1006

/*
 * The requested scope is invalid, unknown, or malformed.
 */
extern NSInteger const NXOAuth2InvalidScopeErrorCode;			// -1007


#pragma mark HTTP Errors

extern NSString * const NXOAuth2HTTPErrorDomain;				// domain

// The error code represents the http status code


#pragma mark Notifications

extern NSString * const NXOAuth2DidStartConnection;
extern NSString * const NXOAuth2DidEndConnection;