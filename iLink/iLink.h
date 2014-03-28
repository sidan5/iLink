//
//  iLink.h
//
//  Created by Idan S on 11/01/2014.
//  Copyright 2014 Idan S

//  Get the latest version from here:
//
//  https://github.com/sidan5/iLink.git

//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

//  // Based on iRate Version 1.9.3 license :
//  // Created by Nick Lockwood on 26/01/2011.
//  // Copyright 2011 Charcoal Design
//  //
//  //   Distributed under the permissive zlib license
//  //   Get the latest version from here:
//  //
//  //   https://github.com/nicklockwood/iRate
//  //
//  //   This software is provided 'as-is', without any express or implied
//  //   warranty.  In no event will the authors be held liable for any damages
//  //   arising from the use of this software.
//  //
//  //   Permission is granted to anyone to use this software for any purpose,
//  //   including commercial applications, and to alter it and redistribute it
//  //   freely, subject to the following restrictions:
//  //
//  //   1. The origin of this software must not be misrepresented; you must not
//  //   claim that you wrote the original software. If you use this software
//  //   in a product, an acknowledgment in the product documentation would be
//  //   appreciated but is not required.
//  //
//  //   2. Altered source versions must be plainly marked as such, and must not be
//  //   misrepresented as being the original software.
//  //
//  //   3. This notice may not be removed or altered from any source distribution.
//  //


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#import <Availability.h>
#undef weak_delegate
#if __has_feature(objc_arc_weak) && \
(TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_8)
#define weak_delegate weak
#else
#define weak_delegate unsafe_unretained
#endif


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif


extern NSUInteger const iLinkAppStoreGameGenreID;
extern NSString *const iLinkErrorDomain;


//localisation string keys
static NSString *const iLinkMessageTitleKey = @"iLinkMessageTitle";
static NSString *const iLinkAppMessageKey = @"iLinkAppMessage";
static NSString *const iLinkGameMessageKey = @"iLinkGameMessage";
static NSString *const iLinkCancelButtonKey = @"iLinkCancelButton";
static NSString *const iLinkRemindButtonKey = @"iLinkRemindButton";
static NSString *const iLinkUpdateButtonKey = @"iLinkUpdateButton";



typedef NS_ENUM(NSUInteger, iLinkErrorCode)
{
    iLinkErrorBundleIdDoesNotMatchAppStore = 1,
    iLinkErrorApplicationNotFoundOnAppStore,
    iLinkErrorApplicationIsNotLatestVersion,
    iLinkErrorCouldNotOpenRatingPageURL,
    iLinkErrorCouldNotOpenAppPageURL
};


@protocol iLinkDelegate <NSObject>
@optional

- (void)iLinkCouldNotConnectToAppStore:(NSError *)error;
- (void)iLinkDidOpenAppStore;
- (void)iLinkDidFindiTunesInfo;
- (void)iLinkDidPromptForUpdate;
- (void)iLinkUserDidDeclineToUpdateApp;
- (void)iLinkUserDidRequestReminderToUpdateApp;
- (void)iLinkUserDidAttemptToUpdateApp;
- (void)iLinkDidDetectAppUpdate;
- (BOOL)iLinkShouldPromptForUpdate;

@end


@interface iLink : NSObject

+ (iLink *)sharedInstance;

//app store ID - this is only needed if your
//bundle ID is not unique between iOS and Mac app stores
@property (nonatomic, assign) NSUInteger appStoreID,artistID;
@property (nonatomic, copy) NSString *applicationStoreVersion;

//application details - these are set automatically
@property (nonatomic, assign) NSUInteger appStoreGenreID;
@property (nonatomic, copy) NSString *appStoreCountry;
@property (nonatomic, copy) NSString *applicationName;
@property (nonatomic, copy) NSString *applicationVersion;
@property (nonatomic, copy) NSString *applicationBundleID;

//usage settings - these have sensible defaults
@property (nonatomic, assign) NSUInteger usesUntilPrompt;
@property (nonatomic, assign) NSUInteger eventsUntilPrompt;
@property (nonatomic, assign) float daysUntilPrompt;
@property (nonatomic, assign) float usesPerWeekForPrompt;
@property (nonatomic, assign) float remindPeriod;

//message text, you may wish to customise these
@property (nonatomic, copy) NSString *messageTitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *cancelButtonLabel;
@property (nonatomic, copy) NSString *remindButtonLabel;
//@property (nonatomic, copy) NSString *rateButtonLabel;*/
@property (nonatomic, copy) NSString *updateButtonLabel;

//debugging and prompt overrides
@property (nonatomic, assign) BOOL useAllAvailableLanguages;
@property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;
@property (nonatomic, assign) BOOL onlyPromptIfMainWindowIsAvailable;
@property (nonatomic, assign) BOOL promptAtLaunch;
@property (nonatomic, assign) BOOL verboseLogging;
@property (nonatomic, assign) BOOL previewMode;
@property (nonatomic, assign) BOOL globalPromptForUpdate;
@property (nonatomic, assign) NSString *linkParams;

//advanced properties for implementing custom behaviour
@property (nonatomic, strong) NSURL *ratingsURL, *appLocalURL,*appShareURL, *artistURL;
@property (nonatomic, strong) NSDate *firstUsed;
@property (nonatomic, strong) NSDate *lastReminded;
@property (nonatomic, assign) NSUInteger usesCount;
@property (nonatomic, assign) NSUInteger eventCount;
@property (nonatomic, readonly) float usesPerWeek;
@property (nonatomic, assign) BOOL declinedThisVersion;
@property (nonatomic, readonly) BOOL declinedAnyVersion;
@property (nonatomic, weak_delegate) id<iLinkDelegate> delegate;


// Functions for controlling links //

// App links //
- (void)iLinkOpenAppPageInAppStore; // This would open the app page in the appropriate way (open the store directly without opening safari first)
- (NSURL *)iLinkGetAppURLforLocal; // Use this if you want to open that inside the app
- (NSURL *)iLinkGetAppURLforSharing; // Use this if you want to share the link on social network

- (void)iLinkOpenAppPageInAppStoreWithAppleID:(NSUInteger)appStoreIDtoOpen; // use this to open another specific app for example the paid version or any reference to other app. Code would recognize if it's an iOS app or Mac app. But pay attention to send the right ID to each app (there isn't same Apple ID for Mac&iOS app for time of writing so you would need to check that if your code support both).

// Developer Links //
- (void)iLinkOpenDeveloperPage; // This would open the developer page in the appropriate way (open the store directly without opening safari first)
- (NSURL *)iLinkGetDeveloperURLforLocal; // Use this if you want to open the Developer URL by yourself
- (NSURL *)iLinkGetDeveloperURLforSharing; // Use this if you want to share the link on social network

// Rating links //
- (void)iLinkOpenRatingsPageInAppStore; // Use this so iLink would open the rating page on the appropriate way (on any case open the store directly without opening safari first)
- (NSURL *)iLinkGetRatingURL; // Use this to open the store on the rating page

@end


#pragma GCC diagnostic pop
