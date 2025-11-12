//
//  AppDelegate.m
//  NetworkIssueTest
//
//  Created by James Orr on 11/10/25.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    NSRect windowRect = NSMakeRect(0, 0, 400, 200);
    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"NetworkIssueTest"];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    
    [self addLabel:@"IP Address:" frame:NSMakeRect(20, 120, 100, 22) bold:NO];
    self.ipAddressField = [self addTextField:NSMakeRect(130, 118, 200, 24) placeholder:@"192.168.0.76"];
    [self.ipAddressField setStringValue:@"192.168.0.76"];

    [self addLabel:@"Port:" frame:NSMakeRect(20, 80, 100, 22) bold:NO];
    self.portField = [self addTextField:NSMakeRect(130, 78, 200, 24) placeholder:@"502"];
    [self.portField setStringValue:@"502"];
    
    self.testButton = [self addButton:@"Test Connection" frame:NSMakeRect(130, 30, 140, 32) action:@selector(testConnection:)];
    }

- (NSTextField *)addLabel:(NSString *)text frame:(NSRect)frame bold:(BOOL)bold
    {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:text];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setFont:bold ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:13]];
    [[self.window contentView] addSubview:label];
    return label;
    }

- (NSTextField *)addTextField:(NSRect)frame placeholder:(NSString *)placeholder
    {
    NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
    [field setPlaceholderString:placeholder];
    [field setFont:[NSFont systemFontOfSize:13]];
    [[self.window contentView] addSubview:field];
    return field;
    }

- (NSButton *)addButton:(NSString *)title frame:(NSRect)frame action:(SEL)action
    {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    [button setTitle:title];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    [button setBezelStyle:NSBezelStyleRounded];
    [button setTarget:self];
    [button setAction:action];
    [[self.window contentView] addSubview:button];
    return button;
    }

- (void)showAlert:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style
    {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:style];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    }

- (void)testConnection:(id)sender
    {
    NSString *ipAddress = [self.ipAddressField stringValue];
    NSString *portString = [self.portField stringValue];
    
    if (ipAddress.length == 0)
        {
        [self showAlert:@"Error" message:@"Please enter an IP address" style:NSAlertStyleWarning];
        return;
        }
    
    NSInteger port = [portString integerValue];
    if (port <= 0 || port > 65535)
        {
        [self showAlert:@"Error" message:@"Please enter a valid port number (1-65535)" style:NSAlertStyleWarning];
        return;
        }
    
    [self.testButton setEnabled:NO];
    [self.testButton setTitle:@"Testing..."];
    self.connectionCompleted = NO;
    self.connectionSucceeded = NO;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ipAddress, (UInt32)port, &readStream, &writeStream);
    
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.connectionCompleted)
            {
            [self closeConnection];
            [self showConnectionResult:NO errorMessage:@"Connection timeout"];
            }
        });
    }

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
    {
    switch (eventCode)
        {
        case NSStreamEventOpenCompleted:
            if (aStream == self.outputStream)
                {
                self.connectionCompleted = YES;
                self.connectionSucceeded = YES;
                [self closeConnection];
                [self showConnectionResult:YES errorMessage:nil];
                }
            break;
        case NSStreamEventErrorOccurred:
            self.connectionCompleted = YES;
            self.connectionSucceeded = NO;
            [self closeConnection];
            [self showConnectionResult:NO errorMessage:[[aStream streamError] localizedDescription]];
            break;
        case NSStreamEventEndEncountered:
            [self closeConnection];
            break;
        default:
            break;
        }
    }

- (void)closeConnection
    {
    if (self.inputStream)
        {
        [self.inputStream close];
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream setDelegate:nil];
        self.inputStream = nil;
        }
    if (self.outputStream)
        {
        [self.outputStream close];
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream setDelegate:nil];
        self.outputStream = nil;
        }
    }

- (void)showConnectionResult:(BOOL)success errorMessage:(NSString *)errorMessage
    {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.testButton setEnabled:YES];
        [self.testButton setTitle:@"Test Connection"];
        NSString *msg = [NSString stringWithFormat:@"%@ to %@:%@", success ? @"Successfully connected" : @"Failed to connect",
        [self.ipAddressField stringValue], [self.portField stringValue]];
        if (errorMessage) msg = [NSString stringWithFormat:@"%@\n\nError: %@", msg, errorMessage];
        [self showAlert:success ? @"Connection Successful" : @"Connection Failed" message:msg style:success ? NSAlertStyleInformational : NSAlertStyleWarning];
        });
    }

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
    {
    return YES;
    }

@end
