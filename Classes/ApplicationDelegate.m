//
//  ApplicationDelegate.m
//  PushMeBaby
//
//  Created by Stefan Hafeneger on 07.04.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ApplicationDelegate.h"

@interface ApplicationDelegate ()
#pragma mark Properties
@property(nonatomic, retain) NSString *deviceToken, *payload, *certificate;
#pragma mark Private
- (void)connect;
- (void)disconnect;
@end

@implementation ApplicationDelegate

#pragma mark Allocation

- (id)init {
	self = [super init];
	if(self != nil) {
        self.payload = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":1,\"sound\":\"sound.caf\"},\"content\":{\"type\":\"4\",\"id\":\"201608174476430\",\"appid\":\"01\"}}";
        //使用后台远程推送的数据格式
//        self.payload = @"{\"aps\":{\"content-available\":1,\"alert\":\"This is some fancy message.\",\"badge\":1,\"sound\":\"sound.caf\"},\"content-id\":42}";
        
        // 要求填写需要推送到得设备的devicetOKEN
//        self.deviceToken = @"84f9879d8ce71f972e86bad77d9c1ab396323d8015ff68624f0bbe0959c1ee8c";
//        self.certificate = [[NSBundle mainBundle] pathForResource:@"aps_development" ofType:@"cer"];//PushTest
//        self.deviceToken = @"84f9879d8ce71f972e86bad77d9c1ab396323d8015ff68624f0bbe0959c1ee8c";
//        self.deviceToken = @"84f9879d 8ce71f97 2e86bad7 7d9c1ab3 96323d80 15ff6862 4f0bbe09 59c1ee8c";
//        9da4718905af31c90a457b5111acc69e1febc0e41c01ad99744429b1acd4d7d2
//        self.deviceToken = @"504cd946 03b6f8c2 3a2261c0 fc8284f1 4e3e6f71 e395bbdb ef715804 bd54d305";
//744cf779 a9290bbd 47fb8908 19277580 dc5d6616 1bf6655a 4bca8ef6 d607bf2d
//809f1862 738f930c c794b418 962b0a96 dd5db213 5e4eeb88 ac1921fb ecc9d6dc
//        self.deviceToken = @"744cf779 a9290bbd 47fb8908 19277580 dc5d6616 1bf6655a 4bca8ef6 d607bf2d";
        self.deviceToken = @"809f1862 738f930c c794b418 962b0a96 dd5db213 5e4eeb88 ac1921fb ecc9d6dc";

//        self.certificate = [[NSBundle mainBundle] pathForResource:@"aps_development" ofType:@"cer"];//iCloudPay
        self.certificate = [[NSBundle mainBundle] pathForResource:@"aps_pro" ofType:@"cer"];//iCloudPay aps_pro.cer

	}
	return self;
}

- (void)dealloc {
	
	// Release objects.
	self.deviceToken = nil;
	self.payload = nil;
	self.certificate = nil;
	
	// Call super.
	[super dealloc];
	
}


#pragma mark Properties

@synthesize deviceToken = _deviceToken;
@synthesize payload = _payload;
@synthesize certificate = _certificate;

#pragma mark Inherent

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[self connect];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self disconnect];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
	return YES;
}

#pragma mark Private

- (void)connect {
	
	if(self.certificate == nil) {
		return;
	}
	
	// Define result variable.
	OSStatus result;
	
	// Establish connection to server.
	PeerSpec peer;
    if (UAT) {
        result = MakeServerConnection("gateway.sandbox.push.apple.com", 2195, &socket, &peer);// NSLog(@"MakeServerConnection(): %d", result);
    }else{
        result = MakeServerConnection("gateway.push.apple.com", 2195, &socket, &peer);
    }
	
	// Create new SSL context.
	result = SSLNewContext(false, &context);// NSLog(@"SSLNewContext(): %d", result);
	
	// Set callback functions for SSL context.
	result = SSLSetIOFuncs(context, SocketRead, SocketWrite);// NSLog(@"SSLSetIOFuncs(): %d", result);
	
	// Set SSL context connection.
	result = SSLSetConnection(context, socket);// NSLog(@"SSLSetConnection(): %d", result);
	
	// Set server domain name.
    if (UAT) {
        result = SSLSetPeerDomainName(context, "gateway.sandbox.push.apple.com", 30);// NSLog(@"SSLSetPeerDomainName(): %d", result);
    }else{
        result = SSLSetPeerDomainName(context, "gateway.push.apple.com", 22);
    }
	
	// Open keychain.
	result = SecKeychainCopyDefault(&keychain);// NSLog(@"SecKeychainOpen(): %d", result);
	
	// Create certificate.
	NSData *certificateData = [NSData dataWithContentsOfFile:self.certificate];
    
    certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)certificateData);
    if (certificate == NULL)
        NSLog (@"SecCertificateCreateWithData failled");
    
	// Create identity.
	result = SecIdentityCreateWithCertificate(keychain, certificate, &identity);// NSLog(@"SecIdentityCreateWithCertificate(): %d", result);
	
	// Set client certificate.
	CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
	result = SSLSetCertificate(context, certificates);// NSLog(@"SSLSetCertificate(): %d", result);
	CFRelease(certificates);
	
	// Perform SSL handshake.
	do {
		result = SSLHandshake(context);// NSLog(@"SSLHandshake(): %d", result);
	} while(result == errSSLWouldBlock);
	
}

- (void)disconnect {
	
	if(self.certificate == nil) {
		return;
	}
	
	// Define result variable.
	OSStatus result;
	
	// Close SSL session.
	result = SSLClose(context);// NSLog(@"SSLClose(): %d", result);
	
	// Release identity.
    if (identity != NULL)
        CFRelease(identity);
	
	// Release certificate.
    if (certificate != NULL)
        CFRelease(certificate);
	
	// Release keychain.
    if (keychain != NULL)
        CFRelease(keychain);
	
	// Close connection to server.
	close((int)socket);
	
	// Delete SSL context.
	result = SSLDisposeContext(context);// NSLog(@"SSLDisposeContext(): %d", result);
	
}

#pragma mark IBAction

- (IBAction)push:(id)sender {
	
	if(self.certificate == nil) {
        NSLog(@"you need the APNS Certificate for the app to work");
        exit(1);
	}
	
	// Validate input.
	if(self.deviceToken == nil || self.payload == nil) {
		return;
	}
	
	// Convert string into device token data.
	NSMutableData *deviceToken = [NSMutableData data];
	unsigned value;
	NSScanner *scanner = [NSScanner scannerWithString:self.deviceToken];
	while(![scanner isAtEnd]) {
		[scanner scanHexInt:&value];
		value = htonl(value);
		[deviceToken appendBytes:&value length:sizeof(value)];
	}
	
	// Create C input variables.
	char *deviceTokenBinary = (char *)[deviceToken bytes];
	char *payloadBinary = (char *)[self.payload UTF8String];
	size_t payloadLength = strlen(payloadBinary);
	
	// Define some variables.
	uint8_t command = 0;
	char message[293];
	char *pointer = message;
	uint16_t networkTokenLength = htons(32);
	uint16_t networkPayloadLength = htons(payloadLength);
	
	// Compose message.
	memcpy(pointer, &command, sizeof(uint8_t));
	pointer += sizeof(uint8_t);
	memcpy(pointer, &networkTokenLength, sizeof(uint16_t));
	pointer += sizeof(uint16_t);
	memcpy(pointer, deviceTokenBinary, 32);
	pointer += 32;
	memcpy(pointer, &networkPayloadLength, sizeof(uint16_t));
	pointer += sizeof(uint16_t);
	memcpy(pointer, payloadBinary, payloadLength);
	pointer += payloadLength;
	
	// Send message over SSL.
	size_t processed = 0;
	OSStatus result = SSLWrite(context, &message, (pointer - message), &processed);
    if (result != noErr)
        NSLog(@"SSLWrite(): %d %zd", result, processed);
	
}

@end
