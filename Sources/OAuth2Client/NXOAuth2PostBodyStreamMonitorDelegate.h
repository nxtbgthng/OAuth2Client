/*
 *  NXOAuth2PostBodyStreamMonitorDelegate.h
 *  OAuth2Client
 *
 *  Created by Ullrich Schäfer on 27.08.10.
 *  Copyright 2010 nxtbgthng. All rights reserved. 
 *  Licenced under the new BSD-licence.
 *  See README.md in this reprository for 
 *  the full licence.
 *
 */

@class NXOAuth2PostBodyStream;

@protocol NXOAuth2PostBodyStreamMonitorDelegate <NSObject>
- (void)stream:(NXOAuth2PostBodyStream *)stream hasBytesDelivered:(unsigned long long)deliveredBytes total:(unsigned long long)totalBytes;
@end

