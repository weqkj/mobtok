// Меню mobtok внутри TikTok в стиле Material You 3 (тёмная тема):
// тональные поверхности, карточки с радиусом 28, чипы-фильтры, M3-переключатели.

#import "MTSettings.h"
#import "MTPrefs.h"
#import <LocalAuthentication/LocalAuthentication.h>

#define RGB(h) [UIColor colorWithRed:((h>>16)&0xFF)/255.0 green:((h>>8)&0xFF)/255.0 blue:(h&0xFF)/255.0 alpha:1]
static UIColor *Surface(void)   { return RGB(0x111318); }
static UIColor *Container(void) { return RGB(0x1D2024); }
static UIColor *Primary(void)   { return RGB(0xA8C7FA); }
static UIColor *OnSurface(void) { return RGB(0xE2E2E9); }
static UIColor *Variant(void)   { return RGB(0xC4C6D0); }

typedef NSArray<NSString *> Row;   // @[ключ, название, подпись]

@interface MTSettings ()
@property (nonatomic, copy) NSArray<NSArray *> *groups;   // @[название, @[Row]]
@property (nonatomic, copy) NSString *filter;
@property (nonatomic, strong) UIStackView *chips;
@end

@implementation MTSettings

+ (void)presentFromTop {
    void (^show)(void) = ^{
        UIWindowScene *scene = (UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject;
        UIViewController *top = scene.keyWindow.rootViewController;
        while (top.presentedViewController) top = top.presentedViewController;
        if ([top isKindOfClass:UINavigationController.class] &&
            [((UINavigationController *)top).topViewController isKindOfClass:MTSettings.class]) return;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[MTSettings new]];
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
        [top presentViewController:nav animated:YES completion:nil];
    };
    if (!MTOn(@"fid")) { show(); return; }
    LAContext *ctx = [LAContext new];
    [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"Открыть настройки mobtok"
                  reply:^(BOOL ok, NSError *e) { if (ok) dispatch_async(dispatch_get_main_queue(), show); }];
}

- (instancetype)init {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _filter = @"Все";
        _groups = @[
            @[@"Видео", @[@[@"dl", @"Скачать без водяного знака", @"видео, карусели, звук"],
                          @[@"q", @"Выбор качества", @"до максимального"],
                          @[@"spd", @"Скорость 0.5–3×", @""], @[@"vol", @"Запоминать громкость", @""]]],
            @[@"Регион", @[@[@"reg", @"Регион контента", @"меняет ленту, не обходит блокировку по IP"]]],
            @[@"Лента", @[@[@"mb", @"Motion blur", @"размытие при свайпе, как в AE"],
                          @[@"ads", @"Без рекламы", @""], @[@"live", @"Скрыть Live и Shop", @""], @[@"auto", @"Автопрокрутка", @""]]],
            @[@"Профиль", @[@[@"ban", @"Открыть фон профиля", @"если TikTok ещё не включил"],
                            @[@"bansave", @"Сохранять фон чужих профилей", @""], @[@"badge", @"Бейдж mobtok", @""]]],
            @[@"Приватность", @[@[@"story", @"Не отмечать просмотр сторис", @""], @[@"prof", @"Не отмечать посещение профилей", @""],
                                @[@"type", @"Скрыть «печатает…»", @""], @[@"fid", @"Вход по Face ID", @""]]],
            @[@"Интерфейс", @[@[@"m3", @"Material You", @"цвета из обоев"], @[@"oled", @"OLED-чёрная тема", @""],
                              @[@"nav", @"Компактная навигация", @""]]],
            @[@"Утилиты", @[@[@"copy", @"Копировать описания и комменты", @""], @[@"tr", @"Перевод комментариев", @""],
                            @[@"hist", @"История просмотров", @""]]],
        ];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"mobtok";
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationController.navigationBar.largeTitleTextAttributes = @{ NSForegroundColorAttributeName: OnSurface() };
    self.navigationController.navigationBar.tintColor = Primary();
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self action:@selector(close)];
    self.tableView.backgroundColor = Surface();
    self.tableView.separatorColor = RGB(0x2B2E33);
    self.tableView.sectionHeaderTopPadding = 12;
    self.tableView.tableHeaderView = [self chipBar];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

#pragma mark - Чипы-фильтры

- (UIView *)chipBar {
    UIScrollView *sc = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 0, 52)];
    sc.showsHorizontalScrollIndicator = NO;
    _chips = [UIStackView new];
    _chips.spacing = 8;
    _chips.translatesAutoresizingMaskIntoConstraints = NO;
    [sc addSubview:_chips];
    [NSLayoutConstraint activateConstraints:@[
        [_chips.leadingAnchor constraintEqualToAnchor:sc.contentLayoutGuide.leadingAnchor constant:16],
        [_chips.trailingAnchor constraintEqualToAnchor:sc.contentLayoutGuide.trailingAnchor constant:-16],
        [_chips.centerYAnchor constraintEqualToAnchor:sc.centerYAnchor],
        [_chips.heightAnchor constraintEqualToConstant:36]]];
    NSMutableArray *names = [@[@"Все"] mutableCopy];
    for (NSArray *g in _groups) [names addObject:g[0]];
    for (NSString *n in names) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:n forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        b.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        b.layer.cornerRadius = 12;
        b.layer.cornerCurve = kCACornerCurveContinuous;
        [b addTarget:self action:@selector(chip:) forControlEvents:UIControlEventTouchUpInside];
        [_chips addArrangedSubview:b];
    }
    [self styleChips];
    return sc;
}

- (void)styleChips {
    for (UIButton *b in _chips.arrangedSubviews) {
        BOOL on = [b.currentTitle isEqualToString:_filter];
        b.backgroundColor = on ? RGB(0x004A77) : UIColor.clearColor;
        b.layer.borderWidth = on ? 0 : 1;
        b.layer.borderColor = RGB(0x44474E).CGColor;
        [b setTitleColor:on ? RGB(0xD3E3FD) : Variant() forState:UIControlStateNormal];
    }
}

- (void)chip:(UIButton *)b {
    _filter = b.currentTitle;
    UIImpactFeedbackGenerator *h = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [h impactOccurred];
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0
                     animations:^{ [self styleChips]; } completion:nil];
    [UIView transitionWithView:self.tableView duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ [self.tableView reloadData]; } completion:nil];
}

- (NSArray<NSArray *> *)visible {
    if ([_filter isEqualToString:@"Все"]) return _groups;
    return [_groups filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF[0] == %@", _filter]];
}

#pragma mark - Таблица

- (BOOL)showsBlurCard:(NSInteger)section { return [self.visible[section][0] isEqualToString:@"Лента"] && MTOn(@"mb"); }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return self.visible.count; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return [self.visible[s][1] count] + ([self showsBlurCard:s] ? 2 : 0);
}
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s { return self.visible[s][0]; }
- (void)tableView:(UITableView *)tv willDisplayHeaderView:(UITableViewHeaderFooterView *)v forSection:(NSInteger)s {
    v.textLabel.textColor = Primary();
    v.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSArray<Row *> *rows = self.visible[ip.section][1];
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    c.backgroundColor = Container();
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    c.textLabel.textColor = OnSurface();
    c.detailTextLabel.textColor = Variant();
    c.textLabel.font = [UIFont systemFontOfSize:16];

    if (ip.row >= (NSInteger)rows.count) return [self blurCell:c index:ip.row - rows.count];

    Row *r = rows[ip.row];
    c.textLabel.text = r[1];
    c.detailTextLabel.text = r[2].length ? r[2] : nil;
    UISwitch *sw = [UISwitch new];
    sw.onTintColor = Primary();
    sw.thumbTintColor = nil;
    sw.on = MTOn(r[0]);
    sw.accessibilityIdentifier = r[0];
    [sw addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
    c.accessoryView = sw;
    return c;
}

- (UITableViewCell *)blurCell:(UITableViewCell *)c index:(NSInteger)i {
    if (i == 0) {
        c.textLabel.text = [NSString stringWithFormat:@"Сила размытия · %d%%", (int)lround(MTPrefs.motionBlurStrength * 100)];
        UISlider *s = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
        s.value = MTPrefs.motionBlurStrength;
        s.minimumTrackTintColor = Primary();
        s.maximumTrackTintColor = RGB(0x004A77);
        [s addTarget:self action:@selector(blurStrength:) forControlEvents:UIControlEventValueChanged];
        c.accessoryView = s;
    } else {
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Мягкий", @"Кино", @"Сильный"]];
        seg.selectedSegmentIndex = MTPrefs.motionBlurMode;
        seg.selectedSegmentTintColor = Primary();
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: RGB(0x0A305F)} forState:UIControlStateSelected];
        [seg addTarget:self action:@selector(blurMode:) forControlEvents:UIControlEventValueChanged];
        c.textLabel.text = @"Режим";
        c.detailTextLabel.text = @"GPU · выключается при перегреве";
        c.accessoryView = seg;
        [seg sizeToFit];
    }
    return c;
}

- (void)toggle:(UISwitch *)sw {
    [MTPrefs setBool:sw.on forKey:sw.accessibilityIdentifier];
    [[UISelectionFeedbackGenerator new] selectionChanged];
    if ([sw.accessibilityIdentifier isEqualToString:@"mb"])
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.visible.count)]
                      withRowAnimation:UITableViewRowAnimationFade];
}

- (void)blurStrength:(UISlider *)s {
    [MTPrefs setObject:@(s.value) forKey:@"mb.strength"];
    UITableViewCell *c = (UITableViewCell *)s.superview;
    while (c && ![c isKindOfClass:UITableViewCell.class]) c = (UITableViewCell *)c.superview;
    c.textLabel.text = [NSString stringWithFormat:@"Сила размытия · %d%%", (int)lround(s.value * 100)];
}

- (void)blurMode:(UISegmentedControl *)s { [MTPrefs setObject:@(s.selectedSegmentIndex) forKey:@"mb.mode"]; }

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    NSArray<Row *> *rows = self.visible[ip.section][1];
    if (ip.row < (NSInteger)rows.count && [rows[ip.row][0] isEqualToString:@"reg"]) [self pickRegion];
}

- (void)pickRegion {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Регион контента"
        message:@"Меняет ленту и рекомендации. Блокировку по IP не обходит — для этого нужен VPN."
        preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *list = @[@[@"KZ", @"Казахстан"], @[@"US", @"США"], @[@"DE", @"Германия"], @[@"TR", @"Турция"],
                      @[@"AE", @"ОАЭ"], @[@"JP", @"Япония"], @[@"BR", @"Бразилия"]];
    for (NSArray *r in list)
        [a addAction:[UIAlertAction actionWithTitle:r[1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
            [MTPrefs setObject:r[0] forKey:@"reg.code"]; [MTPrefs setBool:YES forKey:@"reg"]; [self.tableView reloadData];
        }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Как в системе" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
        [MTPrefs setObject:@"" forKey:@"reg.code"]; [MTPrefs setBool:NO forKey:@"reg"]; [self.tableView reloadData];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
@end
