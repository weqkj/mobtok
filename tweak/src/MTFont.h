#import <UIKit/UIKit.h>

// Google Sans (кириллица) и Google Sans Flex Wide Black (широкий, латиница) — вшиты в dylib.
@interface MTFont : NSObject
+ (UIFont *)size:(CGFloat)size weight:(UIFontWeight)weight;   // Google Sans, Dynamic Type
+ (UIFont *)display:(CGFloat)size;                            // широкий жирный, для «mobtok»
@end
