//
//  NXOAuth2Connection.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved. 
//  Licenced under the new BSD-licence.
//  See README.md in this reprository for 
//  the full licence.
//

#import "NSURL+NXOAuth2.h"
#import "NSData+NXOAuth2.h"

#import "NXOAuth2PostBodyStream.h"
#import "NXOAuth2ConnectionDelegate.h"
#import "NXOAuth2Client.h"
#import "NXOAuth2AccessToken.h"

#import "NXOAuth2Connection.h"

@interface NXOAuth2Client (Private)
- (void)removeConnectionFromWaitingQueue:(NXOAuth2Connection *)connection;
@end



@interface NXOAuth2Connection ()
- (NSURLConnection *)createConnection;
- (NSString *)descriptionForRequest:(NSURLRequest *)request;
- (void)applyParameters:(NSDictionary *)parameters onRequest:(NSMutableURLRequest *)request;
- (BOOL)trustsAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
						  forHostname:(NSString *)hostname
						withTrustMode:(NXOAuth2TrustMode)trustMode;
- (BOOL)isServerCertificateForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
										  andHostname:(NSString *)hostname
								  matchingCertificate:(NSData *)derCertData;
@property (nonatomic, retain, readonly) id<NXOAuth2TrustDelegate> trustDelegate;


@end


@implementation NXOAuth2Connection

#pragma mark Lifecycle

#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
- (id)initWithRequest:(NSMutableURLRequest *)aRequest
	requestParameters:(NSDictionary *)someRequestParameters
		  oauthClient:(NXOAuth2Client *)aClient
               finish:(void (^)(void))finishBlock 
                 fail:(void (^)(NSError *error))failBlock;
{
    if ([self initWithRequest:aRequest requestParameters:someRequestParameters oauthClient:aClient delegate:nil]) {
        finish = Block_copy(finishBlock);
        fail = Block_copy(failBlock);
    }
    return self;
}
#endif

- (id)initWithRequest:(NSMutableURLRequest *)aRequest
	requestParameters:(NSDictionary *)someRequestParameters
		  oauthClient:(NXOAuth2Client *)aClient
			 delegate:(NSObject<NXOAuth2ConnectionDelegate> *)aDelegate;
{
	self = [super init];
	if (self) {
		sentConnectionDidEndNotification = NO;
		delegate = aDelegate;	// assign only
		client = [aClient retain];
		
		request = [aRequest copy];
		requestParameters = [someRequestParameters copy];
		connection = [[self createConnection] retain];
        savesData = YES;
	}
	return self;
}

- (void)dealloc;
{
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
    Block_release(fail);
    Block_release(finish);
#endif
	[connection cancel];
	[connection release];
	[data release];
	[client release];
	[response release];
	[request release];
	[requestParameters release];
	[context release];
	[userInfo release];
    
#if (NXOAuth2ConnectionDebug)
	[startDate release];
#endif
    
	[super dealloc];
}


#pragma mark Accessors

@synthesize delegate;
@synthesize data;
@synthesize context, userInfo;
@synthesize savesData;


- (id<NXOAuth2TrustDelegate>)trustDelegate;
{
    // if a client is set and implemnts the trustModeForHostname: it is preferred
    // in making trust desicions. 
    // The second choice 
    if (client && [client.delegate conformsToProtocol:@protocol(NXOAuth2TrustDelegate)]) {
    	return (id<NXOAuth2TrustDelegate>)client.delegate; 
    } else if ([delegate conformsToProtocol:@protocol(NXOAuth2TrustDelegate)]) {
		return (id<NXOAuth2TrustDelegate>)delegate;  
    }
	return nil;
}

- (NSInteger)statusCode;
{
	NSHTTPURLResponse *httpResponse = nil;
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
		httpResponse = (NSHTTPURLResponse *)response;
	return httpResponse.statusCode;
}

- (long long)expectedContentLength;
{
	return response.expectedContentLength;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"NXOAuth2Connection <%@>", request.URL];
}

#pragma mark Public

- (void)cancel;
{
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
	[connection cancel];
	[client removeConnectionFromWaitingQueue:self];
}

- (void)retry;
{
	[response release]; response = nil;
	[connection cancel]; [connection release];
	connection = [[self createConnection] retain];
}


#pragma mark Private

- (NSURLConnection *)createConnection;
{
	// if token is expired don't bother starting this connection.
	NSDate *tenSecondsAgo = [NSDate dateWithTimeIntervalSinceNow:(-10)];
	NSDate *tokenExpiresAt = client.accessToken.expiresAt;
	if ([tenSecondsAgo earlierDate:tokenExpiresAt] == tokenExpiresAt) {
		[self cancel];
		[client refreshAccessTokenAndRetryConnection:self];
		return nil;
	}
	
	NSMutableURLRequest *startRequest = [[request mutableCopy] autorelease];
	[self applyParameters:requestParameters onRequest:startRequest];
	
	if (client.accessToken) {
		[startRequest setValue:[NSString stringWithFormat:@"OAuth %@", client.accessToken.accessToken]
			forHTTPHeaderField:@"Authorization"];
	}
	
	if (client.userAgent && ![startRequest valueForHTTPHeaderField:@"User-Agent"]) {
		[startRequest setValue:client.userAgent
			forHTTPHeaderField:@"User-Agent"];
	}
	
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:startRequest delegate:self startImmediately:NO];	// don't start yet
	[aConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];	// let's first schedule it in the current runloop. (see http://github.com/soundcloud/cocoa-api-wrapper/issues#issue/2 )
	[aConnection start];	// now start
    
#if (NXOAuth2ConnectionDebug)
    [startDate release]; startDate = [[NSDate alloc] init];
#endif
	
	if (!sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidStartConnection object:self];
	sentConnectionDidEndNotification = YES;
	
	return [aConnection autorelease];
}

- (NSString *)descriptionForRequest:(NSURLRequest *)aRequest;
{
	NSString *range = [aRequest valueForHTTPHeaderField:@"Range"];
	if (!range) {
		return aRequest.URL.absoluteString;
	}
	return [NSString stringWithFormat:@"%@ [%@]", aRequest.URL.absoluteString, range];
}

- (void)applyParameters:(NSDictionary *)parameters onRequest:(NSMutableURLRequest *)aRequest;
{
	if (!parameters) return;
	
	NSString *httpMethod = [aRequest HTTPMethod];
	if ([httpMethod caseInsensitiveCompare:@"POST"] != NSOrderedSame
		&& [httpMethod caseInsensitiveCompare:@"PUT"] != NSOrderedSame) {
		aRequest.URL = [aRequest.URL nxoauth2_URLByAddingParameters:parameters];
	} else {
		NSInputStream *postBodyStream = [[NXOAuth2PostBodyStream alloc] initWithParameters:parameters];
		
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", [(NXOAuth2PostBodyStream *)postBodyStream boundary]];
		NSString *contentLength = [NSString stringWithFormat:@"%d", [(NXOAuth2PostBodyStream *)postBodyStream length]];
		[aRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
		[aRequest setValue:contentLength forHTTPHeaderField:@"Content-Length"];
		
		[aRequest setHTTPBodyStream:postBodyStream];
		[postBodyStream release];
	}
}


- (BOOL)trustsAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
						  forHostname:(NSString *)hostname
						withTrustMode:(NXOAuth2TrustMode)trustMode;
{
	if (trustMode & NXOAuth2TrustModeAnyCertificate) {
		return YES;
	}
	
	if (trustMode & NXOAuth2TrustModeSystem) {
		SecTrustResultType trustEvalResult = kSecTrustResultInvalid;
		OSStatus ossTrust = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &trustEvalResult);
		
		if (ossTrust != errSecSuccess) {
			NSLog(@"Trust evaluation failed for domain %@. Rejecting cert.", hostname);
			return NO;
		}
		
		// TODO: The result might also be kSecTrustResultConfirm
		// But to be safe we ignore this for now
		// if it is kSecTrustResultConfirm, there could be another delegate
		// method that allows to show a delegate UI
		if (trustEvalResult == kSecTrustResultProceed ||
			trustEvalResult == kSecTrustResultUnspecified) {
			return YES;
		}
	}
	
	
	if (trustMode & NXOAuth2TrustModeSpecificCertificate) {
		NSAssert([self.trustDelegate respondsToSelector:@selector(connection:trustedCertificatesForHostname:)],
				 @"For NXOAuth2TrustModeSpecificCertificate the delegate needs to implement oauthConnection:trustedCertificatesDERDataForHostname:");
		NSArray *trustedCerts = [self.trustDelegate connection:self trustedCertificatesForHostname:hostname];
		
        for (NSData* trustedCert in trustedCerts) {
            if ([self isServerCertificateForAuthenticationChallenge:challenge
                                                        andHostname:hostname
                                                matchingCertificate:trustedCert]) {
                return YES;
            }
        }
	}
	
	return NO;
}


- (BOOL)isServerCertificateForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
										  andHostname:(NSString *)hostname
								  matchingCertificate:(NSData *)derCertData;
{
	if (derCertData == nil) {
		return NO;
	}
	
	SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
	SecCertificateRef anchorCert = SecCertificateCreateWithData(NULL,(CFDataRef)derCertData);
	
	if(anchorCert == nil) {
		return NO;
	}
	
	CFArrayRef allTrustedCert = (CFArrayRef)[NSArray arrayWithObject:(id)anchorCert];
	
	CFRelease(anchorCert);
	
	SecTrustSetAnchorCertificates(serverTrust, allTrustedCert);
	SecTrustSetAnchorCertificatesOnly(serverTrust, YES);
	
	SecTrustResultType checkResult;
	OSStatus ossTrust = SecTrustEvaluate(serverTrust, &checkResult);
	
	if (ossTrust != errSecSuccess) {
		return NO;
	}
	
	if (checkResult == kSecTrustResultProceed || checkResult == kSecTrustResultUnspecified) {
		return YES;
	} else if (checkResult == kSecTrustResultRecoverableTrustFailure) {
		// In this case me check if any of the certs is our trusted cert.
		
		OSStatus errGetTrustResult = noErr;
		CFArrayRef certificates = (CFArrayRef)[NSMutableArray array];
		
#if TARGET_OS_IPHONE
		
		// The iOS way of getting the certs.
		for (CFIndex index = 0; index < SecTrustGetCertificateCount(serverTrust); index++) {
			SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, index);
			[(NSMutableArray *)certificates addObject:(id)certificate];
		}
		
#else
		
		// OS X way of getting to the certs.
		CSSM_TP_APPLE_EVIDENCE_INFO *statusChain;
		errGetTrustResult = SecTrustGetResult(serverTrust, &checkResult, &certificates, &statusChain);
		
#endif
		if (errGetTrustResult == noErr) {
			// find if any cert in the chain matches the provided cert.
			for (CFIndex index = 0; index < CFArrayGetCount(certificates); index++) {
				SecCertificateRef certificate = (SecCertificateRef)CFArrayGetValueAtIndex(certificates, index);
				CFDataRef certData = SecCertificateCopyData(certificate);
				NSData *certificateData = [NSData dataWithData:(NSData *)certData];
				CFRelease(certData);
				
				NSString *certificateChecksum = [(NSData *)certificateData nx_SHA1Hexdigest];
				NSString *anchorCertChecksum = [derCertData nx_SHA1Hexdigest];
				
				if ([anchorCertChecksum isEqualToString:certificateChecksum]) {
					return YES;
				}
				
			}
			
			return NO;
		} else {
			return NO;
		}
	}
	
	return NO;
}


#pragma mark -
#pragma mark SCPostBodyStream Delegate

- (void)stream:(NXOAuth2PostBodyStream *)stream didSendBytes:(unsigned long long)deliveredBytes ofTotal:(unsigned long long)totalBytes;
{
	if ([delegate respondsToSelector:@selector(oauthConnection:didSendBytes:ofTotal:)]){
		[delegate oauthConnection:self didSendBytes:deliveredBytes ofTotal:totalBytes];
	}
}


#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)theResponse;
{
#if (NXOAuth2ConnectionDebug)
    NSLog(@"%.0fms (RESP) - %@", -[startDate timeIntervalSinceNow]*1000.0, [self descriptionForRequest:request]);
#endif
    
	[response release];
	response = [theResponse retain];
	
    if (savesData) {
        if (!data) {
            data = [[NSMutableData alloc] init];
        } else {
            [data setLength:0];
        }
    }
	
	NSString *authenticateHeader = nil;
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSDictionary *headerFields = [(NSHTTPURLResponse *)response allHeaderFields];
		for (NSString *headerKey in headerFields.allKeys) {
			if ([[headerKey lowercaseString] isEqualToString:@"www-authenticate"]) {
				authenticateHeader = [headerFields objectForKey:headerKey];
				break;
			}
		}
	}
	if (/*self.statusCode == 401 // TODO: check for status code once the bug returning 500 is fixed
		 &&*/ client.accessToken.refreshToken != nil
		&& authenticateHeader
		&& [authenticateHeader rangeOfString:@"expired_token"].location != NSNotFound) {
		[self cancel];
		[client refreshAccessTokenAndRetryConnection:self];
	} else {
		if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
			[delegate oauthConnection:self didReceiveData:data];	// inform the delegate that we start with empty data
		}
		if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveResponse:)]) {
			[delegate oauthConnection:self didReceiveResponse:theResponse];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)someData;
{
    if (savesData) {
        [data appendData:someData];
    }
	if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveData:)]) {
		[delegate oauthConnection:self didReceiveData:someData];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
#if (NXOAuth2ConnectionDebug)
    NSLog(@"%.0fms (SUCC) - %@", -[startDate timeIntervalSinceNow]*1000.0, [self descriptionForRequest:request]);
#endif
    
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
	if(self.statusCode < 400) {
		if ([delegate respondsToSelector:@selector(oauthConnection:didFinishWithData:)]) {
			[delegate oauthConnection:self didFinishWithData:data];
		}
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
        if (finish) finish();
#endif
	} else {
		if (self.statusCode == 401) {
			// check if token is still valid
			NSString *authenticateHeader = nil;
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				NSDictionary *headerFields = [(NSHTTPURLResponse *)response allHeaderFields];
				for (NSString *headerKey in headerFields.allKeys) {
					if ([[headerKey lowercaseString] isEqualToString:@"www-authenticate"]) {
						authenticateHeader = [headerFields objectForKey:headerKey];
						break;
					}
				}
			}
			if (authenticateHeader
				&& [authenticateHeader rangeOfString:@"invalid_token"].location != NSNotFound) {
				client.accessToken = nil;
			}
		}
		
		NSString *localizedError = [NSString stringWithFormat:NSLocalizedString(@"HTTP Error: %d", @"NXOAuth2HTTPErrorDomain description"), self.statusCode];
		NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObject:localizedError forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:NXOAuth2HTTPErrorDomain
											 code:self.statusCode
										 userInfo:errorUserInfo];
		if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
			[delegate oauthConnection:self didFailWithError:error];
		}
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
        if (fail) fail(error);
#endif
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
#if (NXOAuth2ConnectionDebug)
    NSLog(@"%.0fms (FAIL) - %@ (%@ %i)", -[startDate timeIntervalSinceNow]*1000.0, [self descriptionForRequest:request], [error domain], [error code]);
#endif
    
	if (sentConnectionDidEndNotification) [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2DidEndConnection object:self];
	sentConnectionDidEndNotification = NO;
	
	if ([delegate respondsToSelector:@selector(oauthConnection:didFailWithError:)]) {
		[delegate oauthConnection:self didFailWithError:error];
	}
#if NX_BLOCKS_AVAILABLE && NS_BLOCKS_AVAILABLE
    if (fail) fail(error);
#endif
}

- (NSURLRequest *)connection:(NSURLConnection *)aConnection willSendRequest:(NSURLRequest *)aRequest redirectResponse:(NSURLResponse *)aRedirectResponse;
{
	
	if (!aRedirectResponse) {
#if (NXOAuth2ConnectionDebug)
		NSLog(@"%.0fms (WILL) - %@", -[startDate timeIntervalSinceNow]*1000.0, [self descriptionForRequest:aRequest]);
#endif
		return aRequest; // if not redirecting do nothing
	}
	
	if ([delegate respondsToSelector:@selector(oauthConnection:didReceiveRedirectToURL:)]) {
		[delegate oauthConnection:self didReceiveRedirectToURL:aRequest.URL];
	}
	
#if (NXOAuth2ConnectionDebug)
    NSLog(@"%.0fms (REDI) - %@ > %@", -[startDate timeIntervalSinceNow]*1000.0, aRedirectResponse.URL.absoluteString, [self descriptionForRequest:aRequest]);
#endif
	BOOL hostChanged = [aRequest.URL.host caseInsensitiveCompare:aRedirectResponse.URL.host] != NSOrderedSame;
	
	BOOL schemeChanged = [aRequest.URL.scheme caseInsensitiveCompare:aRedirectResponse.URL.scheme] != NSOrderedSame;
	BOOL schemeChangedToHTTPS = schemeChanged && ([aRequest.URL.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame);
	
	NSMutableURLRequest *mutableRequest = [[aRequest mutableCopy] autorelease];
	mutableRequest.HTTPMethod = request.HTTPMethod;
	
	if(hostChanged
	   || (schemeChanged && !schemeChangedToHTTPS)) {
		
		[mutableRequest setValue:nil forHTTPHeaderField:@"Authorization"]; // strip Authorization information
		return mutableRequest;
	}
	return mutableRequest;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
{
	if ([delegate respondsToSelector:@selector(oauthConnection:didSendBytes:ofTotal:)]) {
		[delegate oauthConnection:self didSendBytes:totalBytesWritten ofTotal:totalBytesExpectedToWrite];
	}
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)aRequest;
{
	return [[[NXOAuth2PostBodyStream alloc] initWithParameters:requestParameters] autorelease];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
{
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		NSString *hostname = challenge.protectionSpace.host;
		
		NXOAuth2TrustMode effectiveTrustMode = NXOAuth2TrustModeSystem;
		if (self.trustDelegate) {
			effectiveTrustMode = [self.trustDelegate connection:self trustModeForHostname:hostname];
		}
		BOOL shouldTrustCerificate = [self trustsAuthenticationChallenge:challenge
															 forHostname:hostname
														   withTrustMode:effectiveTrustMode];
		
		if (shouldTrustCerificate) {
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
				 forAuthenticationChallenge:challenge];
		} else {
			[challenge.sender cancelAuthenticationChallenge:challenge];
		}
		
	} else {
		
        if ( [challenge previousFailureCount] == 0 ) {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        } else {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
	}
}

@end
