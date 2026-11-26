// Регион контента: подменяем страну, которую видит приложение
// (локаль, оператор и параметры запросов). Меняет ленту и рекомендации.
// Блокировку на уровне провайдера (по IP) это НЕ обходит — нужен VPN.

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import "MTPrefs.h"

static NSString *MTRegion(void) { return MTOn(@"reg") ? MTPrefs.region : nil; }

%hook NSLocale
- (id)objectForKey:(NSLocaleKey)key {
    NSString *r = MTRegion();
    if (r && [key isEqualToString:NSLocaleCountryCode]) return r;
    return %orig;
}
- (NSString *)countryCode { return MTRegion() ?: %orig; }
- (NSString *)regionCode  { return MTRegion() ?: %orig; }
%end

%hook CTCarrier
- (NSString *)isoCountryCode { NSString *r = MTRegion(); return r ? r.lowercaseString : %orig; }
%end

// Параметры региона в query-строке запросов.
static NSArray<NSString *> *MTRegionParams(void) {
    return @[ @"region", @"sys_region", @"carrier_region", @"op_region", @"current_region", @"residence" ];
}

static NSURL *MTRewrite(NSURL *url) {
    NSString *r = MTRegion();
    if (!r || !url.query) return url;
    NSURLComponents *c = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    BOOL changed = NO;
    NSMutableArray *items = [NSMutableArray array];
    for (NSURLQueryItem *it in c.queryItems) {
        if ([MTRegionParams() containsObject:it.name]) { [items addObject:[NSURLQueryItem queryItemWithName:it.name value:r]]; changed = YES; }
        else [items addObject:it];
    }
    if (!changed) return url;
    c.queryItems = items;
    return c.URL ?: url;
}

%hook NSMutableURLRequest
- (void)setURL:(NSURL *)url { %orig(MTRewrite(url)); }
%end

%hook NSURLRequest
+ (instancetype)requestWithURL:(NSURL *)url { return %orig(MTRewrite(url)); }
- (instancetype)initWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)p timeoutInterval:(NSTimeInterval)t {
    return %orig(MTRewrite(url), p, t);
}
%end
