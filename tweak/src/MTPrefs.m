#import "MTPrefs.h"

static NSUserDefaults *D(void) {
    static NSUserDefaults *d;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        d = [[NSUserDefaults alloc] initWithSuiteName:@"dev.mobtok"];
        [d registerDefaults:@{ @"dl": @YES, @"q": @YES, @"spd": @YES, @"vol": @YES,
                               @"mb": @YES, @"mb.strength": @0.45, @"mb.mode": @1,
                               @"ads": @YES, @"live": @NO, @"auto": @NO,
                               @"ban": @YES, @"bansave": @YES, @"badge": @YES,
                               @"story": @NO, @"prof": @NO, @"type": @NO, @"fid": @NO,
                               @"m3": @YES, @"oled": @NO, @"nav": @NO,
                               @"copy": @YES, @"tr": @NO, @"hist": @YES }];
    });
    return d;
}

@implementation MTPrefs
+ (BOOL)bool:(NSString *)k { return [D() boolForKey:k]; }
+ (void)setBool:(BOOL)v forKey:(NSString *)k { [D() setBool:v forKey:k]; }
+ (double)motionBlurStrength { return [D() doubleForKey:@"mb.strength"]; }
+ (NSInteger)motionBlurMode { return [D() integerForKey:@"mb.mode"]; }
+ (NSString *)region { NSString *r = [D() stringForKey:@"reg.code"]; return r.length == 2 ? r : nil; }
+ (void)setObject:(id)o forKey:(NSString *)k { [D() setObject:o forKey:k]; }
@end
