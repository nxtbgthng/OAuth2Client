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


// Custom Error codes

/*
 * The connection failed because the token expired and could not be refreshed
 */
extern NSInteger const NXOAuth2CouldNotRefreshTokenErrorCode;	// -2001


#pragma mark HTTP Errors

extern NSString * const NXOAuth2HTTPErrorDomain;				// domain

// The error code represents the http status code


#pragma mark Notifications

extern NSString * const NXOAuth2DidStartConnection;
extern NSString * const NXOAuth2DidEndConnection;

extern NSString * const NXOAuth2AccountCreated;
extern NSString * const NXOAuth2AccountRemoved;

extern NSString * const NXOAuth2AccountStoreDidFailToRequestAccess;

extern NSString * const NXOAuth2AccountDidChangeUserData;
extern NSString * const NXOAuth2AccountDidChangeAccessToken;
extern NSString * const NXOAuth2AccountDidFailToGetAccessToken;



#pragma mark TLS Trust Modes

/*
 * Implement the connection:trustModeForHostname: method from the
 * NXOAuth2ConnectionDelegate protocol to specify how certificates provided by
 * TLS/SSL secured hosts should be trusted.
 * If connection:trustModeForHostname: is not implemented the default
 * NXOAuth2TrustModeSystem is assumed.
 * 
 * Note that you can return multiple flags. If you to a match on any trust mode
 * will be interpreted as trusting the server (basically the are ORed)
 * 
 * If you specify NXOAuth2TrustModeSpecificCertificate you need to also
 * implement connection:trustedCertificatesDERDataForHostname: and provide the
 * trusted certificate as DER-encoded NSData. NXOAuth2TrustModeSpecificCertificate
 * just ensures that any certificate in the chain is equal to the provided one.
 * 
 * See SecCertificateCreateWithData and SecCertificateCopyData from the
 * Security Framework for further reference.
 */

typedef enum  {
	NXOAuth2TrustModeAnyCertificate      = 1 << 0,
	NXOAuth2TrustModeSystem              = 1 << 1,
	NXOAuth2TrustModeSpecificCertificate = 1 << 2
} NXOAuth2TrustMode;


#pragma mark OAuth2 Configuration

extern NSString * const kNXOAuth2AccountStoreConfigurationClientID;
extern NSString * const kNXOAuth2AccountStoreConfigurationSecret;
extern NSString * const kNXOAuth2AccountStoreConfigurationAuthorizeURL;
extern NSString * const kNXOAuth2AccountStoreConfigurationTokenURL;
extern NSString * const kNXOAuth2AccountStoreConfigurationRedirectURL;

extern NSString * const kNXOAuth2AccountStoreAccountType;
extern NSString * const kNXOAuth2AccountStoreError;

