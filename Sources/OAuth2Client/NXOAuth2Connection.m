//
//  NXOAuth2Connection.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 26.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2PostBodyStream.h"

#import "NXOAuth2Connection.h"


@implementation NXOAuth2Connection

#pragma mark Lifecycle

- (id)initWithRequest:(NSURLRequest *)aRequest
		  oauthClient:(NXOAuth2Client *)aClient
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)aDelegate;
{
	if (self = [super init]) {
		statusCode = 0;
		expectedContentLength = 0;
		delegate = aDelegate;	// assign only
		client = [aClient retain];	// TODO: check if assign is better here
		
		NSURLRequest *request = [client sign:aRequest];	// TODO: sign
		
		NSInputStream *bodyStream = [request HTTPBodyStream];
		if ([bodyStream isKindOfClass:[NXOAuth2PostBodyStream class]]){
			[(NXOAuth2PostBodyStream *)bodyStream setMonitorDelegate:self];
		}
		
		connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];	// don't start yet
		[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];				// let's first schedule it in the current runloop. (see http://github.com/soundcloud/cocoa-api-wrapper/issues#issue/2 )
		[connection start];	// now start
	}
	return self;
}

- (void)dealloc;
{
	[client release];
	[connection cancel];
	[connection release];
	[super dealloc];
}


#pragma mark Accessors

@synthesize data;
@synthesize expectedContentLength, statusCode;
@synthesize context;


#pragma mark Public

- (void)cancel;
{
	[connection cancel];
	// maybe unschedule from current runloop now?...
}


#pragma mark -
#pragma mark SCPostBodyStream Delegate

- (void)stream:(NXOAuth2PostBodyStream *)stream hasBytesDelivered:(unsigned long long)deliveredBytes total:(unsigned long long)totalBytes;
{
	if ([delegate respondsToSelector:@selector(oauthConnection:didSendBytes:ofTotal:)]){
		[delegate oauthConnection:self didSendBytes:deliveredBytes ofTotal:totalBytes];
	}
}


#pragma mark NSURLConnectionDelegate

// TODO: handle request signed with expired token

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	expectedContentLength = response.expectedContentLength;
	statusCode = [(NSHTTPURLResponse *)response statusCode];
	
	if (!data) {
		data = [[NSMutableData alloc] init];
	} else {
		[data setLength:0];
	}
	if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
		[delegate oauthConnection:self didReceiveData:data];	// inform the delegate that we start with empty data
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)someData;
{
	[data appendData:someData];
	if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
		[delegate oauthConnection:self didReceiveData:someData];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	if(statusCode < 400) {
		if ([delegate respondsToSelector:@selector(oauthConnection:didFinishWithData:)]) {
			[delegate oauthConnection:self didFinishWithData:data];
		}
	} else {
		NSError *httpError = [NSError errorWithDomain:NSURLErrorDomain
												 code:statusCode
											 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													   [NSHTTPURLResponse localizedStringForStatusCode:statusCode], NSLocalizedDescriptionKey,
													   nil]];
		NSError *error = [NSError errorWithDomain:NXOAuth2ErrorDomain
											 code:NXOAuth2HTTPErrorCode
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   httpError, NXOAuth2HTTPErrorKey,
												   nil]];
		if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
			[delegate oauthConnection:self didFailWithError:error];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)httpError;
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  httpError, NXOAuth2HTTPErrorKey,
							  nil];
	NSError *error = [NSError errorWithDomain:NXOAuth2ErrorDomain
										 code:NXOAuth2HTTPErrorCode
									 userInfo:userInfo];
	if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
		[delegate oauthConnection:self didFailWithError:error];
	}
}


@end
