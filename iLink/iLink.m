//
//  iLink.m
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


#import "iLink.h"

#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


#pragma GCC diagnostic ignored "-Wreceiver-is-weak"
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wunused-macros"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wgnu"


NSString *const iLinkErrorDomain = @"iLinkErrorDomain";

static NSString *const iLinkParamsCode = @"at=10lu5f&ct=iLink";
static NSString *const iLinkAppStoreIDKey = @"iLinkAppStoreID";
static NSString *const iLinkArtistIDKey = @"iLinkArtistID";
static NSString *const iLinkDeclinedVersionKey = @"iLinkDeclinedVersion";
static NSString *const iLinkLastRemindedKey = @"iLinkLastReminded";
static NSString *const iLinkLastVersionUsedKey = @"iLinkLastVersionUsed";
static NSString *const iLinkFirstUsedKey = @"iLinkFirstUsed";
static NSString *const iLinkUseCountKey = @"iLinkUseCount";
static NSString *const iLinkEventCountKey = @"iLinkEventCount";

static NSString *const iLinkMacAppStoreBundleID = @"com.apple.appstore";
static NSString *const iLinkAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";

static NSString *const iLinkiOSAppStoreURLScheme = @"itms-apps";
static NSString *const iLinkiOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@?%@";
static NSString *const iLinkiOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@?%@";
static NSString *const iLinkMacAppStoreURLFormat = @"macappstore://itunes.apple.com/app/id%@?%@";

static NSString *const iLinkRegulariOSAppStoreURLFormat = @"http://itunes.apple.com/app/id%@?%@";

static NSString *const iLinkArtistAppStoreURLFormat = @"https://itunes.apple.com/artist/id%@?%@";
static NSString *const iLinkiOSArtistAppStoreURLFormat = @"itms-apps://itunes.apple.com/artist/id%@?%@";
static NSString *const iLinkMacArtistAppStoreURLFormat = @"macappstore://itunes.apple.com/artist/id%@?%@";

#define SECONDS_IN_A_DAY 86400.0
#define SECONDS_IN_A_WEEK 604800.0
#define MAC_APP_STORE_REFRESH_DELAY 5.0
#define REQUEST_TIMEOUT 60.0


@implementation NSObject (iLink)

- (void)iLinkCouldNotConnectToAppStore:(__unused NSError *)error {}
- (void)iLinkDidOpenAppStore {}
- (void)iLinkDidPromptForUpdate {}
- (void)iLinkUserDidDeclineToUpdateApp {}
- (void)iLinkUserDidRequestReminderToUpdateApp {}
- (void)iLinkUserDidAttemptToUpdateApp {}
- (void)iLinkDidDetectAppUpdate {}
- (BOOL)iLinkShouldPromptForUpdate { return YES; }

@end


@interface iLink()

@property (nonatomic, strong) id visibleAlert;
@property (nonatomic, assign) int previousOrientation;
@property (nonatomic, assign) BOOL checkingForPrompt;
@property (nonatomic, assign) BOOL checkingForAppStoreID;

@end


@implementation iLink

+ (void)load
{
    [self performSelectorOnMainThread:@selector(sharedInstance) withObject:nil waitUntilDone:NO];
}

+ (iLink *)sharedInstance
{
    static iLink *sharedInstance = nil;
    if (sharedInstance == nil)
    {
        sharedInstance = [[iLink alloc] init];
    }
    return sharedInstance;
}

- (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
    static NSBundle *bundle = nil;
    if (bundle == nil)
    {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"iLink" ofType:@"bundle"];
        if (self.useAllAvailableLanguages)
        {
            bundle = [NSBundle bundleWithPath:bundlePath];
            NSString *language = [[NSLocale preferredLanguages] count]? [NSLocale preferredLanguages][0]: @"en";
            if (![[bundle localizations] containsObject:language])
            {
                language = [language componentsSeparatedByString:@"-"][0];
            }
            if ([[bundle localizations] containsObject:language])
            {
                bundlePath = [bundle pathForResource:language ofType:@"lproj"];
            }
        }
        bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
    }
    defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:defaultString table:nil];
}

- (iLink *)init
{
    self.applicationStoreVersion = nil;
    if ((self = [super init]))
    {
        
#if TARGET_OS_IPHONE
        
        //register for iphone application events
        if (&UIApplicationWillEnterForegroundNotification)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillEnterForeground)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
        }
        
        self.previousOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate) name:UIDeviceOrientationDidChangeNotification object:nil];
        
#endif
        
        //get country
        self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        if ([self.appStoreCountry isEqualToString:@"150"])
        {
            self.appStoreCountry = @"eu";
        }
        else if ([[self.appStoreCountry stringByReplacingOccurrencesOfString:@"[A-Za-z]{2}" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, 2)] length])
        {
            self.appStoreCountry = @"us";
        }
        
        //application version (use short version preferentially)
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([self.applicationVersion length] == 0)
        {
            self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }
        
        //localised application name
        self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if ([self.applicationName length] == 0)
        {
            self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        }
        
        //bundle id
        self.applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        //default settings
        self.useAllAvailableLanguages = YES;
        self.onlyPromptIfLatestVersion = NO;
        self.onlyPromptIfMainWindowIsAvailable = YES;
        self.promptAtLaunch = YES;
        self.usesUntilPrompt = 0;//10;
        self.eventsUntilPrompt = 0;//10;
        self.daysUntilPrompt = 0.0f;//10.0f;
        self.usesPerWeekForPrompt = 0.0f;
        self.remindPeriod = 1.0f;
        self.verboseLogging = NO;
        self.previewMode = NO;
        self.globalPromptForUpdate = YES;
        self.linkParams = iLinkParamsCode;
        
#if DEBUG
        
        //enable verbose logging in debug mode
        self.verboseLogging = YES;
        
#endif
        
        //app launched
        [self performSelectorOnMainThread:@selector(applicationLaunched) withObject:nil waitUntilDone:NO];
    }
    return self;
}

- (id<iLinkDelegate>)delegate
{
    if (_delegate == nil)
    {
        
#if TARGET_OS_IPHONE
#define APP_CLASS UIApplication      
#else
#define APP_CLASS NSApplication  
#endif
        
        _delegate = (id<iLinkDelegate>)[[APP_CLASS sharedApplication] delegate];
    }
    return _delegate;
}

- (NSString *)messageTitle
{
    return [_messageTitle ?: [self localizedStringForKey:iLinkMessageTitleKey withDefault:@"Update %@"] stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
}

- (NSString *)message
{
    NSString *message = _message;
    if (!message)
    {
        message = [self localizedStringForKey:iLinkAppMessageKey withDefault:@"An update for %@ is available. \n\nWould you like to update it now?"];    }
    return [message stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
}

- (NSString *)cancelButtonLabel
{
    return _cancelButtonLabel ?: [self localizedStringForKey:iLinkCancelButtonKey withDefault:@"No, Thanks"];
}

- (NSString *)updateButtonLabel
{
    return _updateButtonLabel ?: [self localizedStringForKey:iLinkUpdateButtonKey withDefault:@"Update Now"];
}

- (NSString *)remindButtonLabel
{
    return _remindButtonLabel ?: [self localizedStringForKey:iLinkRemindButtonKey withDefault:@"Remind Me Later"];
}

- (NSURL *)ratingsURL
{
    if (_ratingsURL)
    {
        return _ratingsURL;
    }
    
    if (!self.appStoreID && self.verboseLogging)
    {
        NSLog(@"iLink could not find the App Store ID for this application. If the application is not intended for App Store release then you must specify a custom ratingsURL.");
    }
    
#if TARGET_OS_IPHONE
    
    return [NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? iLinkiOS7AppStoreURLFormat: iLinkiOSAppStoreURLFormat, @(self.appStoreID),iLinkParamsCode]];
    
#else
    
    return [NSURL URLWithString:[NSString stringWithFormat:iLinkMacAppStoreURLFormat, @(self.appStoreID),iLinkParamsCode]];
    
#endif
    
}

- (NSUInteger)appStoreID
{
    return _appStoreID ?: [[[NSUserDefaults standardUserDefaults] objectForKey:iLinkAppStoreIDKey] unsignedIntegerValue];
}

- (NSUInteger)artistID
{
    return _artistID ?: [[[NSUserDefaults standardUserDefaults] objectForKey:iLinkArtistIDKey] unsignedIntegerValue];
}

- (NSDate *)firstUsed
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:iLinkFirstUsedKey];
}

- (void)setFirstUsed:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:iLinkFirstUsedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lastReminded
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:iLinkLastRemindedKey];
}

- (void)setLastReminded:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:iLinkLastRemindedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)usesCount
{
    return (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:iLinkUseCountKey];
}

- (void)setUsesCount:(NSUInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)count forKey:iLinkUseCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)eventCount
{
    return (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:iLinkEventCountKey];
}

- (void)setEventCount:(NSUInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)count forKey:iLinkEventCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (float)usesPerWeek
{
    return (float)self.usesCount / ([[NSDate date] timeIntervalSinceDate:self.firstUsed] / SECONDS_IN_A_WEEK);
}

- (BOOL)declinedThisVersion
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iLinkDeclinedVersionKey] isEqualToString:self.applicationVersion];
}

- (void)setDeclinedThisVersion:(BOOL)declined
{
    [[NSUserDefaults standardUserDefaults] setObject:(declined? self.applicationVersion: nil) forKey:iLinkDeclinedVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)declinedAnyVersion
{
    return [(NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:iLinkDeclinedVersionKey] length];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)incrementUseCount
{
    self.usesCount ++;
}

- (void)incrementEventCount
{
    self.eventCount ++;
}

- (BOOL)shouldPromptForUpdate
{   
    //preview mode?
    if (self.previewMode)
    {
        NSLog(@"iLink preview mode is enabled - make sure you disable this for release");
        return YES;
    }
    
    else if (!self.globalPromptForUpdate)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for update because the developer decided not to use this feature");
        }
        return NO;
    }
    
    //check if we've rated the app
   /* else if (self.ratedAnyVersion)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for rating because the user has already rated the app");
        }
        return NO;
    }*/
    
    //check if we've declined to update the app
    else if (self.declinedAnyVersion)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for update because the user has declined to update the app");
        }
        return NO;
    }

    //check for first launch
    else if ((self.daysUntilPrompt > 0.0f || self.usesPerWeekForPrompt) && self.firstUsed == nil)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for update because this is the first time the app has been launched");
        }
        return NO;
    }
    
    //check how long we've been using this version
    else if ([[NSDate date] timeIntervalSinceDate:self.firstUsed] < self.daysUntilPrompt * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for update because the app was first used less than %g days ago", self.daysUntilPrompt);
        }
        return NO;
    }
    
    //check how many times we've used it and the number of significant events
    else if (self.usesCount < self.usesUntilPrompt && self.eventCount < self.eventsUntilPrompt)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for update because the app has only been used %@ times and only %@ events have been logged", @(self.usesCount), @(self.eventCount));
        }
        return NO;
    }
    
    //check if usage frequency is high enough
    else if (self.usesPerWeek < self.usesPerWeekForPrompt)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for update because the app has only been used %g times per week on average since it was installed", self.usesPerWeek);
        }
        return NO;
    }

    //check if within the reminder period
    else if (self.lastReminded != nil && [[NSDate date] timeIntervalSinceDate:self.lastReminded] < self.remindPeriod * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink did not prompt for update because the user last asked to be reminded less than %g days ago", self.remindPeriod);
        }
        return NO;
    }else if (self.applicationStoreVersion!=nil){
        
        if ([self.applicationStoreVersion compare:self.applicationVersion options:NSNumericSearch] == NSOrderedDescending){ // There is a new version
        return YES;
        }
    }
    
    //lets prompt!
    return NO;//YES;
}

- (NSString *)valueForKey:(NSString *)key inJSON:(id)json
{
    if ([json isKindOfClass:[NSString class]])
    {
        //use legacy parser
        NSRange keyRange = [json rangeOfString:[NSString stringWithFormat:@"\"%@\"", key]];
        if (keyRange.location != NSNotFound)
        {
            NSInteger start = keyRange.location + keyRange.length;
            NSRange valueStart = [json rangeOfString:@":" options:(NSStringCompareOptions)0 range:NSMakeRange(start, [(NSString *)json length] - start)];
            if (valueStart.location != NSNotFound)
            {
                start = valueStart.location + 1;
                NSRange valueEnd = [json rangeOfString:@"," options:(NSStringCompareOptions)0 range:NSMakeRange(start, [(NSString *)json length] - start)];
                if (valueEnd.location != NSNotFound)
                {
                    NSString *value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    while ([value hasPrefix:@"\""] && ![value hasSuffix:@"\""])
                    {
                        if (valueEnd.location == NSNotFound)
                        {
                            break;
                        }
                        NSInteger newStart = valueEnd.location + 1;
                        valueEnd = [json rangeOfString:@"," options:(NSStringCompareOptions)0 range:NSMakeRange(newStart, [(NSString *)json length] - newStart)];
                        value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    }
                    
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                    value = [value stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                    value = [value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\f" withString:@"\f"];
                    value = [value stringByReplacingOccurrencesOfString:@"\\b" withString:@"\f"];
                    
                    while (YES)
                    {
                        NSRange unicode = [value rangeOfString:@"\\u"];
                        if (unicode.location == NSNotFound || unicode.location + unicode.length == 0)
                        {
                            break;
                        }
                        
                        uint32_t c = 0;
                        NSString *hex = [value substringWithRange:NSMakeRange(unicode.location + 2, 4)];
                        NSScanner *scanner = [NSScanner scannerWithString:hex];
                        [scanner scanHexInt:&c];
                        
                        if (c <= 0xffff)
                        {
                            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C", (unichar)c]];
                        }
                        else
                        {
                            //convert character to surrogate pair
                            uint16_t x = (uint16_t)c;
                            uint16_t u = (c >> 16) & ((1 << 5) - 1);
                            uint16_t w = (uint16_t)u - 1;
                            unichar high = 0xd800 | (w << 6) | x >> 10;
                            unichar low = (uint16_t)(0xdc00 | (x & ((1 << 10) - 1)));
                            
                            value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C%C", high, low]];
                        }
                    }
                    return value;
                }
            }
        }
    }
    else
    {
        return json[key];
    }
    return nil;
}

- (void)setAppStoreIDOnMainThread:(NSString *)appStoreIDString
{
    _appStoreID = [appStoreIDString integerValue];
    [[NSUserDefaults standardUserDefaults] setInteger:_appStoreID forKey:iLinkAppStoreIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setArtistIDOnMainThread:(NSString *)artistIDString
{
    _artistID = [artistIDString integerValue];
    [[NSUserDefaults standardUserDefaults] setInteger:_artistID forKey:iLinkArtistIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}




- (void)connectionSucceeded
{
    if (self.checkingForAppStoreID)
    {
        //no longer checking
        self.checkingForPrompt = NO;
        self.checkingForAppStoreID = NO;
        
        //open app store
       // [self openRatingsPageInAppStore];
    }
    else if (self.checkingForPrompt)
    {
        //no longer checking
        self.checkingForPrompt = NO;
        
        //confirm with delegate
        if (![self.delegate iLinkShouldPromptForUpdate])
        {
            if (self.verboseLogging)
            {
                NSLog(@"iLink did not display the rating prompt because the iLinkShouldPromptForUpdate delegate method returned NO");
            }
            return;
        }
        
        //prompt user
        [self promptForUpdate];
    }
}

- (void)connectionError:(NSError *)error
{
    if (//self.checkingForPrompt ||
        self.checkingForAppStoreID)
    {
        //no longer checking
        self.checkingForPrompt = NO;
        self.checkingForAppStoreID = NO;
        
        //log the error
        if (error)
        {
            NSLog(@"iLink rating process failed because: %@", [error localizedDescription]);
        }
        else
        {
            NSLog(@"iLink rating process failed because an unknown error occured");
        }
        
        //could not connect
        [self.delegate iLinkCouldNotConnectToAppStore:error];
    }
}

- (void)checkForConnectivityInBackground
{
    if ([NSThread isMainThread])
    {
        [self performSelectorInBackground:@selector(checkForConnectivityInBackground) withObject:nil];
        return;
    }
    
    @autoreleasepool
    {
        //prevent concurrent checks
        static BOOL checking = NO;
        if (checking) return;
        checking = YES;
        
        //first check iTunes
        NSString *iTunesServiceURL = [NSString stringWithFormat:iLinkAppLookupURLFormat, self.appStoreCountry];
        if (_appStoreID) //important that we check ivar and not getter in case it has changed
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?id=%@", @(_appStoreID)];
        }
        else 
        {
            iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?bundleId=%@", self.applicationBundleID];
        }
        
        if (self.verboseLogging)
        {
            NSLog(@"iLink is checking %@ to retrieve the App Store details...", iTunesServiceURL);
        }
        
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunesServiceURL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:REQUEST_TIMEOUT];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
        if (data && statusCode == 200)
        {
            //in case error is garbage...
            error = nil;
            
            id json = nil;
            if ([NSJSONSerialization class])
            {
                json = [[NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error][@"results"] lastObject];
            }
            else
            {
                //convert to string
                json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            
            if (!error)
            {
                //check bundle ID matches
                NSString *bundleID = [self valueForKey:@"bundleId" inJSON:json];
                if (bundleID)
                {
                    if ([bundleID isEqualToString:self.applicationBundleID])
                    {
                        //get genre
                        if (self.appStoreGenreID == 0)
                        {
                            self.appStoreGenreID = [[self valueForKey:@"primaryGenreId" inJSON:json] integerValue];
                        }
                        
                        //get app id
                        if (!_appStoreID)
                        {
                            NSString *appStoreIDString = [self valueForKey:@"trackId" inJSON:json];
                            [self performSelectorOnMainThread:@selector(setAppStoreIDOnMainThread:) withObject:appStoreIDString waitUntilDone:YES];
                            
                            if (self.verboseLogging)
                            {
                                NSLog(@"iLink found the app on iTunes. The App Store ID is %@", appStoreIDString);
                            }
                            
                            
                    
                        }
                        
                        //check version
                        if (!self.applicationStoreVersion)
                        {
                            NSString *latestVersion = [self valueForKey:@"version" inJSON:json];
                            
                            self.applicationStoreVersion = latestVersion;
                            
                            NSLog(@"Latest version on store : %@",latestVersion);
                            if ([latestVersion compare:self.applicationVersion options:NSNumericSearch] == NSOrderedDescending)
                            {
                                if (self.verboseLogging)
                                {
                                    NSLog(@"iLink found that the installed application version (%@) is not the latest version on the App Store, which is %@", self.applicationVersion, latestVersion);
                                }
                                
                                error = [NSError errorWithDomain:iLinkErrorDomain code:iLinkErrorApplicationIsNotLatestVersion userInfo:@{NSLocalizedDescriptionKey: @"Installed app is not the latest version available"}];
                                
                                //[self shouldPromptForUpdate];
                            }
                        }
                        
                        if (!_artistID)
                        {
                            NSString *artistIDString = [self valueForKey:@"artistId" inJSON:json];
                            [self performSelectorOnMainThread:@selector(setArtistIDOnMainThread:) withObject:artistIDString waitUntilDone:YES];
                            
                            if (self.verboseLogging)
                            {
                                NSLog(@"iLink found the artist on iTunes. The Artist ID is %@", artistIDString);
                            }
                            
                            
                            
                        }
                        
                        
                        
                        
                        if ([self.delegate respondsToSelector:@selector(iLinkDidFindiTunesInfo)]) {
                            [self.delegate iLinkDidFindiTunesInfo];
                        }else if (self.verboseLogging)
                        {
                            NSLog(@"iLinkDidFindiTunesInfo isn't implemented. implement that if you want to get notified");
                        }

                        
                    }
                    else
                    {
                        if (self.verboseLogging)
                        {
                            NSLog(@"iLink found that the application bundle ID (%@) does not match the bundle ID of the app found on iTunes (%@) with the specified App Store ID (%@)", self.applicationBundleID, bundleID, @(self.appStoreID));
                        }
                        
                        error = [NSError errorWithDomain:iLinkErrorDomain code:iLinkErrorBundleIdDoesNotMatchAppStore userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Application bundle ID does not match expected value of %@", bundleID]}];
                    }
                }
                else if (_appStoreID || !self.ratingsURL || !self.appLocalURL || !self.appShareURL)
                {
                    if (self.verboseLogging)
                    {
                        NSLog(@"iLink could not find this application on iTunes. If your app is not intended for App Store release then you must specify a custom relevant URL (ratingURL/appLocalURL/appShareURL). If this is the first release of your application then it's not a problem that it cannot be found on the store yet");
                    }
                    if (!self.previewMode)
                    {
                        error = [NSError errorWithDomain:iLinkErrorDomain
                                                    code:iLinkErrorApplicationNotFoundOnAppStore
                                                userInfo:@{NSLocalizedDescriptionKey: @"The application could not be found on the App Store."}];
                    }
                }
                else if (!_appStoreID && self.verboseLogging)
                {
                    NSLog(@"iLink could not find your app on iTunes. If your app is not yet on the store or is not intended for App Store release then don't worry about this");
                }
            }
        }
        else if (statusCode >= 400)
        {
            //http error
            NSString *message = [NSString stringWithFormat:@"The server returned a %@ error", @(statusCode)];
            error = [NSError errorWithDomain:@"HTTPResponseErrorDomain" code:statusCode userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        
        //handle errors (ignoring sandbox issues)
        if (error && !(error.code == EPERM && [error.domain isEqualToString:NSPOSIXErrorDomain] && _appStoreID))
        {
            [self performSelectorOnMainThread:@selector(connectionError:) withObject:error waitUntilDone:YES];
        }
        else if (self.appStoreID || self.previewMode)
        {
            //show prompt
            [self performSelectorOnMainThread:@selector(connectionSucceeded) withObject:nil waitUntilDone:YES];
        }
        
        //finished
        checking = NO;
    }
}

- (void)promptIfNetworkAvailable
{
    if (!self.checkingForPrompt && !self.checkingForAppStoreID)
    {
        self.checkingForPrompt = YES;
        [self checkForConnectivityInBackground];
    }
}

 - (void)promptForUpdate
{
    if (!self.visibleAlert)
    {
    
#if TARGET_OS_IPHONE
    
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.messageTitle
                                                        message:self.message
                                                       delegate:(id<UIAlertViewDelegate>)self
                                              cancelButtonTitle:[self.cancelButtonLabel length] ? self.cancelButtonLabel: nil
                                              otherButtonTitles:self.updateButtonLabel//self.rateButtonLabel
                              , nil];
        if ([self.remindButtonLabel length])
        {
            [alert addButtonWithTitle:self.remindButtonLabel];
        }
        
        self.visibleAlert = alert;
        [self.visibleAlert show];
#else

        //only show when main window is available
        if (self.onlyPromptIfMainWindowIsAvailable && ![[NSApplication sharedApplication] mainWindow])
        {
            [self performSelector:@selector(promptForRating) withObject:nil afterDelay:0.5];
            return;
        }
        
        self.visibleAlert = [NSAlert alertWithMessageText:self.messageTitle
                                            defaultButton:self.updateButtonLabel//self.rateButtonLabel
                                          alternateButton:self.cancelButtonLabel
                                              otherButton:nil
                                informativeTextWithFormat:@"%@", self.message];
        
        if ([self.remindButtonLabel length])
        {
            [self.visibleAlert addButtonWithTitle:self.remindButtonLabel];
        }
        
        [self.visibleAlert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                      modalDelegate:self
                                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                        contextInfo:nil];

#endif

        //inform about prompt
        [self.delegate iLinkDidPromptForUpdate];
    }
}

- (void)applicationLaunched
{
    //check if this is a new version
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:iLinkLastVersionUsedKey] isEqualToString:self.applicationVersion])
    {
        //reset counts
        [defaults setObject:self.applicationVersion forKey:iLinkLastVersionUsedKey];
        [defaults setObject:[NSDate date] forKey:iLinkFirstUsedKey];
        [defaults setInteger:0 forKey:iLinkUseCountKey];
        [defaults setInteger:0 forKey:iLinkEventCountKey];
        [defaults setObject:nil forKey:iLinkLastRemindedKey];
        [defaults synchronize];

        //inform about app update
        [self.delegate iLinkDidDetectAppUpdate];
    }
    
    [self incrementUseCount];
    [self checkForConnectivityInBackground];
    
    // Ugly implementation for waiting till network respond. Should be done by a callback.
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        if (self.promptAtLaunch && [self shouldPromptForUpdate])//[self shouldPromptForRating])
        {
            [self promptIfNetworkAvailable];
        }
    });
    
    
}

#if TARGET_OS_IPHONE

- (void)applicationWillEnterForeground
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [self incrementUseCount];
        [self checkForConnectivityInBackground];
        if (self.promptAtLaunch && [self shouldPromptForUpdate])//[self shouldPromptForRating])
        {
            [self promptIfNetworkAvailable];
        }
    }
}

- (void)openRatingsPageInAppStore
{
    if (!_ratingsURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        //if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:self.ratingsURL])
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink will open the App Store ratings page using the following URL: %@", self.ratingsURL);
        }
        
        [[UIApplication sharedApplication] openURL:self.ratingsURL];
        [self.delegate iLinkDidOpenAppStore];
    }
    else
    {
         NSString *message = [NSString stringWithFormat:@"iLink was unable to open the specified ratings URL: %@", self.ratingsURL];
        
#if TARGET_IPHONE_SIMULATOR
        
        if ([[self.ratingsURL scheme] isEqualToString:iLinkiOSAppStoreURLScheme])
        {
            message = @"iLink could not open the ratings page because the App Store is not available on the iOS simulator";
        }
        
#endif
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:iLinkErrorDomain code:iLinkErrorCouldNotOpenRatingPageURL userInfo:@{NSLocalizedDescriptionKey: message}];
        [self.delegate iLinkCouldNotConnectToAppStore:error];
    }
}

- (void)openAppPageInAppStore
{
    if (!_appLocalURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        //if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:self.appLocalURL])
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink will open the App Store app page using the following URL: %@", self.appLocalURL);
        }
        
        [[UIApplication sharedApplication] openURL:self.appLocalURL];
        [self.delegate iLinkDidOpenAppStore];
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"iLink was unable to open the specified app URL: %@", self.appLocalURL];
        
#if TARGET_IPHONE_SIMULATOR
        
        if ([[self.appLocalURL scheme] isEqualToString:iLinkiOSAppStoreURLScheme])
        {
            message = @"iLink could not open the app page because the App Store is not available on the iOS simulator";
        }
        
#endif
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:iLinkErrorDomain code:iLinkErrorCouldNotOpenAppPageURL userInfo:@{NSLocalizedDescriptionKey: message}];
        [self.delegate iLinkCouldNotConnectToAppStore:error];
    }
}

- (void)openArtistPageInAppStore
{
    if (!_artistURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        //if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[self iLinkGetDeveloperURLforLocal]])
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink will open the Artist page using the following URL: %@", [self iLinkGetDeveloperURLforLocal]);
        }
        
        [[UIApplication sharedApplication] openURL:[self iLinkGetDeveloperURLforLocal]];
        [self.delegate iLinkDidOpenAppStore];
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"iLink was unable to open the specified artist URL: %@", self.artistURL];
        
#if TARGET_IPHONE_SIMULATOR
        
        if ([[self.artistURL scheme] isEqualToString:iLinkiOSAppStoreURLScheme])
        {
            message = @"iLink could not open the artist page because the App Store is not available on the iOS simulator";
        }
        
#endif
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:iLinkErrorDomain code:iLinkErrorCouldNotOpenAppPageURL userInfo:@{NSLocalizedDescriptionKey: message}];
        [self.delegate iLinkCouldNotConnectToAppStore:error];
    }
}


- (void)openAppPageInAppStoreWithAppleID: (NSUInteger) appStoreIDtoOpen
{
    
    
    if ([[UIApplication sharedApplication] canOpenURL:[self appLocalURLWithAppStoreID:appStoreIDtoOpen]])
    {
        if (self.verboseLogging)
        {
            NSLog(@"iLink will open the App Store app page using the following URL: %@", [self appLocalURLWithAppStoreID:appStoreIDtoOpen]);
        }
        
        [[UIApplication sharedApplication] openURL:[self appLocalURLWithAppStoreID:appStoreIDtoOpen]];
        [self.delegate iLinkDidOpenAppStore];
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"iLink was unable to open the specified app URL: %@", [self appLocalURLWithAppStoreID:appStoreIDtoOpen]];
        
#if TARGET_IPHONE_SIMULATOR
        
        if ([[[self appLocalURLWithAppStoreID:appStoreIDtoOpen] scheme] isEqualToString:iLinkiOSAppStoreURLScheme])
        {
            message = @"iLink could not open the app page because the App Store is not available on the iOS simulator";
        }
        
#endif
        NSLog(@"%@", message);
        NSError *error = [NSError errorWithDomain:iLinkErrorDomain code:iLinkErrorCouldNotOpenAppPageURL userInfo:@{NSLocalizedDescriptionKey: message}];
        [self.delegate iLinkCouldNotConnectToAppStore:error];
    }
}



- (void)resizeAlertView:(UIAlertView *)alertView
{
    if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0f)
    {
        NSInteger imageCount = 0;
        CGFloat offset = 0.0f;
        CGFloat messageOffset = 0.0f;
        for (UIView *view in alertView.subviews)
        {
            CGRect frame = view.frame;
            if ([view isKindOfClass:[UILabel class]])
            {
                UILabel *label = (UILabel *)view;
                if ([label.text isEqualToString:alertView.title])
                {
                    CGFloat height = label.frame.size.height;
                    [label sizeToFit];
                    offset = messageOffset = label.frame.size.height - height;
                    frame.size.height = label.frame.size.height;
                }
                else if ([label.text isEqualToString:alertView.message])
                {
                    label.lineBreakMode = NSLineBreakByWordWrapping;
                    label.numberOfLines = 0;
                    label.alpha = 1.0f;
                    [label sizeToFit];
                    offset += label.frame.size.height - frame.size.height;
                    frame.origin.y += messageOffset;
                    frame.size.height = label.frame.size.height;
                }
            }
            else if ([view isKindOfClass:[UITextView class]])
            {
                view.alpha = 0.0f;
            }
            else if ([view isKindOfClass:[UIImageView class]])
            {
                if (imageCount++ > 0)
                {
                    view.alpha = 0.0f;
                }
            }
            else if ([view isKindOfClass:[UIControl class]])
            {
                frame.origin.y += offset;
            }
            view.frame = frame;
        }
        CGRect frame = alertView.frame;
        frame.origin.y -= roundf(offset/2.0f);
        frame.size.height += offset;
        alertView.frame = frame;
    }
}

- (void)willRotate
{
    [self performSelectorOnMainThread:@selector(didRotate) withObject:nil waitUntilDone:NO];
}

- (void)didRotate
{
    if (self.previousOrientation != [UIApplication sharedApplication].statusBarOrientation)
    {
        self.previousOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self resizeAlertView:self.visibleAlert];
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    [self resizeAlertView:alertView];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {        
        //ignore this version
        self.declinedThisVersion = YES;
        
        //log event
        [self.delegate iLinkUserDidDeclineToUpdateApp];
    }
    else if (([self.cancelButtonLabel length] && buttonIndex == 2) ||
             ([self.cancelButtonLabel length] == 0 && buttonIndex == 1))
    {        
        //remind later
        self.lastReminded = [NSDate date];
        
        //log event
        [self.delegate iLinkUserDidRequestReminderToUpdateApp];

    }
    else
    {
        //mark as rated
        //self.ratedThisVersion = YES;
        
        //log event
        [self.delegate iLinkUserDidAttemptToUpdateApp];
        
        //if ([self.delegate iLinkShouldOpenAppStore])
        {
            //go to app page
            [self openAppPageInAppStore];
        }
    }
    
    //release alert
    self.visibleAlert = nil;
}

#else

- (void)openAppPageWhenAppStoreLaunched
{
    //check if app store is running
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
    {
        if ([app.bundleIdentifier isEqualToString:iLinkMacAppStoreBundleID])
        {
            //open app page
            [[NSWorkspace sharedWorkspace] performSelector:@selector(openURL:) withObject:self.ratingsURL afterDelay:MAC_APP_STORE_REFRESH_DELAY];
            return;
        }
    }
    
    //try again
    [self performSelector:@selector(openAppPageWhenAppStoreLaunched) withObject:nil afterDelay:0.0];
}

- (void)openRatingsPageInAppStore
{
    if (!_ratingsURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if (self.verboseLogging)
    {
        NSLog(@"iLink will open the App Store ratings page using the following URL: %@", self.ratingsURL);
    }
    
    [[NSWorkspace sharedWorkspace] openURL:self.ratingsURL];
    [self openAppPageWhenAppStoreLaunched];
    [self.delegate iLinkDidOpenAppStore];
}

- (void)openAppPageInAppStore
{
    if (!_appLocalURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
       // if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if (self.verboseLogging)
    {
        NSLog(@"iLink will open the App Store app page using the following URL: %@", self.appLocalURL);
    }
    
    [[NSWorkspace sharedWorkspace] openURL:self.appLocalURL];
    [self openAppPageWhenAppStoreLaunched];
    [self.delegate iLinkDidOpenAppStore];
}

- (void)openArtistPageInAppStore
{
    if (!_artistURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        // if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return;
    }
    
    if (self.verboseLogging)
    {
        NSLog(@"iLink will open the Artist page using the following URL: %@", [self iLinkGetDeveloperURLforLocal]);
    }
    
    [[NSWorkspace sharedWorkspace] openURL:[self iLinkGetDeveloperURLforLocal]];
    [self openAppPageWhenAppStoreLaunched];
    [self.delegate iLinkDidOpenAppStore];
}

- (void)openAppPageInAppStoreWithAppleID: (NSUInteger) appStoreIDtoOpen
{
    
    if (self.verboseLogging)
    {
        NSLog(@"iLink will open the App Store app page using the following URL: %@", [self appLocalURLWithAppStoreID:appStoreIDtoOpen]);
    }

    [[NSWorkspace sharedWorkspace] openURL:[self appLocalURLWithAppStoreID:appStoreIDtoOpen] ];
    [self openAppPageWhenAppStoreLaunched];
    [self.delegate iLinkDidOpenAppStore];
}

- (void)alertDidEnd:(__unused NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(__unused void *)contextInfo
{
    switch (returnCode)
    {
        case NSAlertAlternateReturn:
        {
            //ignore this version
            self.declinedThisVersion = YES;
            
            //log event
            [self.delegate iLinkUserDidDeclineToUpdateApp];
            
            break;
        }
        case NSAlertDefaultReturn:
        {
            //mark as rated
            //self.ratedThisVersion = YES;
            
            //log event
            [self.delegate iLinkUserDidAttemptToUpdateApp];
            
            //if ([self.delegate iLinkShouldOpenAppStore])
            {
                //launch mac app store
                [self openAppPageInAppStore];
            }
            break;
        }
        default:
        {
            //remind later
            self.lastReminded = [NSDate date];
            
            //log event
            [self.delegate iLinkUserDidRequestReminderToUpdateApp];
            
        }
    }
    
    //release alert
    self.visibleAlert = nil;
}

#endif

- (void)logEvent:(BOOL)deferPrompt
{
    [self incrementEventCount];
    if ((!deferPrompt) && [self shouldPromptForUpdate])
    {
        [self promptIfNetworkAvailable];
    }
}

#pragma mark -
#pragma mark iLink functions

- (void)iLinkOpenRatingsPageInAppStore{
    [self openRatingsPageInAppStore];
}

- (NSURL *)iLinkGetRatingURL{
    if (!_ratingsURL && !self.appStoreID)
    {
        self.checkingForAppStoreID = YES;
        //if (!self.checkingForPrompt)
        {
            [self checkForConnectivityInBackground];
        }
        return [NSURL URLWithString:@""];
    }
    
    return self.ratingsURL;
}


- (NSURL *)appLocalURL
{
    if (_appLocalURL)
    {
        return _appLocalURL;
    }
    
    if (!self.appStoreID && self.verboseLogging)
    {
        NSLog(@"iLink could not find the App Store ID for this application. If the application is not intended for App Store release then you must specify a custom appLocalURL.");
    }
    
#if TARGET_OS_IPHONE
    
    // itms-apps
    return [NSURL URLWithString:[NSString stringWithFormat: iLinkiOS7AppStoreURLFormat, @(self.appStoreID),iLinkParamsCode]];
    
#else
    
    return [NSURL URLWithString:[NSString stringWithFormat:iLinkMacAppStoreURLFormat, @(self.appStoreID),iLinkParamsCode]];
    
#endif
    
}

- (NSURL *)appLocalURLWithAppStoreID:(NSUInteger)appStoreIDofApp
{
    
    
#if TARGET_OS_IPHONE
    
    // itms-apps
    return [NSURL URLWithString:[NSString stringWithFormat: iLinkiOS7AppStoreURLFormat, @(appStoreIDofApp),iLinkParamsCode]];
    
#else
    
    return [NSURL URLWithString:[NSString stringWithFormat:iLinkMacAppStoreURLFormat, @(appStoreIDofApp),iLinkParamsCode]];
    
#endif
    
}


- (NSURL *)appShareURL
{
    if (_appShareURL)
    {
        return _appShareURL;
    }
    
    if (!self.appStoreID && self.verboseLogging)
    {
        NSLog(@"iLink could not find the App Store ID for this application. If the application is not intended for App Store release then you must specify a custom appShareURL.");
    }
    
    
    return [NSURL URLWithString:[NSString stringWithFormat: iLinkRegulariOSAppStoreURLFormat, @(self.appStoreID),iLinkParamsCode]];
    
}

- (NSURL *)artistURL
{
    if (_artistURL)
    {
        return _artistURL;
    }
    
    if (!self.artistID && self.verboseLogging)
    {
        NSLog(@"iLink could not find the Artist ID for this application. If the application is not intended for App Store release then you must specify a custom appLocalURL.");
    }
    
#if TARGET_OS_IPHONE
    
    // itms-apps
    return [NSURL URLWithString:[NSString stringWithFormat: iLinkArtistAppStoreURLFormat, @(self.artistID),iLinkParamsCode]];
    
#else
    
    return [NSURL URLWithString:[NSString stringWithFormat:iLinkArtistAppStoreURLFormat, @(self.artistID),iLinkParamsCode]];
    
#endif
    
}




- (NSURL *)iLinkGetAppURLforLocal
{
    return self.appLocalURL;
    
}

- (NSURL *)iLinkGetAppURLforSharing
{
    return self.appShareURL;
    
}

- (void)iLinkOpenAppPageInAppStore{
    [self openAppPageInAppStore];
    
}

- (void)iLinkOpenAppPageInAppStoreWithAppleID:(NSUInteger)appStoreIDtoOpen{
    [self openAppPageInAppStoreWithAppleID: appStoreIDtoOpen];
}

- (NSURL *)iLinkGetDeveloperURLforSharing{
    return self.artistURL;
}
- (NSURL *)iLinkGetDeveloperURLforLocal{

#if TARGET_OS_IPHONE
    
    
    return [NSURL URLWithString:[NSString stringWithFormat: iLinkiOSArtistAppStoreURLFormat, @(self.artistID),iLinkParamsCode]];
    
#else
    
    return [NSURL URLWithString:[NSString stringWithFormat:iLinkMacArtistAppStoreURLFormat, @(self.artistID),iLinkParamsCode]];
    
#endif
}

- (void)iLinkOpenDeveloperPage{
    [self openArtistPageInAppStore];
}



@end
