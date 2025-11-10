//
//  AppDelegate.h
//  NetworkIssueTest
//
//  Created by James Orr on 11/10/25.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSStreamDelegate>

@property (strong) NSWindow *window;
@property (strong) NSTextField *ipAddressField;
@property (strong) NSTextField *portField;
@property (strong) NSButton *testButton;
@property (strong) NSButton *pingButton;
@property (strong) NSTextView *networkInfoTextView;
@property (strong) NSScrollView *networkInfoScrollView;
@property (strong) NSInputStream *inputStream;
@property (strong) NSOutputStream *outputStream;
@property (strong) NSTask *pingTask;
@property (strong) NSTimer *pingTimeoutTimer;
@property (strong) dispatch_source_t pingTimerSource;
@property (strong) id pingTerminateObserver;
@property (assign) BOOL connectionCompleted;
@property (assign) BOOL connectionSucceeded;

- (void)updateNetworkInfo;
- (void)pingIPAddress:(NSString *)ipAddress;

@end

