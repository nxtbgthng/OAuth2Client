# OAuth2Client

An OAuth2 library for Mac OS X & iOS (Cocoa & Cocoa touch).

## Description

This library is based on [draft 10 of the OAuth2 spec](http://tools.ietf.org/html/draft-ietf-oauth-v2-10).
It implements the [native application profile](http://tools.ietf.org/html/draft-ietf-oauth-v2-10#section-1.4.3)
and supports the end-user authorization endpoint via an internal or an external user-agent. Furthermore it
also supports the user credentials flow by prompting the end-user for their username and password and use them
directly to obtain an access token. See the description of the delegate for more information how to choose the
authentication flow.

## Getting started

### Get the sources

Getting the sources is as easy as doing a:  
`git clone git://github.com/nxtbgthng/OAuth2Client.git`

### Adding the library to your project using CocoaPods
[CocoaPods](http://cocoapods.org/) is a dependency manager for Xcode projects. It manages the above
installation steps automatically.

In order to install the library this way add the following line to your `Podfile`:

```pod 'NXOAuth2Client', '~> 1.2.6'```

and run the following command `pod install`.

*Note:* CocoaPods is now the preferred way to integrate NXOAuth2Client into XCode

### Manually including the library in your Xcode project

#### iOS projects

* Place the _OAuth2Client_ folder within your source root
* Drag the _OAuth2Client.xcodeproj_ into your project
* Under your build target, select the _Build Phases_ tab.
    * Under _Target Dependencies_ add _OAuth2Client_
    * Under _Link Binary With Libraries_, add _libOAuth2Client.a_
* Under _Build Settings_,
    * Add `$(SRCROOT)/path/to/OAuth2Client` _Header Search Paths_, set as _recursive_
    * Add `-ObjC` to _Other Linker Flags_
* `#import "NXOAuth2.h"`
* add the Security.framework as a build dependency

#### Desktop Mac projects

- drag the OAuth2Client.xcodeproj into your project
- add OAuth2Client.framework as a build dependency
- add the Security.framework as a build dependency
- add `$(CONFIGURATION_BUILD_DIR)/$(CONTENTS_FOLDER_PATH)/Frameworks` to your targets Framework Search Path
- link your target against OAuth2Client (drag the OAuth2Client.framework product from OAuth2Client.xcodeproj
to your targets *Link Binary With Libraries*)
- `#import <OAuth2Client/NXOAuth2.h>`

*Using the library as a framework in desktop applications is fairly untested. Please
[report any issues](http://github.com/nxtbgthng/OAuth2Client/issues) and help in making the library better.*



## Using the OAuth2Client

### Configure your Client

The best place to configure your client is `+[UIApplicationDelegate initialize]` on iOS or `+[NSApplicationDelegate initialize]` on Mac OS X. There you can call `-[NXOAuth2AccountStore setClientID:secret:authorizationURL:tokenURL:redirectURL:forAccountType:]` on the shared account store for each service you want to have access to from your application. The account type is a string which is used as an identifier for a certain service.

<pre>
+ (void)initialize;
{
	[[NXOAuth2AccountStore sharedStore] setClientID:@"xXxXxXxXxXxX"
                                             secret:@"xXxXxXxXxXxX"
                                   authorizationURL:[NSURL URLWithString:@"https://...your auth URL..."]
                                           tokenURL:[NSURL URLWithString:@"https://...your token URL..."]
                                        redirectURL:[NSURL URLWithString:@"https://...your redirect URL..."]
                                     forAccountType:@"myFancyService"];
}
</pre>

### Requesting Access to a Service

Once you have configured your client you are ready to request access to one of those services. The NXOAuth2AccountStore provides three different methods for this:

- Username and Password
 <pre>
 [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"myFancyService"
 	                                                       username:aUserName
 	                                                       password:aPassword];
 </pre>

- External Browser
 <pre>
 [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"myFancyService"];
 </pre>
  
 If you are using an external browser, your application needs to handle the URL you have registered as an redirect URL for the account type. The service will redirect to that URL after the authentication process.

- Provide an Authorization URL Handler
 <pre>
 [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"myFancyService"
 	                            withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
 	                                // Open a web view or similar
 	                            }];
 </pre>
 Using an authorization URL handler gives you the ability to open the URL in an own web view or do some fancy stuff for authentication. Therefor you pass a block to the NXOAuth2AccountStore while requesting access.

#### On Success

After a successful authentication, a new `NXOAuth2Account` object is in the list of accounts of `NXOAuth2AccountStore`. You will receive a notification of type `NXOAuth2AccountStoreAccountsDidChangeNotification`, e.g., for updating your UI.
<pre>
[[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                  object:[NXOAuth2AccountStore sharedStore]
                                                   queue:nil
                                              usingBlock:^(NSNotification *aNotification){
                                                    // Update your UI
                                              }];
</pre>
If an account was added the `userInfo` dictionary of the notification will contain the new account at the `NXOAuth2AccountStoreNewAccountUserInfoKey`. Note though that this notification can be triggered on other events (e.g. account removal). In that case this key will not be set.

#### On Failure

If the authentication did not succeed, a notification of type `NXOAuth2AccountStoreDidFailToRequestAccessNotification` containing an `NSError` will be send.
<pre>
[[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                  object:[NXOAuth2AccountStore sharedStore]
                                                   queue:nil
                                              usingBlock:^(NSNotification *aNotification){
                                                    NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                    // Do something with the error
                                              }];
</pre>

### Getting a List of all Accounts

The authenticated accounts can be accessed via the `NXOAuth2AccountStore`. Either the complete list, only a list of accounts for a specific service or an account with an identifier (maybe cached in the user settings).

<pre>
for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accounts]) {
    // Do something with the account
};

for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"myFancyService"]) {
    // Do something with the account
};

NXOAuth2Account *account = [[NXOAuth2AccountStore sharedStore] accountWithIdentifier:@"...cached account id..."];
</pre>

Each `NXOAuth2Account` has a property `userData` which can be used to store some related information for that account.
<pre>
NXOAuth2Account *account = // ... get an account
NSDictionary *userData = // ...

account.userData = userData;
</pre>

This payload will be stored together with the accounts in the Keychain. Thus it shouldn't be to big.

### Invoking a Request

An request using the authentication for a service can be invoked via `NXOAuth2Request`. The most convenient method (see below) is a class method which you pass the method, a resource and some parameters (or nil) for the request and to handlers (both optional). One for a progress and the other for the response. The account is used for authentication and can be nil. Then a normal request without authentication will be invoked.
<pre>
[NXOAuth2Request performMethod:@"GET"
                    onResource:[NSURL URLWithString:@"https://...your service URL..."]
               usingParameters:nil
                   withAccount:anAccount
           sendProgressHandler:^(unsigned long long bytesSend, unsigned long long bytesTotal) { // e.g., update a progress indicator }
               responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                   // Process the response
               }];
</pre>

#### Getting a signed NSURLRequest

In some circumstances you have to go the *god old way* and use an `NSURLConnection`. Maybe if you to download a large file. Therefor `NXOAuth2Request` gives you the possibility to get an `NSURLRequest` containing the additional information to authenticate that request.

<pre>
NXOAuth2Request *theRequest = [[NXOAuth2Request alloc] initWithResource:[NSURL URLWithString:@"https://...your service URL..."]
									                             method:@"GET"
								                             parameters:nil];
theRequest.account = // ... an account
                               
NSURLRequest *sigendRequest = [theRequest signedURLRequest];

[theRequest release];

// Invoke the request with you preferd method
</pre>

#### Fully Parametrized File Upload

<pre>
// Get fileSize
NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:uploadFile.localDataFilePath error:nil];
NSNumber *fileSize = [fileAttributes valueForKey:NSFileSize];

// Create a stream wrapper for the upload file
NXOAuth2FileStreamWrapper* w =[NXOAuth2FileStreamWrapper
    wrapperWithStream:[NSInputStream inputStreamWithFileAtPath:uploadFile.localDataFilePath]
        contentLength:[fileSize unsignedLongLongValue]
             fileName:uploadFile.remoteFilename];

if([uploadFile.remoteFilename hasSuffix:@".json"])
    w.contentType = @"application/json";
else
    if([uploadFile.remoteFilename hasSuffix:@".jpg"])
        w.contentType = @"image/jpeg";

// POST Content-Disposition: form-data; name="file"; filename=uploadFile.remoteFilename
[NXOAuth2Request performMethod:@"POST" onResource:uploadFile.uploadURL usingParameters:@{@"file": w} withAccount:account
           sendProgressHandler:... responseHandler: ...];
</pre>


## Contributing & Pull Requests

Patches and pull requests are welcome! We are sorry if it takes a while to review them, but sooner or later we will get to yours.

Not that we are using the [git-flow](http://nvie.com/posts/a-successful-git-branching-model/) model of branching and releasing, so **please make pull requests against the develop branch** to make merging them easier.

## BSD License

Copyright © 2012, nxtbgthng GmbH

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name of nxtbgthng nor the
  names of its contributors may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
