#import <UIKit/UIKit.h>

// Фон меню: фигуры M3 Expressive с физикой и motion blur, поверх — стекло.
// -kickFrom: толкает фигуры от точки касания.
@interface MTShapeField : UIView
- (void)kickFrom:(CGPoint)point power:(CGFloat)power;
@end
