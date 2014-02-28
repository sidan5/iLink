//
//  iLinkAppDelegate.h
//  iLink
//
//  Created by Idan S on 11/01/2014.
//  Copyright 2014 Idan S
//

#import <UIKit/UIKit.h>
#import  "iLink.h"


@interface iLinkAppDelegate : NSObject <UIApplicationDelegate,iLinkDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;

@end

