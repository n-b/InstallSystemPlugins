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

@interface NSAlert (InstallSystemPlugins) <NSAlertDelegate>
+ (NSInteger) confirmMoveWithMessage:(NSString*)messageText
                     informativeText:(NSString*)informativeText
                       defaultButton:(NSString*)defaultButton
                            filename:(NSString*)filename
                                 uti:(NSString*)uti
                         installPath:(NSString*)installPath;
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
    // Activate App
    [NSApp activateIgnoringOtherApps:YES];
    
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
    
    NSString * installFolder = typeDict[@"ISPInstallPath"];
    
    if([installFolder length]==0)
        return NO;
    
    // Check wether the document we're opening is already in the destination folder
    NSString * installPath = [[installFolder stringByExpandingTildeInPath] stringByAppendingPathComponent:[filename lastPathComponent]];
    if([filename isEqualToString:installPath])
        [NSApp terminate:self];
    
    
#pragma mark - Move
    
    NSError * error;
    BOOL success;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:installPath];

    // Move the file
    if( ! fileExists )
    {
        [NSAlert confirmMoveWithMessage:@"INSTALL_PLUGIN_%@_TYPE_%@"
                        informativeText:@"FILE_WILL_BE_MOVED_TO_%@"
                          defaultButton:@"BUTTON_INSTALL_%@"
                               filename:filename
                                    uti:uti
                            installPath:installPath];
        
        // Move
        success = [[NSFileManager defaultManager] moveItemAtPath:filename toPath:installPath error:&error];
    }

    // File exists "now" : move failed, or we didn't attempt it
    if(fileExists || (!success && error.code == NSFileWriteFileExistsError))
    {
        [NSAlert confirmMoveWithMessage:@"PREVIOUS_VERSION_OF_%@_OF_TYPE_%@_ALREADY_INSTALLED"
                        informativeText:@"DO_YOU_WANT_TO_REPLACE_%@"
                          defaultButton:@"BUTTON_REPLACE_%@"
                               filename:filename
                                    uti:uti
                            installPath:installPath];
        
        success = [[NSFileManager defaultManager] removeItemAtPath:installPath error:&error];
        success &= [[NSFileManager defaultManager] moveItemAtPath:filename toPath:installPath error:&error];
    }
    
    // End with failure
    if(!success)
    {
        [[NSAlert alertWithError:error] runModal];
        [NSApp terminate:self];
    }
    
    
#pragma mark - Done
    
    [[NSWorkspace sharedWorkspace] selectFile:installPath inFileViewerRootedAtPath:nil];
    
    [NSApp terminate:self];
    return YES;
}

@end

/****************************************************************************/
#pragma mark - UI Code \o/

@implementation NSAlert (InstallSystemPlugins)

+ (NSInteger) confirmMoveWithMessage:(NSString*)messageText
                     informativeText:(NSString*)informativeText
                       defaultButton:(NSString*)defaultButton
                            filename:(NSString*)filename
                                 uti:(NSString*)uti
                         installPath:(NSString*)installPath
{
    NSString * displayName = [[[NSFileManager defaultManager] displayNameAtPath:filename] stringByDeletingPathExtension];
    NSString * typeDescription = (__bridge NSString *)(UTTypeCopyDescription((__bridge CFStringRef)(uti)));

    NSAlert * alert = [self alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(messageText,nil),displayName, typeDescription]
                                   defaultButton:[NSString stringWithFormat:NSLocalizedString(defaultButton, nil), displayName]
                                 alternateButton:NSLocalizedString(@"BUTTON_REVEAL_DESTINATION", nil)
                                     otherButton:NSLocalizedString(@"CANCEL_BUTTON", nil)
                       informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(informativeText, nil), installPath],nil];

    // Draw Icon
    NSDictionary * typeDeclaration = (__bridge NSDictionary *)(UTTypeCopyDeclaration((__bridge CFStringRef)(uti)));
    NSString * bundleID = typeDeclaration[(id)kCFBundleIdentifierKey];
    NSString * appPath;
    if (bundleID)
        appPath = [[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleID] path];
    if(appPath==nil)
        appPath = [[NSBundle mainBundle] bundlePath];
    NSImage * appIcon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    NSImage * fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:filename];
    NSBitmapImageRep* bitmap = [fileIcon representations][0];
    CGSize size = CGSizeMake(bitmap.pixelsWide,bitmap.pixelsHigh);
    fileIcon.size = appIcon.size = size;
    [fileIcon lockFocus];
    [appIcon drawInRect:NSMakeRect(size.width/2, 0,size.width/2, size.height/2) fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositeSourceOver fraction:1];
    [fileIcon unlockFocus];

    alert.icon = fileIcon;
    alert.showsHelp = YES;
    alert.delegate = alert;
    
    
    // Run
    NSInteger result = [alert runModal];
    
    if(result==NSAlertAlternateReturn)
    {
        [[NSWorkspace sharedWorkspace] selectFile:[installPath stringByDeletingLastPathComponent] inFileViewerRootedAtPath:nil];
        [NSApp terminate:self];
    }

    if(result==NSAlertOtherReturn)
        [NSApp terminate:self];
    return result;
}

- (BOOL)alertShowHelp:(NSAlert *)alert
{
    return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[NSBundle mainBundle] infoDictionary][@"ISPHelpURL"]]];
}

@end
