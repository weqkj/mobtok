#import <Foundation/Foundation.h>

// Сохранение медиа в «Фото». URL без водяного знака берёт адаптер (MTAdapter),
// сам загрузчик о TikTok ничего не знает.
@interface MTDownloader : NSObject
+ (void)saveVideoAt:(NSURL *)url completion:(void (^)(NSError *err))done;
+ (void)saveImagesAt:(NSArray<NSURL *> *)urls completion:(void (^)(NSError *err))done;
@end
