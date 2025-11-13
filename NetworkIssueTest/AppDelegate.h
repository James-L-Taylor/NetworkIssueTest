//
//  AppDelegate.h
//  NetworkIssueTest
//
//  Created by James Orr on 11/10/25.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSStreamDelegate>

@property (strong) NSWindow *window;
@property (strong) NSTextField *ipAddressField;
@property (strong) NSTextField *portField;
@property (strong) NSButton *testButton;
@property (strong) NSInputStream *inputStream;
@property (strong) NSOutputStream *outputStream;
@property (assign) BOOL connectionCompleted;
@property (assign) BOOL connectionSucceeded;

@end

