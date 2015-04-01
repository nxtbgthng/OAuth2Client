//
//  NXApplication.h
//  OAuth2Client
//
//  Created by Oleksandr Dodatko on 2/2/15.
//  Copyright (c) 2015 nxtbgthng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NXApplication <NSObject>

-(BOOL)openURL:(NSURL*)url;

@end
