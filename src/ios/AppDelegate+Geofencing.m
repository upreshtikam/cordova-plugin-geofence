//
//  AppDelegate+Geofencing.m
//  OutSystems
//
//  Created by Vitor Oliveira on 09/03/16.
//
//

#import "AppDelegate+Geofencing.h"
#import <CoreLocation/CLCircularRegion.h>

CLLocationManager *knewLocationManager;
@implementation AppDelegate (Geofencing)

@dynamic locationManager;

- (void)setLocationManager:(CLLocationManager *)locationManager
{
    objc_setAssociatedObject(self, (__bridge const void *)(knewLocationManager), locationManager, OBJC_ASSOCIATION_ASSIGN);
}

- (id)locationManager
{
    return objc_getAssociatedObject(self, (__bridge const void *)(knewLocationManager));
}

+ (void)load {
    
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        
        SEL originalSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector = @selector(geofencing_application:didFinishLaunchingWithOptions:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
    });
}

- (BOOL) geofencing_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    knewLocationManager = [CLLocationManager new];
    knewLocationManager.delegate = self;
    [knewLocationManager requestAlwaysAuthorization];

    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    
    return [self geofencing_application:application didFinishLaunchingWithOptions:launchOptions];
}

-(void) locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateInactive)
    {
        if ([region isKindOfClass:[CLCircularRegion class]]){
            UILocalNotification *notification = [[UILocalNotification alloc] init];
           // if (IsAtLeastiOSVersion(@"8.2"))
             //   notification.alertTitle = @"Nativezer Shell";
            notification.alertBody = @"Enter in a new Geofencing";
            notification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    }
}

-(void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateInactive)
    {
        if ([region isKindOfClass:[CLCircularRegion class]]){
            UILocalNotification *notification = [[UILocalNotification alloc] init];
          //  if (IsAtLeastiOSVersion(@"8.2"))
          //      notification.alertTitle = @"Nativezer Shell";
            notification.alertBody = @"Exit from a Geofencing!";
            notification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    }
}

@end
