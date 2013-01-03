//
//  MSFAppDelegate.m
//  Missing System Folders
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


@implementation InstallSystemPlugins

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
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
    {
        NSLog(@"Already installed");
        return YES;
    }
    
    // Copy
    NSError * error;
    NSInteger alertResult;
    BOOL success;
    
    alertResult = [[NSAlert alertWithMessageText:@"Copy" defaultButton:@"Copy" alternateButton:@"Cancel" otherButton:@"Move" informativeTextWithFormat:@"Copy %@ to %@",filename, installPath] runModal];
    BOOL shouldCopy = alertResult==NSAlertDefaultReturn;
    if(!shouldCopy)
        return YES;
    
    // Handle "replace existing version"
    success = [[NSFileManager defaultManager] copyItemAtPath:filename toPath:installPath error:&error];
    if(!success && error.code == NSFileWriteFileExistsError)
    {
        alertResult = [[NSAlert alertWithMessageText:@"File exists" defaultButton:@"Delete and Replace" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Delete existing version ?"] runModal];
        BOOL shouldReplace = alertResult==NSAlertDefaultReturn;
        if(!shouldReplace)
            return YES;

        success = [[NSFileManager defaultManager] removeItemAtPath:installPath error:&error];
        success &= [[NSFileManager defaultManager] copyItemAtPath:filename toPath:installPath error:&error];
    }
    if(!success)
        [[NSAlert alertWithError:error] runModal];
    
    return YES;
}

@end
