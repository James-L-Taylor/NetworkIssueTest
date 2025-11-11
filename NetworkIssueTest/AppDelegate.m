//
//  AppDelegate.m
//  NetworkIssueTest
//
//  Created by James Orr on 11/10/25.
//

#import "AppDelegate.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
    {
    // Create window - make it larger to accommodate network info
    NSRect windowRect = NSMakeRect(0, 0, 600, 500);
    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    [self.window setTitle:@"NetworkIssueTest"];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    
    // Create Network Info label
    NSTextField *networkInfoLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 380, 200, 22)];
    [networkInfoLabel setStringValue:@"Network Configuration:"];
    [networkInfoLabel setBezeled:NO];
    [networkInfoLabel setDrawsBackground:NO];
    [networkInfoLabel setEditable:NO];
    [networkInfoLabel setSelectable:NO];
    [networkInfoLabel setFont:[NSFont boldSystemFontOfSize:13]];
    [[self.window contentView] addSubview:networkInfoLabel];
    
    // Create scroll view for network info
    self.networkInfoScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 240, 560, 130)];
    [self.networkInfoScrollView setHasVerticalScroller:YES];
    [self.networkInfoScrollView setHasHorizontalScroller:NO];
    [self.networkInfoScrollView setAutohidesScrollers:YES];
    [self.networkInfoScrollView setBorderType:NSBezelBorder];
    
    // Create text view for network info
    NSRect textViewRect = [self.networkInfoScrollView contentView].bounds;
    self.networkInfoTextView = [[NSTextView alloc] initWithFrame:textViewRect];
    [self.networkInfoTextView setEditable:NO];
    [self.networkInfoTextView setSelectable:YES];
    [self.networkInfoTextView setFont:[NSFont fontWithName:@"Menlo" size:11]];
    [self.networkInfoTextView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    [self.networkInfoScrollView setDocumentView:self.networkInfoTextView];
    [[self.window contentView] addSubview:self.networkInfoScrollView];
    
    // Create IP Address label
    NSTextField *ipLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 200, 100, 22)];
    [ipLabel setStringValue:@"IP Address:"];
    [ipLabel setBezeled:NO];
    [ipLabel setDrawsBackground:NO];
    [ipLabel setEditable:NO];
    [ipLabel setSelectable:NO];
    [ipLabel setFont:[NSFont systemFontOfSize:13]];
    [[self.window contentView] addSubview:ipLabel];
    
    // Create IP Address text field
    self.ipAddressField = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 198, 200, 24)];
    [self.ipAddressField setPlaceholderString:@"192.168.1.1"];
    [self.ipAddressField setFont:[NSFont systemFontOfSize:13]];
    [[self.window contentView] addSubview:self.ipAddressField];
    
    // Create Port label
    NSTextField *portLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 160, 100, 22)];
    [portLabel setStringValue:@"Port:"];
    [portLabel setBezeled:NO];
    [portLabel setDrawsBackground:NO];
    [portLabel setEditable:NO];
    [portLabel setSelectable:NO];
    [portLabel setFont:[NSFont systemFontOfSize:13]];
    [[self.window contentView] addSubview:portLabel];
    
    // Create Port text field
    self.portField = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 158, 200, 24)];
    [self.portField setPlaceholderString:@"80"];
    [self.portField setStringValue:@"80"];
    [self.portField setFont:[NSFont systemFontOfSize:13]];
    [[self.window contentView] addSubview:self.portField];
    
    // Create test connection button
    self.testButton = [[NSButton alloc] initWithFrame:NSMakeRect(20, 100, 140, 32)];
    [self.testButton setTitle:@"Test Connection"];
    [self.testButton setButtonType:NSButtonTypeMomentaryPushIn];
    [self.testButton setBezelStyle:NSBezelStyleRounded];
    [self.testButton setTarget:self];
    [self.testButton setAction:@selector(testConnection:)];
    [[self.window contentView] addSubview:self.testButton];
    
    // Create ping button
    self.pingButton = [[NSButton alloc] initWithFrame:NSMakeRect(180, 100, 140, 32)];
    [self.pingButton setTitle:@"Ping"];
    [self.pingButton setButtonType:NSButtonTypeMomentaryPushIn];
    [self.pingButton setBezelStyle:NSBezelStyleRounded];
    [self.pingButton setTarget:self];
    [self.pingButton setAction:@selector(pingButtonClicked:)];
    [[self.window contentView] addSubview:self.pingButton];
    
    // Update network info
    [self updateNetworkInfo];
    }

- (void)testConnection:(id)sender
    {
    NSString *ipAddress = [self.ipAddressField stringValue];
    NSString *portString = [self.portField stringValue];
    
    if (ipAddress.length == 0)
        {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error"];
        [alert setInformativeText:@"Please enter an IP address"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
        }
    
    NSInteger port = [portString integerValue];
    if (port <= 0 || port > 65535)
        {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error"];
        [alert setInformativeText:@"Please enter a valid port number (1-65535)"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
        }
    
    // Disable button during connection test
    [self.testButton setEnabled:NO];
    [self.testButton setTitle:@"Testing..."];
    
    // Reset connection state
    self.connectionCompleted = NO;
    self.connectionSucceeded = NO;
    
    // Create streams
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
    
    // Set a timeout for the connection
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
                // Connection established successfully
                self.connectionCompleted = YES;
                self.connectionSucceeded = YES;
                [self closeConnection];
                [self showConnectionResult:YES errorMessage:nil];
                }
            break;
            
        case NSStreamEventErrorOccurred:
            {
            self.connectionCompleted = YES;
            self.connectionSucceeded = NO;
            NSError *error = [aStream streamError];
            NSString *errorMessage = [error localizedDescription];
            [self closeConnection];
            [self showConnectionResult:NO errorMessage:errorMessage];
            break;
            }
            
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
        // Re-enable button
        [self.testButton setEnabled:YES];
        [self.testButton setTitle:@"Test Connection"];
        
        // Show result alert
        NSAlert *alert = [[NSAlert alloc] init];
        NSString *ipAddress = [self.ipAddressField stringValue];
        NSString *portString = [self.portField stringValue];
        
        if (success)
            {
            [alert setMessageText:@"Connection Successful"];
            [alert setInformativeText:[NSString stringWithFormat:@"Successfully connected to %@:%@", ipAddress, portString]];
            [alert setAlertStyle:NSAlertStyleInformational];
            }
        else
            {
            [alert setMessageText:@"Connection Failed"];
            NSString *infoText = [NSString stringWithFormat:@"Failed to connect to %@:%@", ipAddress, portString];
            if (errorMessage)
                {
                infoText = [NSString stringWithFormat:@"%@\n\nError: %@", infoText, errorMessage];
                }
            [alert setInformativeText:infoText];
            [alert setAlertStyle:NSAlertStyleWarning];
            }
        
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        });
    }

- (void)updateNetworkInfo
    {
    NSMutableString *infoText = [[NSMutableString alloc] init];
    
    // Get network interfaces
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = getifaddrs(&interfaces);
    
    if (success == 0)
        {
        temp_addr = interfaces;
        NSMutableArray *ipv4Addresses = [[NSMutableArray alloc] init];
        NSMutableArray *ipv6Addresses = [[NSMutableArray alloc] init];
        
        while (temp_addr != NULL)
            {
            // Check if interface is up and not a loopback interface
            if ((temp_addr->ifa_flags & IFF_UP) && !(temp_addr->ifa_flags & IFF_LOOPBACK))
                {
                // IPv4
                if (temp_addr->ifa_addr->sa_family == AF_INET)
                    {
                    struct sockaddr_in *sin = (struct sockaddr_in *)temp_addr->ifa_addr;
                    char ip[INET_ADDRSTRLEN];
                    inet_ntop(AF_INET, &(sin->sin_addr), ip, INET_ADDRSTRLEN);
                    NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];
                    NSString *ipString = [NSString stringWithUTF8String:ip];
                    [ipv4Addresses addObject:[NSString stringWithFormat:@"%@: %@", interfaceName, ipString]];
                    }
                // IPv6
                else if (temp_addr->ifa_addr->sa_family == AF_INET6)
                    {
                    struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)temp_addr->ifa_addr;
                    char ip6[INET6_ADDRSTRLEN];
                    inet_ntop(AF_INET6, &(sin6->sin6_addr), ip6, INET6_ADDRSTRLEN);
                    NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];
                    NSString *ipString = [NSString stringWithUTF8String:ip6];
                    [ipv6Addresses addObject:[NSString stringWithFormat:@"%@: %@", interfaceName, ipString]];
                    }
                }
            temp_addr = temp_addr->ifa_next;
            }
        
        freeifaddrs(interfaces);
        
        // Build info string
        [infoText appendString:@"IPv4 Addresses:\n"];
        if (ipv4Addresses.count > 0)
            {
            for (NSString *addr in ipv4Addresses)
                {
                [infoText appendFormat:@"  %@\n", addr];
                }
            }
        else
            {
            [infoText appendString:@"  None\n"];
            }
        
        [infoText appendString:@"\nIPv6 Addresses:\n"];
        if (ipv6Addresses.count > 0)
            {
            for (NSString *addr in ipv6Addresses)
                {
                [infoText appendFormat:@"  %@\n", addr];
                }
            }
        else
            {
            [infoText appendString:@"  None\n"];
            }
        
        // Try to determine DHCP vs Static (simplified - check system configuration)
        [infoText appendString:@"\nConfiguration Method:\n"];
        SCPreferencesRef prefs = SCPreferencesCreate(NULL, CFSTR("NetworkIssueTest"), NULL);
        if (prefs)
            {
            SCNetworkSetRef currentSet = SCNetworkSetCopyCurrent(prefs);
            if (currentSet)
                {
                // Get all services
                CFArrayRef services = SCNetworkSetCopyServices(currentSet);
                if (services)
                    {
                    CFIndex count = CFArrayGetCount(services);
                    BOOL foundConfiguration = NO;
                    for (CFIndex i = 0; i < count; i++)
                        {
                        SCNetworkServiceRef service = (SCNetworkServiceRef)CFArrayGetValueAtIndex(services, i);
                        SCNetworkInterfaceRef interface = SCNetworkServiceGetInterface(service);
                        
                        if (interface)
                            {
                            CFStringRef interfaceType = SCNetworkInterfaceGetInterfaceType(interface);
                            // Check both Ethernet and WiFi interfaces
                            BOOL isNetworkInterface = NO;
                            if (interfaceType)
                                {
                                if (CFStringCompare(interfaceType, kSCNetworkInterfaceTypeEthernet, 0) == kCFCompareEqualTo ||
                                    CFStringCompare(interfaceType, kSCNetworkInterfaceTypeIEEE80211, 0) == kCFCompareEqualTo ||
                                    CFStringCompare(interfaceType, kSCNetworkInterfaceTypeWWAN, 0) == kCFCompareEqualTo)
                                    {
                                    isNetworkInterface = YES;
                                    }
                                }
                            
                            if (isNetworkInterface)
                                {
                                // Check for configuration method
                                SCNetworkProtocolRef ipv4 = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeIPv4);
                                if (ipv4)
                                    {
                                    CFDictionaryRef config = SCNetworkProtocolGetConfiguration(ipv4);
                                    if (config)
                                        {
                                        CFStringRef method = CFDictionaryGetValue(config, kSCPropNetIPv4ConfigMethod);
                                        if (method)
                                            {
                                            foundConfiguration = YES;
                                            CFStringRef name = SCNetworkServiceGetName(service);
                                            NSString *serviceName = name ? (__bridge NSString *)name : @"Unknown";
                                            
                                            if (CFStringCompare(method, kSCValNetIPv4ConfigMethodDHCP, 0) == kCFCompareEqualTo)
                                                {
                                                [infoText appendFormat:@"  %@: DHCP\n", serviceName];
                                                }
                                            else if (CFStringCompare(method, kSCValNetIPv4ConfigMethodManual, 0) == kCFCompareEqualTo)
                                                {
                                                [infoText appendFormat:@"  %@: Static (Manual)\n", serviceName];
                                                }
                                            else if (CFStringCompare(method, kSCValNetIPv4ConfigMethodBOOTP, 0) == kCFCompareEqualTo)
                                                {
                                                [infoText appendFormat:@"  %@: BootP\n", serviceName];
                                                }
                                            else
                                                {
                                                [infoText appendFormat:@"  %@: %@\n", serviceName, (__bridge NSString *)method];
                                                }
                                            }
                                        }
                                    CFRelease(ipv4);
                                    }
                                }
                            }
                        }
                    if (!foundConfiguration)
                        {
                        [infoText appendString:@"  Unable to determine configuration method (may require admin privileges)\n"];
                        }
                    CFRelease(services);
                    }
                CFRelease(currentSet);
                }
            CFRelease(prefs);
            }
        else
            {
            [infoText appendString:@"  Unable to determine (requires System Preferences access)\n"];
            }
        }
    else
        {
        [infoText appendString:@"Unable to retrieve network information\n"];
        }
    
    // Update text view
    [[self.networkInfoTextView textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:infoText]];
    }

- (void)pingButtonClicked:(id)sender
    {
    NSString *ipAddress = [self.ipAddressField stringValue];
    
    if (ipAddress.length == 0)
        {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error"];
        [alert setInformativeText:@"Please enter an IP address to ping"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
        }
    
    [self pingIPAddress:ipAddress];
    }

- (void)pingIPAddress:(NSString *)ipAddress
    {
    // Clean up any existing ping
    [self cleanupPingTask];
    
    // Disable button during ping
    [self.pingButton setEnabled:NO];
    [self.pingButton setTitle:@"Pinging..."];
    
    __weak typeof(self) weakSelf = self;
    
    // Create ping task and store it
    self.pingTask = [[NSTask alloc] init];
    [self.pingTask setLaunchPath:@"/sbin/ping"];
    // Send 4 packets with 2 second timeout per packet (-t timeout in seconds)
    [self.pingTask setArguments:@[@"-c", @"4", @"-t", @"2", ipAddress]];
    
    // Create pipe for output
    NSPipe *outputPipe = [[NSPipe alloc] init];
    NSPipe *errorPipe = [[NSPipe alloc] init];
    [self.pingTask setStandardOutput:outputPipe];
    [self.pingTask setStandardError:errorPipe];
    
    // Get file handles for reading (don't close write ends - NSTask needs them)
    NSFileHandle *outputHandle = [outputPipe fileHandleForReading];
    NSFileHandle *errorHandle = [errorPipe fileHandleForReading];
    
    // Set up timeout using dispatch source (20 seconds total timeout - enough for 4 packets with 2s timeout each)
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.pingTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(self.pingTimerSource, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
    dispatch_source_set_event_handler(self.pingTimerSource, ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // Timeout - terminate the task
        if (strongSelf.pingTask && [strongSelf.pingTask isRunning])
            {
            [strongSelf.pingTask terminate];
            }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            [strongSelf cleanupPingTask];
            [strongSelf handlePingResult:[NSString stringWithFormat:@"Ping to %@ timed out after 20 seconds", ipAddress]];
            });
        });
    dispatch_resume(self.pingTimerSource);
    
    // Launch task and wait for completion on background queue
    dispatch_async(queue, ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        @try
            {
            // Launch the task
            [strongSelf.pingTask launch];
            
            // Wait for task to complete (this blocks the background thread, not the main thread)
            [strongSelf.pingTask waitUntilExit];
            
            // Read output and error after task completes
            // NSTask automatically closes the write ends when the process terminates
            NSData *outputData = [outputHandle readDataToEndOfFile];
            NSData *errorData = [errorHandle readDataToEndOfFile];
            
            // Combine output and error (ping typically uses stdout)
            NSMutableData *allData = [outputData mutableCopy];
            if (errorData.length > 0)
                {
                [allData appendData:errorData];
                }
            
            // Convert to string
            NSString *output = nil;
            if (allData.length > 0)
                {
                output = [[NSString alloc] initWithData:allData encoding:NSUTF8StringEncoding];
                // Fallback to ASCII if UTF-8 fails
                if (!output)
                    {
                    output = [[NSString alloc] initWithData:allData encoding:NSASCIIStringEncoding];
                    }
                }
            
            // Cancel timeout on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                // Cancel timeout
                if (strongSelf.pingTimerSource)
                    {
                    dispatch_source_cancel(strongSelf.pingTimerSource);
                    strongSelf.pingTimerSource = nil;
                    }
                
                // Handle result - always show output, even if empty
                NSInteger status = [strongSelf.pingTask terminationStatus];
                if (output && output.length > 0)
                    {
                    [strongSelf handlePingResult:output];
                    }
                else
                    {
                    // No output but task completed - might be a permission issue or other problem
                    NSString *errorMsg = [NSString stringWithFormat:@"Ping completed with exit status: %ld\n(No output received)", (long)status];
                    [strongSelf handlePingResult:errorMsg];
                    }
                });
            
            } @catch (NSException *exception)
            {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                [strongSelf cleanupPingTask];
                [strongSelf.pingButton setEnabled:YES];
                [strongSelf.pingButton setTitle:@"Ping"];
                
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Error"];
                [alert setInformativeText:[NSString stringWithFormat:@"Failed to start ping: %@", [exception reason]]];
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
                });
            }
        });
    }

- (void)cleanupPingTask
    {
    // Cancel timeout timer source
    if (self.pingTimerSource)
        {
        dispatch_source_cancel(self.pingTimerSource);
        self.pingTimerSource = nil;
        }
    
    // Cancel NSTimer if it exists
    if (self.pingTimeoutTimer)
        {
        [self.pingTimeoutTimer invalidate];
        self.pingTimeoutTimer = nil;
        }
    
    // Terminate task if still running
    if (self.pingTask && [self.pingTask isRunning])
        {
        [self.pingTask terminate];
        }
    
    // Remove notification observer if it exists
    if (self.pingTerminateObserver)
        {
        [[NSNotificationCenter defaultCenter] removeObserver:self.pingTerminateObserver];
        self.pingTerminateObserver = nil;
        }
    
    self.pingTask = nil;
    }

- (void)handlePingResult:(NSString *)output
    {
    // Clean up
    [self cleanupPingTask];
    
    // Re-enable button on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pingButton setEnabled:YES];
        [self.pingButton setTitle:@"Ping"];
    
    // Parse ping output to determine success
    BOOL success = NO;
    NSMutableString *summary = [[NSMutableString alloc] init];
    NSInteger packetLoss = 100; // Default to 100% loss (failure)
    
    if (output && output.length > 0)
        {
        NSArray *lines = [output componentsSeparatedByString:@"\n"];
        
        // First, check for any successful ping responses
        for (NSString *line in lines)
            {
            if ([line containsString:@"bytes from"])
                {
                success = YES; // At least one packet was received
                break;
                }
            }
        
        // Then parse the statistics line
        for (NSString *line in lines)
            {
            if ([line containsString:@"packets transmitted"])
                {
                // Extract packet loss percentage
                NSArray *components = [line componentsSeparatedByString:@","];
                for (NSString *component in components)
                    {
                    NSString *trimmed = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if ([trimmed containsString:@"packet loss"] || [trimmed containsString:@"% packet loss"])
                        {
                        // Extract the percentage number
                        NSScanner *scanner = [NSScanner scannerWithString:trimmed];
                        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
                        if ([scanner scanInteger:&packetLoss])
                            {
                            success = (packetLoss < 100);
                            }
                        break;
                        }
                    }
                if (summary.length > 0)
                    {
                    [summary appendString:@"\n"];
                    }
                [summary appendString:line];
                }
            else if ([line containsString:@"round-trip"] || [line containsString:@"min/avg/max"] || [line containsString:@"stddev"])
                {
                if (summary.length > 0)
                    {
                    [summary appendString:@"\n"];
                    }
                [summary appendString:line];
                }
            }
        
        // Check for error messages if we haven't determined success yet
        if (!success)
            {
            NSString *lowerOutput = [output lowercaseString];
            if ([lowerOutput containsString:@"request timeout"] || 
                [lowerOutput containsString:@"no route to host"] ||
                [lowerOutput containsString:@"host is down"] ||
                [lowerOutput containsString:@"network is unreachable"] ||
                [lowerOutput containsString:@"unknown host"] ||
                [lowerOutput containsString:@"cannot resolve"])
                {
                success = NO;
                }
            }
        
        // If we still don't have a summary, use the full output (truncated)
        if (summary.length == 0 && output.length > 0)
            {
            summary = [[output substringToIndex:MIN(500, output.length)] mutableCopy];
            }
        }
    
        // Show result
        NSAlert *alert = [[NSAlert alloc] init];
        NSString *ipAddress = [self.ipAddressField stringValue];
        
        if (success)
            {
            [alert setMessageText:@"Ping Successful"];
            [alert setInformativeText:[NSString stringWithFormat:@"Successfully pinged %@\n\n%@", ipAddress, summary.length > 0 ? summary : output]];
            [alert setAlertStyle:NSAlertStyleInformational];
            }
        else
            {
            [alert setMessageText:@"Ping Failed"];
            NSString *infoText = [NSString stringWithFormat:@"Failed to ping %@", ipAddress];
            if (output.length > 0)
                {
                infoText = [NSString stringWithFormat:@"%@\n\n%@", infoText, output];
                }
            [alert setInformativeText:infoText];
            [alert setAlertStyle:NSAlertStyleWarning];
            }
        
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        });
    }

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
    {
    return YES;
    }

@end

