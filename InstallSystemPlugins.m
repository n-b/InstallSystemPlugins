//
//  InstallSystemPlugins.m
//  InstallSystemPlugins
//
//  Created by Nicolas on 03/01/13.
//  Copyright (c) 2013 Nicolas Bouilleaud. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InstallSystemPlugins : NSObject <NSApplicationDelegate>
@end

int main(int argc, char *argv[])
{
    NS_VALID_UNTIL_END_OF_SCOPE InstallSystemPlugins * delegate = [InstallSystemPlugins new];
    [NSApplication sharedApplication].delegate = delegate;
    [NSApp run];
    return EXIT_SUCCESS;
}

/****************************************************************************/
#pragma mark -

@implementation InstallSystemPlugins

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    
#pragma mark - Check Params

    // Get basic info of opened document
    NSString * extension = [filename pathExtension];
    NSString * uti = (__bridge NSString *)(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)(extension), NULL));
    
    // Find document type declaration
    NSArray * types = [[NSBundle mainBundle] infoDictionary][@"CFBundleDocumentTypes"];
    __block NSDictionary * typeDict = nil;
    [types enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
        if([obj[@"LSItemContentTypes"] containsObject:uti])
        {
            typeDict = obj;
            *stop = YES;
        }
    }];
    
    NSString * installPath = typeDict[@"MSFInstallPath"];
    
    if([installPath length]==0)
        return NO;
    
    // Check wether the document we're opening is already in the destination folder
    installPath = [[installPath stringByExpandingTildeInPath] stringByAppendingPathComponent:[filename lastPathComponent]];
    if([filename isEqualToString:installPath])
        [NSApp terminate:self];
    
    
#pragma mark - Copy

    // Copy
    NSError * error;
    NSInteger alertResult;
    BOOL success;
    
    alertResult = [[NSAlert alertWithMessageText:NSLocalizedString(@"INSTALL_TITLE", nil)
                                   defaultButton:NSLocalizedString(@"COPY_TO_DESTINATION", nil)
                                 alternateButton:NSLocalizedString(@"CANCEL", nil)
                                     otherButton:nil
                       informativeTextWithFormat:NSLocalizedString(@"INSTALL_MESSAGE_FORMAT_%@_%@", nil),filename, installPath] runModal];
    BOOL shouldCopy = alertResult==NSAlertDefaultReturn;
    if(!shouldCopy)
        [NSApp terminate:self];
    
    // Handle "replace existing version"
    success = [[NSFileManager defaultManager] copyItemAtPath:filename toPath:installPath error:&error];
    if(!success && error.code == NSFileWriteFileExistsError)
    {
        alertResult = [[NSAlert alertWithMessageText:NSLocalizedString(@"REPLACE_TITLE", nil)
                                       defaultButton:NSLocalizedString(@"REPLACE_BUTTON", nil)
                                     alternateButton:NSLocalizedString(@"CANCEL", nil)
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"REPLACE_MESSAGE_FORMAT", nil)] runModal];
        BOOL shouldReplace = alertResult==NSAlertDefaultReturn;
        if(!shouldReplace)
            [NSApp terminate:self];

        success = [[NSFileManager defaultManager] removeItemAtPath:installPath error:&error];
        success &= [[NSFileManager defaultManager] copyItemAtPath:filename toPath:installPath error:&error];
    }
    if(!success)
        [[NSAlert alertWithError:error] runModal];
    
    
#pragma mark - Done
    
    [[NSWorkspace sharedWorkspace] selectFile:installPath inFileViewerRootedAtPath:nil];
    
    [NSApp terminate:self];
    return YES;
}

@end
