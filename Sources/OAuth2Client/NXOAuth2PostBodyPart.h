//
//  NXOAuth2PostBodyPart.h
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

#import <Foundation/Foundation.h>


@interface NXOAuth2PostBodyPart : NSObject {
    NSString        *contentHeaders;
    NSInputStream    *contentStream;
    unsigned long long    contentLength;
}

@property (nonatomic, strong, readonly) NSString        *contentHeaders;
@property (nonatomic, strong, readonly) NSInputStream    *contentStream;
@property (nonatomic, assign, readonly) unsigned long long    contentLength;


/*!
 *    Convenience methods
 *
 *    Note: possible types for content are
 *    - NSString
 *    - NSURL (local file URL)
 *    - NSData
 *    - NXOAuth2FileStreamWrapper
 */
+ (instancetype)partWithName:(NSString *)name
                     content:(id)content;

- (instancetype)initWithName:(NSString *)name
                     content:(id)content;

- (instancetype)initWithHeaders:(NSString *)headers
                    dataContent:(NSData *)data;

- (instancetype)initWithName:(NSString *)name
               streamContent:(NSInputStream *)stream
                streamLength:(unsigned long long)streamLength
                    fileName:(NSString *)fileName;

- (instancetype)initWithHeaders:(NSString *)headers
                  streamContent:(NSInputStream *)stream
                         length:(unsigned long long)length; //designated initializer

@end
