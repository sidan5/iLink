Purpose
--------------

iLink is a library that help you build the right link to the App Store for any usage within your app (appropriate link to rate, link to share for the app or for the developer profile) all this without knowing the Apple ID of the app or details about developer account (usually you should set it beforehand but you don't have to anymore). This library would also prompt the user to update the app if there is a newer version on the App Store.
Works both on iOS & Mac OS-X, Just drop the 2 files of the library directly to your project and use the methods to open the app page or developer page without setting up anything beforehand.

Please check the Example apps (iOS/Mac) for fast integration.

Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 8.4 / Mac OS 10.10.4 (Xcode 6.4, Apple LLVM compiler 6.1.0)
* Earliest supported deployment target - iOS 5.1 / Mac OS 10.7

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

iLink requires ARC. If you wish to use iLink in a non-ARC project, just add the -fobjc-arc compiler flag to the iLink.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click iLink.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in iLink.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including iLink.m) are checked.


Thread Safety
--------------

iLink uses threading internally to avoid blocking the UI, but none of the iLink external interfaces are thread safe and you should not call any methods or set any properties on iLink except from the main thread.


Installation
--------------

To install iLink into your app, drag the iLink.h, .m into your project. 
You could also use cocoapods (recommended) by adding this line to your podfile:
    pod 'iLink', '~> 1.0.2'

iLink typically requires no configuration at all and will simply run automatically, using the application's bundle ID to look the app ID up on the App Store.

**Note:** If you have apps with matching bundle IDs on both the Mac and iOS app stores (even if they use different capitalisation), the lookup mechanism won't work, so you'll need to manually set the appStoreID property, which is a numeric ID that can be found in iTunes Connect after you set up an app. Also, if you are creating a sandboxed Mac app and your app does not request the network access permission then you will need to set the appStoreID because it cannot be retrieved from the iTunes service. 

If you do wish to customise iLink, the best time to do this is *before* the app has finished launching. The easiest way to do this is to add the iLink configuration code in your AppDelegate's `initialize` method, like this:

    #import "iLink.h"

	+ (void)initialize
	{
		//configure iLink
		[iLink sharedInstance].globalPromptForUpdate = YES; // If you want iLink to prompt user to update when the app is old.
	}
	
	
Methods
--------------

iLink is used to open App page, developer profile or rating page for the app using the following methods:

--- App Links 

	- (void)iLinkOpenAppPageInAppStore;  

This method would open the app page in the appropriate way in the Mac or iPhone app store, depending on which platform iLink is running on. Important is that this would open the store directly without opening safari first.

	- (NSURL *)iLinkGetAppURLforLocal; 

This method would create the relevant URL for locally open the app store (it is recommended to use iLinkOpenAppPageInAppStore to open the store and not getting the link). Use this if you want to open that inside the app manually.

	- (NSURL *)iLinkGetAppURLforSharing; 

This method would create the appropriate link to share on social networks/email etc. Use this if you want to share the link outside the app.

	- (void)iLinkOpenAppPageInAppStoreWithAppleID:(NSUInteger)appStoreIDtoOpen; 

This method would create the appropriate link to the app with Apple ID appStoreIDtoOpen. Use this to open another specific app for example the paid version or any reference to other app. Code would recognize if it's an iOS app or Mac app. But pay attention to send the right ID to each app (there isn't same Apple ID for Mac&iOS app for time of writing so you would need to check that if your code support both).


--- Developer Links

	- (void)iLinkOpenDeveloperPage;

This method would open the developer page in the appropriate way in the Mac or iPhone app store, depending on which platform iLink is running on. Important is that this would open the store directly without opening safari first.

	- (NSURL *)iLinkGetDeveloperURLforLocal; 

Use this method if you want to open the Developer URL by yourself and not by using iLinkOpenDeveloperPage method for example if you want to open that page inside the app.

	- (NSURL *)iLinkGetDeveloperURLforSharing; 
This method return the URL for the developer profile in the best way for sharing. Use this if you want to share the link outside the app (for example on social networks).
    
--- Rating Links 

    - (void)openRatingsPageInAppStore;

This method opens the application ratings page in the Mac or iPhone app store, depending on which platform iLink is running on. This method does not perform any checks to verify that the machine has network access or that the app store is available. It also does not call the `-iLinkShouldOpenAppStore` delegate method. You should use this method to open the ratings page instead of the ratingsURL property, as the process for launching the app store is more complex than merely opening the URL in many cases. Note that this method depends on the `appStoreID` which is only retrieved after polling the iTunes server. If you call this method without first doing an update check, you will either need to set the `appStoreID` property yourself beforehand, or risk that the method may take some time to make a network call, or fail entirely. On success, this method will call the `-iLinkDidOpenAppStore` delegate method. On Failure it will call the `-iLinkCouldNotConnectToAppStore:` delegate method.

	- (NSURL *)iLinkGetRatingURL;
	
This method returns the relevant URL for rating the current app (if you have something smart to do with it).


Configuration
--------------

To configure iLink, there are a number of properties of the iLink class that can alter the behaviour and appearance of iLink. These should be mostly self- explanatory, but they are documented below:

    @property (nonatomic, assign) BOOL globalPromptForUpdate;
    
This would set if iLink would automatically check if there is an update for the app on iTunes and prompt the user to update. Default is set to YES meaning iLink would automatically ask the user to update if there is an update for the app, prompt would include a reminder of 1 day (after user press "Remind me later").

    @property (nonatomic, assign) BOOL aggressiveUpdatePrompt;

This would set if iLink would automatically check if there is an update for the app on iTunes and prompt the user to update always. Default is set to NO, if set to YES meaning iLink would automatically ask the user to update if there is an update for the app, prompt would include only "Update NOW!" option (user WON'T be able to access the app without updating). Use this option carefully.
    
    @property (nonatomic, assign) NSUInteger appStoreID;

This should match the iTunes app ID of your application, which you can get from iTunes connect after setting up your app. This value is not normally necessary and is generally only required if you have the aforementioned conflict between bundle IDs for your Mac and iOS apps, or in the case of Sandboxed Mac apps, if your app does not have network permission because it won't be able to fetch the appStoreID automatically using iTunes services.

    @property (nonatomic, copy) NSString *appStoreCountry;

This is the two-letter country code used to specify which iTunes store to check. It is set automatically from the device locale preferences, so shouldn't need to be changed in most cases. You can override this to point to the US store, or another specific store if you prefer, which may be a good idea if your app is only available in certain countries.

    @property (nonatomic, copy) NSString *applicationName;

This is the name of the app displayed in the iLink alert. It is set automatically from the application's info.plist, but you may wish to override it with a shorter or longer version.

    @property (nonatomic, copy) NSString *applicationBundleID;

This is the application bundle ID, used to retrieve the `appStoreID` and `appStoreGenreID` from iTunes. This is set automatically from the app's info.plist, so you shouldn't need to change it except for testing purposes.

    @property (nonatomic, assign) float remindPeriod;

How long the app should wait before reminding a user to update after they select the "remind me later" option (measured in days). A value of zero means the app will remind the user next launch. Note that this value supersedes the other criteria, so the app won't prompt for an update during the reminder period, even if a new version is released in the meantime.  This defaults to 1 day.

    @property (nonatomic, copy) NSString *messageTitle;

The title displayed for the update prompt. If you don't want to display a title then set this to `@""`;

    @property (nonatomic, copy) NSString *message;

The update prompt message. This should be polite and courteous, but not too wordy. If you don't want to display a message then set this to `@""`;

    @property (nonatomic, copy) NSString *cancelButtonLabel;

The button label for the button to dismiss the update prompt without updating the app.

    @property (nonatomic, copy) NSString *updateButtonLabel;

The button label for the button the user presses if they do want to update the app.

    @property (nonatomic, copy) NSString *remindButtonLabel;

The button label for the button the user presses if they don't want to update the app immediately, but do want to be reminded about it in future. Set this to `@""` if you don't want to display the remind me button - e.g. if you don't have space on screen.

    @property (nonatomic, assign) BOOL useAllAvailableLanguages;

By default, iLink will use all available languages in the iLink.bundle, even if used in an app that does not support localisation. If you would prefer to restrict iLink to only use the same set of languages that your application already supports, set this property to NO. (Defaults to YES).

    @property (nonatomic, assign) BOOL onlyPromptIfMainWindowIsAvailable;

This setting is applicable to Mac OS only. By default, on Mac OS the iLink update alert is displayed as sheet on the main window. Some applications do not have a main window, so this approach doesn't work. For such applications, set this property to NO to allow the iLink update alert to be displayed as a regular modal window.

	@property (nonatomic, assign) NSString *linkParams;

By default, iLink would use a default parameters to work with the App Store. In any case you want to change the parameters sent to the store (for example if you have afiliate code or any other specific important parameter) please do it by changing this property.

    @property (nonatomic, assign) BOOL promptAtLaunch;

Set this to NO to disable the update prompt appearing automatically when the application launches or returns from the background. The update criteria will continue to be tracked, but the prompt will not be displayed automatically while this setting is in effect. You can use this option if you wish to manually control display of the update prompt.

    @property (nonatomic, assign) BOOL verboseLogging;

This option will cause iLink to send detailed logs to the console about the prompt decision process. If your app is not correctly prompting for an update when you would expect it to, this will help you figure out why. Verbose logging is enabled by default on debug builds, and disabled on release and deployment builds.

    @property (nonatomic, assign) BOOL previewMode;

If set to YES, iLink will always display the update prompt on launch, regardless of how long the app has been in use or whether it's the latest version. Use this to proofread your message and check your configuration is correct during testing, but disable it for the final release (defaults to NO).

	@property (nonatomic, assign) id<iLinkDelegate> delegate;

An object you have supplied that implements the `iLinkDelegate` protocol, documented below. Use this to detect and/or override iLink's default behaviour. This defaults to the App Delegate, so if you are using your App Delegate as your iLink delegate, you don't need to set this property. 



Delegate methods
---------------

The iLinkDelegate protocol provides the following methods that can be used intercept iLink events and override the default behaviour. All methods are optional.

	- (void)iLinkDidFindiTunesInfo;

This method would be called after iLink succeeded to fetch all app data from iTunes. **Important:**To be on the safe side it is recommended to use the links provided by iLink only after this method is called.

    - (void)iLinkCouldNotConnectToAppStore:(NSError *)error;

This method is called if iLink cannot connect to the App Store, usually because the network connection is down. This may also fire if your app does not have access to the network due to Sandbox permissions, in which case you will need to manually set the appStoreID so that iLink can still function.

	- (BOOL)iLinkShouldPromptForUpdate;
	
Should return YES if you want iLink to ask the user for updating the app when there is a newer version available (only if the current version is old).

    - (void)iLinkDidDetectAppUpdate;

This method is called if iLink detects that the application has been updated since the last time it was launched.

	- (void)iLinkDidOpenAppStore;
	
This method is called immediately before the app page on App Store is displayed. 
	
   	- (void)iLinkDidPromptForUpdate;

This method is called immediately before the update prompt is displayed. This is useful if you use analytics to track what percentage of users see the update prompt and then go to the app store. This can help you fine tune the circumstances around when/how you show the prompt.

    - (void)iLinkUserDidAttemptToUpdateApp;
    
This is called when the user pressed the update button in the update prompt. This is useful if you want to log user interaction with iLink. 
    
    - (void)iLinkUserDidDeclineToUpdateApp;
    
This is called when the user declines to update the app. This is useful if you want to log user interaction with iLink. 
    
    - (void)iLinkUserDidRequestReminderToUpdateApp;

This is called when the user asks to be reminded to update the app. This is useful if you want to log user interaction with iLink. 




Example Projects
---------------

When you build and run the basic Mac or iPhone example project for the first time, it will show an alert asking you to update the app. This may be because the previewMode option is set.

Pay attention to disable the previewMode option (if it's on) and play with the other settings to see how the app behaves in practice.

