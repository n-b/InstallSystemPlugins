//
//  InstallSystemPlugins.m
//  InstallSystemPlugins
//
//  Created by Nicolas on 03/01/13.
//  Copyright (c) 2013 Nicolas Bouilleaud. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PluginInstallDelegate;
@interface PluginInstall : NSObject <NSAlertDelegate>
- (id) initWithFile:(NSString*)filename delegate:(id<PluginInstallDelegate>)delegate;
- (void) install;
@end
@protocol PluginInstallDelegate
- (void) installFinished:(PluginInstall*)install;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, PluginInstallDelegate>
@end

/****************************************************************************/
#pragma mark -

int main(int argc, char *argv[])
{
    NS_VALID_UNTIL_END_OF_SCOPE AppDelegate * delegate = [AppDelegate new];
    [NSApplication sharedApplication].delegate = delegate;
    [NSApp run];
    return EXIT_SUCCESS;
}

/****************************************************************************/
#pragma mark -

@implementation AppDelegate
{
    NSMutableArray * _installs;
}

- (id)init
{
    self = [super init];
    if (self) {
        _installs = [NSMutableArray new];
    }
    return self;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    // Activate App
    [NSApp activateIgnoringOtherApps:YES];
    
    PluginInstall * install = [[PluginInstall alloc] initWithFile:filename delegate:self];
    [_installs addObject:install];
    BOOL res = install!=nil;
    [install performSelector:@selector(install) withObject:nil afterDelay:0];
    return res;
}

- (void) installFinished:(PluginInstall*)install
{
    [_installs removeObject:install];
    if([_installs count]==0)
        [NSApp terminate:self];
}

@end

/****************************************************************************/
#pragma mark -

@implementation PluginInstall
{
    id<PluginInstallDelegate> _delegate;
    NSString * _filename;
    NSString * _uti;
    NSDictionary * _documentTypeDictionary;
    NSString * _installFolder;
    NSString * _installPath;
}

- (id) initWithFile:(NSString*)filename delegate:(id<PluginInstallDelegate>)delegate
{
    self = [super init];
    if (self) {
        _filename = filename;
        _delegate = delegate;
        
#pragma mark - Check Params
        
        // Get basic info of opened document
        _uti = (__bridge NSString *)(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([filename pathExtension]), NULL));
        
        // Find document type declaration
        NSArray * types = [[NSBundle mainBundle] infoDictionary][@"CFBundleDocumentTypes"];
        [types enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
            if([obj[@"LSItemContentTypes"] containsObject:_uti])
            {
                _documentTypeDictionary = obj;
                *stop = YES;
            }
        }];
        
        _installFolder = [_documentTypeDictionary[@"ISPInstallPath"] stringByExpandingTildeInPath];
        _installPath = [_installFolder stringByAppendingPathComponent:[_filename lastPathComponent]];

        if([_installFolder length]==0)
            return nil;
        
    }
    return self;
}

- (void) install
{
    [self preflight];
    
    // Check wether the document we're opening is already in the destination folder
    if([_filename isEqualToString:_installPath])
    {
        [_delegate installFinished:self];
        return;
    }
    
#pragma mark - Move
    
    NSError * error;
    BOOL success;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:_installPath];
    
    // Move the file
    if( ! fileExists )
    {
        if(![self confirmMoveWithMessage:@"INSTALL_PLUGIN_%@_TYPE_%@"
                         informativeText:@"FILE_WILL_BE_MOVED_TO_%@"
                           defaultButton:@"BUTTON_INSTALL_%@"])
        {
            [_delegate installFinished:self];
            return;
        }
        
        // Move
        success = [self moveOrCopy:&error];
    }
    
    // File exists "now" : move failed, or we didn't attempt it
    if(fileExists || (!success && error.code == NSFileWriteFileExistsError))
    {
        if(![self confirmMoveWithMessage:@"PREVIOUS_VERSION_OF_%@_OF_TYPE_%@_ALREADY_INSTALLED"
                         informativeText:@"DO_YOU_WANT_TO_REPLACE_%@"
                           defaultButton:@"BUTTON_REPLACE_%@"])
        {
            [_delegate installFinished:self];
            return;
        }
        
        success = [[NSFileManager defaultManager] removeItemAtPath:_installPath error:&error];
        success &= [self moveOrCopy:&error];
    }
    
    // End with failure
    if(!success)
    {
        [[NSAlert alertWithError:error] runModal];
        [_delegate installFinished:self];
        return;
    }
    
    // Post-process
    [self postflight];
    
#pragma mark - Done
    
    [[NSWorkspace sharedWorkspace] selectFile:_installPath inFileViewerRootedAtPath:nil];
    
    [_delegate installFinished:self];
    return;
}

- (BOOL) moveOrCopy:(NSError**)error
{
    BOOL res = YES;
    res &= [[NSFileManager defaultManager] createDirectoryAtPath:_installFolder withIntermediateDirectories:YES attributes:nil error:error];
    if([[NSFileManager defaultManager] isDeletableFileAtPath:_filename])
        res &= [[NSFileManager defaultManager] moveItemAtPath:_filename toPath:_installPath error:error];
    else
        res &= [[NSFileManager defaultManager] copyItemAtPath:_filename toPath:_installPath error:error];
    return res;
}

/****************************************************************************/
#pragma mark - UI Code \o/

- (BOOL) confirmMoveWithMessage:(NSString*)messageText
                informativeText:(NSString*)informativeText
                  defaultButton:(NSString*)defaultButton
{
    NSString * displayName = [[[NSFileManager defaultManager] displayNameAtPath:_filename] stringByDeletingPathExtension];
    NSString * typeDescription = (__bridge NSString *)(UTTypeCopyDescription((__bridge CFStringRef)(_uti)));
    
    NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(messageText,nil),displayName, typeDescription]
                                      defaultButton:[NSString stringWithFormat:NSLocalizedString(defaultButton, nil), displayName]
                                    alternateButton:NSLocalizedString(@"BUTTON_REVEAL_DESTINATION", nil)
                                        otherButton:NSLocalizedString(@"CANCEL_BUTTON", nil)
                          informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(informativeText, nil), _installPath],nil];
    
    // Draw Icon
    NSDictionary * typeDeclaration = (__bridge NSDictionary *)(UTTypeCopyDeclaration((__bridge CFStringRef)(_uti)));
    NSString * bundleID = typeDeclaration[(id)kCFBundleIdentifierKey];
    NSString * appPath;
    if (bundleID)
        appPath = [[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleID] path];
    if(appPath==nil)
        appPath = [[NSBundle mainBundle] bundlePath];
    NSImage * appIcon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    NSImage * fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:_filename];
    NSBitmapImageRep* bitmap = [fileIcon representations][0];
    CGSize size = CGSizeMake(bitmap.pixelsWide,bitmap.pixelsHigh);
    fileIcon.size = appIcon.size = size;
    [fileIcon lockFocus];
    [appIcon drawInRect:NSMakeRect(size.width/2, 0,size.width/2, size.height/2) fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositeSourceOver fraction:1];
    [fileIcon unlockFocus];
    
    alert.icon = fileIcon;
    alert.showsHelp = YES;
    alert.delegate = self;
    
    // Run
    NSInteger result = [alert runModal];
    switch (result) {
        case NSAlertAlternateReturn: [[NSWorkspace sharedWorkspace] selectFile:[_installPath stringByDeletingLastPathComponent] inFileViewerRootedAtPath:nil]; // no break
        case NSAlertOtherReturn: [_delegate installFinished:self];
            return NO;
        default:
            return YES;
    }
}

- (BOOL)alertShowHelp:(NSAlert *)alert
{
    return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[NSBundle mainBundle] infoDictionary][@"ISPHelpURL"]]];
}

/****************************************************************************/
#pragma mark - Pre-Postflight

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void) preflight
{
    SEL selector = NSSelectorFromString(_documentTypeDictionary[@"ISPPreflight"]);
    if([self respondsToSelector:selector])
       [self performSelector:selector withObject:nil];
}

- (void) postflight
{
    SEL selector = NSSelectorFromString(_documentTypeDictionary[@"ISPPostflight"]);
    if([self respondsToSelector:selector])
        [self performSelector:selector withObject:nil];
}
#pragma clang diagnostic pop

- (void) restartQLManage
{
    system("qlmanage -r");
}

- (void) fixupCodesnippetFilename
{
    NSDictionary * snippet = [NSDictionary dictionaryWithContentsOfFile:_filename];
    NSString * uuid = snippet[@"IDECodeSnippetIdentifier"];
    if(![[[_filename lastPathComponent] stringByDeletingPathExtension] isEqualToString:uuid])
        _installPath = [[_installFolder stringByAppendingPathComponent:uuid] stringByAppendingPathExtension:[_filename pathExtension]];
}

@end
