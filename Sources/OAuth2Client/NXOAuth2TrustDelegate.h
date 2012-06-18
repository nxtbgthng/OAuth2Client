//
//  NXOAuth2TrustDelegate.h
//  OAuth2Client
//
//  Created by Thomas Kollbach on 24.05.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for
//  the full licence.
//

#import <Foundation/Foundation.h>
#import "NXOAuth2Constants.h"

@class NXOAuth2Connection;

/*!
 * The delegate of the NXOAuth2Connection or the NXOAuth2Client can both
 * optionally implement this protocol to ensure specific trust modes.
 *
 * If a NXOAuth2Connection is created with a NXOAuth2Client set and both
 * delegates conform to the NXOAuth2TrustDelegate protocol, the NXOAuth2Client's
 * delegate is used.
 */

@protocol NXOAuth2TrustDelegate <NSObject>

@optional

/*!
 * Specifies Trust mode for the specific hostname. See NXOAuth2Constants.h for constants
 */
-(NXOAuth2TrustMode)connection:(NXOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;

/*!
 * Array of NSData objects that contains the trusted certificates for the hostname.
 */
-(NSArray *)connection:(NXOAuth2Connection *)connection trustedCertificatesForHostname:(NSString *)hostname;

@end
