#import "MTFont.h"
#import <CoreText/CoreText.h>
#import "MTFontData.h"

static void Register(const unsigned char *bytes, size_t len) {
    CFDataRef data = CFDataCreate(NULL, bytes, (CFIndex)len);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    if (font) { CTFontManagerRegisterGraphicsFont(font, NULL); CGFontRelease(font); }
    CGDataProviderRelease(provider);
    CFRelease(data);
}

static void RegisterOnce(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Register(GoogleSans_Regular, GoogleSans_Regular_len);
        Register(GoogleSans_Medium, GoogleSans_Medium_len);
        Register(GoogleSans_Bold, GoogleSans_Bold_len);
        Register(GoogleSansFlex_WideBlack, GoogleSansFlex_WideBlack_len);
    });
}

@implementation MTFont
+ (UIFont *)size:(CGFloat)size weight:(UIFontWeight)weight {
    RegisterOnce();
    NSString *name = weight >= UIFontWeightBold ? @"mobtokSans-Bold"
                   : weight >= UIFontWeightMedium ? @"mobtokSans-Medium" : @"mobtokSans-Regular";
    UIFont *f = [UIFont fontWithName:name size:size] ?: [UIFont systemFontOfSize:size weight:weight];
    return [[UIFontMetrics defaultMetrics] scaledFontForFont:f];
}
+ (UIFont *)display:(CGFloat)size {
    RegisterOnce();
    return [UIFont fontWithName:@"mobtokDisplay-WideBlack" size:size] ?: [UIFont systemFontOfSize:size weight:UIFontWeightBlack];
}
@end
