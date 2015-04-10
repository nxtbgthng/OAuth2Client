//
//  NXOAuth2RequestCallbacks.h
//  OAuth2Client
//
//  Created by Oleksandr Dodatko on 2/2/15.
//  Copyright (c) 2015 nxtbgthng. All rights reserved.
//

#ifndef OAuth2Client_NXOAuth2RequestCallbacks_h
#define OAuth2Client_NXOAuth2RequestCallbacks_h


#import <Foundation/Foundation.h>

typedef void(^NXOAuth2ConnectionResponseHandler)(NSURLResponse *response, NSData *responseData, NSError *error);
typedef void(^NXOAuth2ConnectionSendingProgressHandler)(unsigned long long bytesSend, unsigned long long bytesTotal);


#endif
