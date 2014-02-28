//
//  iLinkMacAppDelegate.m
//  iLinkMac
//
//  Created by Idan S on 11/01/2014.
//  Copyright 2014 Idan S
//

#import "iLinkMacAppDelegate.h"
#import "iLink.h"


@implementation iLinkMacAppDelegate

@synthesize window;

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iLink sharedInstance].applicationBundleID = @"com.charcoaldesign.RainbowBlocksLite"; 
    [iLink sharedInstance].onlyPromptIfLatestVersion = NO;
    
    //enable preview mode
    [iLink sharedInstance].previewMode = YES;
}

@end
