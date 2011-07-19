//
//  NXOAuth2Account+Private.h
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 19.07.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#import "NXOAuth2Account.h"

@interface NXOAuth2Account (Private)
- (id)initAccountWithOAuthClient:(NXOAuth2Client *)oauthClient accountType:(NSString *)accountType;
@end
