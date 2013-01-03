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
    NSString * typeDescription = (__bridge NSString *)(UTTypeCopyDescription((__bridge CFStringRef)(uti)));
    NSString * displayName = [[[NSFileManager defaultManager] displayNameAtPath:filename] stringByDeletingPathExtension];
    
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
    
    alertResult = [[NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"INSTALL_PLUGIN_%@_TYPE_%@", nil),displayName, typeDescription]
                                   defaultButton:[NSString stringWithFormat:NSLocalizedString(@"BUTTON_INSTALL_%@", nil),displayName]
                                 alternateButton:NSLocalizedString(@"CANCEL_BUTTON", nil)
                                     otherButton:nil
                       informativeTextWithFormat:NSLocalizedString(@"FILE_WILL_BE_MOVED_TO_%@", nil),filename, installPath] runModal];
    BOOL shouldCopy = alertResult==NSAlertDefaultReturn;
    if(!shouldCopy)
        [NSApp terminate:self];
    
    // Handle "replace existing version"
    success = [[NSFileManager defaultManager] copyItemAtPath:filename toPath:installPath error:&error];
    if(!success && error.code == NSFileWriteFileExistsError)
    {
        alertResult = [[NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"PREVIOUS_VERSION_OF_%@_ALREADY_INSTALLED", nil),displayName]
                                       defaultButton:NSLocalizedString(@"REPLACE_BUTTON", nil)
                                     alternateButton:NSLocalizedString(@"CANCEL_BUTTON", nil)
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"DO_YOU_WANT_TO_REPLACE", nil)] runModal];
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
