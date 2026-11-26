// Адаптер к внутренностям TikTok: единственное место, которое зависит от версии.
//
// Имена классов и селекторов ниже — ЗАГЛУШКИ. Их нужно взять из class-dump
// той версии TikTok, под которую собирается мод (см. README → «Адаптер»).
// Пока имя не найдено, %hook просто не срабатывает и TikTok работает как обычно.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MTPrefs.h"
#import "MTDownloader.h"
#import "MTSettings.h"

#define MT_VIDEO_MODEL      "TODO_VideoModel"        // модель ролика (URL-ы воспроизведения)
#define MT_SHARE_PANEL      "TODO_SharePanel"        // панель «Поделиться»
#define MT_SETTINGS_LIST    "TODO_SettingsList"      // экран настроек TikTok
#define MT_FEED_AD_FILTER   "TODO_FeedDataSource"    // источник данных ленты

%group Adapter

// Пункт «mobtok» в настройках TikTok.
%hook MTSettingsListHook
- (void)viewDidLoad {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    UIBarButtonItem *b = [[UIBarButtonItem alloc] initWithTitle:@"mobtok" style:UIBarButtonItemStylePlain
                                                         target:MTSettings.class action:@selector(presentFromTop)];
    vc.navigationItem.rightBarButtonItem = b;
}
%end

%end

// Запасной вход в меню, работающий всегда: встряхнуть телефон.
%hook UIWindow
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    %orig;
    if (motion == UIEventSubtypeMotionShake) [MTSettings presentFromTop];
}
%end

%ctor {
    Class settings = objc_getClass(MT_SETTINGS_LIST);
    if (settings) %init(Adapter, MTSettingsListHook = settings);
    %init;
}
