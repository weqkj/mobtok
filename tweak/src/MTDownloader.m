#import "MTDownloader.h"
#import <Photos/Photos.h>

@implementation MTDownloader

+ (void)fetch:(NSURL *)url ext:(NSString *)ext done:(void (^)(NSURL *file, NSError *err))done {
    NSURLSessionDownloadTask *t = [NSURLSession.sharedSession downloadTaskWithURL:url
        completionHandler:^(NSURL *loc, NSURLResponse *r, NSError *e) {
        if (e || !loc) { done(nil, e); return; }
        NSURL *dst = [[NSURL fileURLWithPath:NSTemporaryDirectory()]
                      URLByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:ext]];
        NSError *mv; [NSFileManager.defaultManager moveItemAtURL:loc toURL:dst error:&mv];
        done(mv ? nil : dst, mv);
    }];
    [t resume];
}

+ (void)write:(void (^)(void))changes cleanup:(NSArray<NSURL *> *)files done:(void (^)(NSError *))done {
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly handler:^(PHAuthorizationStatus s) {
        if (s != PHAuthorizationStatusAuthorized && s != PHAuthorizationStatusLimited) {
            dispatch_async(dispatch_get_main_queue(), ^{ done([NSError errorWithDomain:@"mobtok" code:1
                userInfo:@{NSLocalizedDescriptionKey: @"Нет доступа к «Фото»"}]); });
            return;
        }
        [PHPhotoLibrary.sharedPhotoLibrary performChanges:changes completionHandler:^(BOOL ok, NSError *e) {
            for (NSURL *f in files) [NSFileManager.defaultManager removeItemAtURL:f error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ done(e); });
        }];
    }];
}

+ (void)saveVideoAt:(NSURL *)url completion:(void (^)(NSError *))done {
    [self fetch:url ext:@"mp4" done:^(NSURL *file, NSError *err) {
        if (!file) { dispatch_async(dispatch_get_main_queue(), ^{ done(err); }); return; }
        [self write:^{ [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:file]; }
            cleanup:@[file] done:done];
    }];
}

+ (void)saveImagesAt:(NSArray<NSURL *> *)urls completion:(void (^)(NSError *))done {
    dispatch_group_t g = dispatch_group_create();
    NSMutableArray<NSURL *> *files = [NSMutableArray array];
    for (NSURL *u in urls) {
        dispatch_group_enter(g);
        [self fetch:u ext:@"jpg" done:^(NSURL *f, NSError *e) {
            if (f) @synchronized (files) { [files addObject:f]; }
            dispatch_group_leave(g);
        }];
    }
    dispatch_group_notify(g, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self write:^{
            for (NSURL *f in files) [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:f];
        } cleanup:files done:done];
    });
}
@end
