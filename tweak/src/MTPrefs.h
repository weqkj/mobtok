#import <Foundation/Foundation.h>

// Все настройки мода. Ключи — те же, что в меню.
#define MTOn(key) [MTPrefs bool:key]

@interface MTPrefs : NSObject
+ (BOOL)bool:(NSString *)key;
+ (void)setBool:(BOOL)v forKey:(NSString *)key;
+ (double)motionBlurStrength;          // 0…1
+ (NSInteger)motionBlurMode;           // 0 мягкий, 1 кино, 2 сильный
+ (NSString *)region;                  // ISO-код, напр. "KZ"; nil — не подменять
+ (void)setObject:(id)obj forKey:(NSString *)key;
@end
