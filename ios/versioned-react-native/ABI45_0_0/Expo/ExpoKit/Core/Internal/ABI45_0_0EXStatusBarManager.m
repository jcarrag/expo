
#import "ABI45_0_0EXStatusBarManager.h"
#import "ABI45_0_0EXUnversioned.h"

#import <ABI45_0_0React/ABI45_0_0RCTEventDispatcher.h>
#import <ABI45_0_0React/ABI45_0_0RCTLog.h>
#import <ABI45_0_0React/ABI45_0_0RCTUtils.h>

#if !TARGET_OS_TV
@implementation ABI45_0_0RCTConvert (ABI45_0_0EXStatusBar)

ABI45_0_0RCT_ENUM_CONVERTER(UIStatusBarStyle, (@{
  @"default": @(UIStatusBarStyleDefault),
  @"light-content": @(UIStatusBarStyleLightContent),
  @"dark-content": @(UIStatusBarStyleDefault),
}), UIStatusBarStyleDefault, integerValue);

ABI45_0_0RCT_ENUM_CONVERTER(UIStatusBarAnimation, (@{
  @"none": @(UIStatusBarAnimationNone),
  @"fade": @(UIStatusBarAnimationFade),
  @"slide": @(UIStatusBarAnimationSlide),
}), UIStatusBarAnimationNone, integerValue);

@end
#endif

@interface ABI45_0_0EXStatusBarManager ()

@property (nonatomic, strong) NSMutableDictionary *capturedStatusBarProperties;

@end

@implementation ABI45_0_0EXStatusBarManager

+ (NSString *)moduleName { return @"ABI45_0_0RCTStatusBarManager"; }

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"statusBarFrameDidChange",
           @"statusBarFrameWillChange"];
}

#if !TARGET_OS_TV

- (void)setBridge:(ABI45_0_0RCTBridge *)bridge
{
  [super setBridge:bridge];
  _capturedStatusBarProperties = [[self _currentStatusBarProperties] mutableCopy];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_bridgeDidForeground:)
                                               name:@"EXKernelBridgeDidForegroundNotification"
                                             object:self.bridge];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_bridgeDidBackground:)
                                               name:@"EXKernelBridgeDidBackgroundNotification"
                                             object:self.bridge];
}

- (void)dealloc
{
  [self stopObserving];
}

- (void)startObserving
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(applicationDidChangeStatusBarFrame:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
  [nc addObserver:self selector:@selector(applicationWillChangeStatusBarFrame:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
}

- (void)stopObserving
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)emitEvent:(NSString *)eventName forNotification:(NSNotification *)notification
{
  CGRect frame = [notification.userInfo[UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
  NSDictionary *event = @{
    @"frame": @{
      @"x": @(frame.origin.x),
      @"y": @(frame.origin.y),
      @"width": @(frame.size.width),
      @"height": @(frame.size.height),
    },
  };
  [self sendEventWithName:eventName body:event];
}

- (void)applicationDidChangeStatusBarFrame:(NSNotification *)notification
{
  [self emitEvent:@"statusBarFrameDidChange" forNotification:notification];
}

- (void)applicationWillChangeStatusBarFrame:(NSNotification *)notification
{
  [self emitEvent:@"statusBarFrameWillChange" forNotification:notification];
}

ABI45_0_0RCT_EXPORT_METHOD(getHeight:(ABI45_0_0RCTResponseSenderBlock)callback)
{
  callback(@[@{
    @"height": @([UIApplication sharedApplication].statusBarFrame.size.height),
  }]);
}

ABI45_0_0RCT_EXPORT_METHOD(setStyle:(UIStatusBarStyle)statusBarStyle
                  animated:(BOOL)animated)
{
  if ([[self class] _viewControllerBasedStatusBarAppearance]) {
    ABI45_0_0RCTLogError(@"ABI45_0_0RCTStatusBarManager module requires that the \
                UIViewControllerBasedStatusBarAppearance key in the Info.plist is set to NO");
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [ABI45_0_0RCTSharedApplication() setStatusBarStyle:statusBarStyle
                                     animated:animated];
    _capturedStatusBarProperties[@"style"] = @(statusBarStyle);
#pragma clang diagnostic pop
  }
}

ABI45_0_0RCT_EXPORT_METHOD(setHidden:(BOOL)hidden
                  withAnimation:(UIStatusBarAnimation)animation)
{
  if ([[self class] _viewControllerBasedStatusBarAppearance]) {
    ABI45_0_0RCTLogError(@"ABI45_0_0RCTStatusBarManager module requires that the \
                UIViewControllerBasedStatusBarAppearance key in the Info.plist is set to NO");
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [ABI45_0_0RCTSharedApplication() setStatusBarHidden:hidden
                                 withAnimation:animation];
    _capturedStatusBarProperties[@"hidden"] = @(hidden);
#pragma clang diagnostic pop
  }
}

ABI45_0_0RCT_EXPORT_METHOD(setNetworkActivityIndicatorVisible:(BOOL)visible)
{
  ABI45_0_0RCTSharedApplication().networkActivityIndicatorVisible = visible;
  _capturedStatusBarProperties[@"networkActivityIndicatorVisible"] = @(visible);
}

/**
 *  Used by the expo menu to restore status bar state between bridges.
 *  Normally nobody should use this method because it bypasses the JS state used by the StatusBar component.
 */
ABI45_0_0RCT_REMAP_METHOD(_captureProperties,
                 _capturePropertiesWithResolver:(ABI45_0_0RCTPromiseResolveBlock)resolve
                 rejecter:(ABI45_0_0RCTPromiseRejectBlock)reject)
{
  resolve([self _currentStatusBarProperties]);
}

/**
 *  Used by the expo menu to restore status bar state between bridges.
 *  Normally nobody should use this method because it bypasses the JS state used by the StatusBar component.
 */
ABI45_0_0RCT_EXPORT_METHOD(_applyPropertiesAndForget:(NSDictionary *)properties)
{
  [self _applyCapturedProperties:properties];
}

#pragma mark - internal

+ (BOOL)_viewControllerBasedStatusBarAppearance
{
  static BOOL value;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    value = [[[NSBundle mainBundle] objectForInfoDictionaryKey:
              @"UIViewControllerBasedStatusBarAppearance"] ?: @YES boolValue];
  });
  
  return value;
}

- (NSDictionary *)_currentStatusBarProperties
{
  UIApplication *currentApplication = ABI45_0_0RCTSharedApplication();
  return @{
    @"style": @(currentApplication.statusBarStyle),
    @"networkActivityIndicatorVisible": @(currentApplication.isNetworkActivityIndicatorVisible),
    @"hidden": @(currentApplication.isStatusBarHidden),
  };
}

- (void)_applyCapturedProperties:(NSDictionary *)properties
{
  UIApplication *currentApplication = ABI45_0_0RCTSharedApplication();
  if (![[self class] _viewControllerBasedStatusBarAppearance]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [currentApplication setStatusBarStyle:(UIStatusBarStyle)[properties[@"style"] integerValue] animated:NO];
    [currentApplication setStatusBarHidden:[properties[@"hidden"] boolValue] withAnimation:UIStatusBarAnimationNone];
#pragma clang diagnostic pop
  }
  currentApplication.networkActivityIndicatorVisible = [properties[@"networkActivityIndicatorVisible"] boolValue];
}

- (void)_bridgeDidForeground:(__unused NSNotification *)notif
{
  [self _applyCapturedProperties:_capturedStatusBarProperties];
}

- (void)_bridgeDidBackground:(__unused NSNotification *)notif
{
  _capturedStatusBarProperties = [[self _currentStatusBarProperties] mutableCopy];
}

#endif //TARGET_OS_TV

@end
