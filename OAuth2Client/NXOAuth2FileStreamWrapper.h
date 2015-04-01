//
//  NXOAuth2FileStreamWrapper.h
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


@interface NXOAuth2FileStreamWrapper : NSObject {
    NSInputStream        *stream;
    unsigned long long    contentLength;
    NSString            *fileName;
    NSString            *contentType;
}
@property (nonatomic, strong, readonly) NSInputStream *stream;
@property (nonatomic, assign, readonly) unsigned long long contentLength;
@property (nonatomic, copy, readonly) NSString *fileName;
@property (nonatomic, copy) NSString *contentType; // optional DEFAULT: "application/octettstream"

+ (instancetype)wrapperWithStream:(NSInputStream *)stream
                    contentLength:(unsigned long long)contentLength DEPRECATED_ATTRIBUTE;

- (instancetype)initWithStream:(NSInputStream *)stream
                 contentLength:(unsigned long long)contentLength DEPRECATED_ATTRIBUTE;

+ (instancetype)wrapperWithStream:(NSInputStream *)stream
                    contentLength:(unsigned long long)contentLength
                         fileName:(NSString *)fileName;

- (instancetype)initWithStream:(NSInputStream *)stream
                 contentLength:(unsigned long long)contentLength
                      fileName:(NSString *)fileName;

@end
