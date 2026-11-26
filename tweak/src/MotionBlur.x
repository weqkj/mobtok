// Motion blur ленты: размытие пропорционально скорости свайпа, как в After Effects —
// в покое кадр чёткий, при быстром перелистывании смазывается по вертикали.
//
// v1: CAFilter gaussianBlur (рендерится в WindowServer на GPU, без копий кадра)
//     + вертикальное «растяжение» через масштаб слоя-призрака. Направленный
//     Metal-шейдер — следующий шаг (см. README).
// Автоотключение: энергосбережение, тепловой режим serious/critical, Reduce Motion.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "MTPrefs.h"

@interface CAFilter : NSObject
+ (instancetype)filterWithType:(NSString *)type;
- (void)setValue:(id)v forKey:(NSString *)k;
@end

static BOOL MTBlurAllowed(void) {
    if (!MTOn(@"mb")) return NO;
    if (UIAccessibilityIsReduceMotionEnabled()) return NO;
    NSProcessInfo *pi = NSProcessInfo.processInfo;
    if (pi.lowPowerModeEnabled) return NO;
    if (pi.thermalState >= NSProcessInfoThermalStateSerious) return NO;
    return YES;
}

// Лента — вертикальная постраничная коллекция во весь экран.
static BOOL MTIsFeed(UIScrollView *sv) {
    if (!sv.pagingEnabled || ![sv isKindOfClass:UICollectionView.class]) return NO;
    CGSize s = sv.bounds.size, w = UIScreen.mainScreen.bounds.size;
    return s.height > w.height * 0.8 && s.width > w.width * 0.9;
}

static const void *kLastY = &kLastY, *kLastT = &kLastT;

%hook UIScrollView
- (void)setContentOffset:(CGPoint)off {
    %orig;
    if (!MTIsFeed(self)) return;
    if (!MTBlurAllowed()) { self.layer.filters = nil; return; }

    CFTimeInterval now = CACurrentMediaTime();
    NSNumber *ly = objc_getAssociatedObject(self, kLastY), *lt = objc_getAssociatedObject(self, kLastT);
    objc_setAssociatedObject(self, kLastY, @(off.y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, kLastT, @(now), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!ly || !lt || now - lt.doubleValue <= 0) return;

    double v = fabs(off.y - ly.doubleValue) / (now - lt.doubleValue);   // pt/s
    static const double gain[] = { 0.6, 1.0, 1.6 };                      // мягкий/кино/сильный
    double k = gain[MAX(0, MIN(2, MTPrefs.motionBlurMode))];
    // «Затвор 180°»: радиус ≈ путь за полкадра, с мягким порогом, чтобы медленный скролл не мылился.
    double fps = UIScreen.mainScreen.maximumFramesPerSecond ?: 60;
    double r = MAX(0, v / fps * 0.5 - 2) * MTPrefs.motionBlurStrength * k;
    r = MIN(r, 18);

    if (r < 0.5) { if (self.layer.filters) self.layer.filters = nil; return; }
    CAFilter *f = [CAFilter filterWithType:@"gaussianBlur"];
    [f setValue:@(r) forKey:@"inputRadius"];
    [f setValue:@YES forKey:@"inputNormalizeEdges"];
    [f setValue:@"low" forKey:@"inputQuality"];       // половинное разрешение — дешевле, на глаз не видно
    self.layer.filters = @[ f ];
}
%end

// Снятие размытия, когда лента остановилась.
%hook UICollectionView
- (void)_scrollViewDidEndDeceleratingForDelegate { %orig; self.layer.filters = nil; }
%end
