//
//  AppDelegate+Geofencing.m
//  OutSystems
//
//  Created by Vitor Oliveira on 09/03/16.
//
//

#import "AppDelegate+Geofencing.h"
#import <CoreLocation/CLCircularRegion.h>
#import "OutSystems-Swift.h"

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
    if (state == UIApplicationStateInactive ||state == UIApplicationStateBackground)
    {
        if ([region isKindOfClass:[CLCircularRegion class]]){
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            // if (IsAtLeastiOSVersion(@"8.2"))
            
            //get data from databse swift
            WrapperStore *wrapper = [[WrapperStore alloc] init];
            NSString * geofencing = [wrapper getGeofencingById:region.identifier];
            //get json to dicionary
            NSError *jsonError;
            NSData *objectData = [geofencing dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:objectData
                                                                              options:NSJSONReadingMutableContainers
                                                                                error:&jsonError];
            //form dicionary from parced data
            notification.alertBody = [[parsedData valueForKey:@"notification"] valueForKey:@"text"];
            notification.soundName = UILocalNotificationDefaultSoundName;
            //form dicionary to userInfo
            NSMutableDictionary *userInfoDici = [[NSMutableDictionary alloc]init];
            [userInfoDici setValue:@"inside" forKey:@"state"];
            [userInfoDici setObject:parsedData forKey:@"geofence.notification.data"];
            notification.userInfo = userInfoDici;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    }
}

-(void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateInactive ||state == UIApplicationStateBackground)
    {
        if ([region isKindOfClass:[CLCircularRegion class]]){
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            //  if (IsAtLeastiOSVersion(@"8.2"))
            
            //get data from databse swift
            WrapperStore *wrapper = [[WrapperStore alloc] init];
            NSString * geofencing = [wrapper getGeofencingById:region.identifier];
            //get json to dicionary
            NSError *jsonError;
            NSData *objectData = [geofencing dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:objectData
                                                                              options:NSJSONReadingMutableContainers
                                                                                error:&jsonError];
            //form dicionary from parced data
            notification.alertBody = [[parsedData valueForKey:@"notification"] valueForKey:@"text"];
            notification.soundName = UILocalNotificationDefaultSoundName;
            //form dicionary to userInfo
            NSMutableDictionary *userInfoDici = [[NSMutableDictionary alloc]init];
            [userInfoDici setValue:@"outside" forKey:@"state"];
            [userInfoDici setObject:parsedData forKey:@"geofence.notification.data"];
            notification.userInfo = userInfoDici;
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    }
}

@end
