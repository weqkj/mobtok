#import "MTShapeField.h"

typedef struct { CGFloat x, y, vx, vy, a, w, size; } MTBody;
static const int kN = 5, kGhosts = 5;

@implementation MTShapeField {
    MTBody _b[kN];
    CAShapeLayer *_layers[kN][kGhosts + 1];
    CADisplayLink *_link;
    CFTimeInterval _last;
    UIVisualEffectView *_glass;
}

static UIBezierPath *ShapePath(int kind, CGFloat size) {
    CGFloat r = size / 2;
    if (kind == 2) return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-r, -r * 0.55, size, r * 1.1) cornerRadius:r * 0.55];
    if (kind == 4) return [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-r, -r, size, size)];
    double lobes = kind == 0 ? 9 : kind == 1 ? 4 : 6, depth = kind == 0 ? 0.07 : kind == 1 ? 0.16 : 0.12;
    UIBezierPath *p = [UIBezierPath bezierPath];
    for (int i = 0; i <= 120; i++) {
        double t = i / 120.0 * 2 * M_PI, rr = r * (1 - depth + depth * cos(lobes * t));
        CGPoint pt = CGPointMake(rr * cos(t), rr * sin(t));
        i ? [p addLineToPoint:pt] : [p moveToPoint:pt];
    }
    [p closePath];
    return p;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.backgroundColor = [UIColor colorWithRed:0x19/255.0 green:0x11/255.0 blue:0x13/255.0 alpha:1];
    self.userInteractionEnabled = NO;
    UIColor *colors[kN] = {
        [UIColor colorWithRed:0x8C/255.0 green:0x2F/255.0 blue:0x55/255.0 alpha:1],
        [UIColor colorWithRed:0x6E/255.0 green:0x3B/255.0 blue:0x8F/255.0 alpha:1],
        [UIColor colorWithRed:0x8A/255.0 green:0x4A/255.0 blue:0x2B/255.0 alpha:1],
        [UIColor colorWithRed:0x5E/255.0 green:0x11/255.0 blue:0x33/255.0 alpha:1],
        [UIColor colorWithRed:0x7D/255.0 green:0x29/255.0 blue:0x48/255.0 alpha:1] };
    MTBody init[kN] = {
        {0.12, 0.10, 0.012, 0.008, 0, 0.10, 230}, {0.92, 0.30, -0.010, 0.010, 1, -0.08, 190},
        {0.18, 0.70, 0.008, -0.010, 0.6, 0.06, 170}, {0.85, 0.88, -0.008, -0.006, 2, 0.05, 260},
        {0.55, 0.50, 0.010, 0.012, 0, 0, 120} };
    for (int i = 0; i < kN; i++) {
        _b[i] = init[i];
        CGPathRef path = ShapePath(i, _b[i].size).CGPath;
        for (int g = kGhosts; g >= 0; g--) {          // призраки рисуются под основной фигурой
            CAShapeLayer *l = [CAShapeLayer layer];
            l.path = path;
            l.fillColor = colors[i].CGColor;
            l.opacity = g == 0 ? 0.85 : 0;
            [self.layer addSublayer:l];
            _layers[i][g] = l;
        }
    }
    // Стекло поверх фигур: размывает их в мягкие пятна
    _glass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    _glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _glass.frame = self.bounds;
    [self addSubview:_glass];
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [_link invalidate]; _link = nil;
    if (!self.window || UIAccessibilityIsReduceMotionEnabled()) { [self layoutBodies]; return; }
    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    if (@available(iOS 15.0, *)) _link.preferredFrameRateRange = CAFrameRateRangeMake(30, 120, 120);
    _last = 0;
    [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)kickFrom:(CGPoint)p power:(CGFloat)power {
    CGSize s = self.bounds.size;
    if (s.width < 1) return;
    CGFloat ox = p.x / s.width, oy = p.y / s.height;
    for (int i = 0; i < kN; i++) {
        CGFloat dx = _b[i].x - ox, dy = _b[i].y - oy, len = MAX(0.15, hypot(dx, dy));
        _b[i].vx += dx / len * power / len * 0.35;
        _b[i].vy += dy / len * power / len * 0.35;
        _b[i].w += ((double)arc4random_uniform(2400) / 1000.0 - 1.2);
    }
}

- (void)tick:(CADisplayLink *)link {
    CFTimeInterval now = link.timestamp;
    CGFloat dt = _last ? MIN(0.05, now - _last) : 0;
    _last = now;
    CGFloat drag = pow(0.18, dt);
    for (int i = 0; i < kN; i++) {
        MTBody *b = &_b[i];
        b->x += b->vx * dt; b->y += b->vy * dt; b->a += b->w * dt;
        if (b->x < -0.05 || b->x > 1.05) { b->vx *= -0.7; b->x = MIN(MAX(b->x, -0.05), 1.05); }
        if (b->y < -0.05 || b->y > 1.05) { b->vy *= -0.7; b->y = MIN(MAX(b->y, -0.05), 1.05); }
        if (hypot(b->vx, b->vy) > 0.015) { b->vx *= drag; b->vy *= drag; }
        b->w = b->w * drag + (b->w > 0 ? 0.05 : -0.05) * (1 - drag);
    }
    [self layoutBodies];
}

- (void)layoutBodies {
    CGSize s = self.bounds.size;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (int i = 0; i < kN; i++) {
        MTBody b = _b[i];
        CGFloat speed = hypot(b.vx, b.vy);
        int ghosts = speed > 0.04 ? MIN(kGhosts, (int)(speed * 25)) : 0;   // motion blur только на скорости
        for (int g = 0; g <= kGhosts; g++) {
            CAShapeLayer *l = _layers[i][g];
            CGFloat k = (CGFloat)g / kGhosts;
            l.position = CGPointMake((b.x - b.vx * k * 0.12) * s.width, (b.y - b.vy * k * 0.12) * s.height);
            l.affineTransform = CGAffineTransformMakeRotation(b.a - b.w * k * 0.05);
            l.opacity = g == 0 ? 0.85 : (g <= ghosts ? 0.85 * (1 - k) * 0.35 : 0);
        }
    }
    [CATransaction commit];
}

- (void)removeFromSuperview { [_link invalidate]; _link = nil; [super removeFromSuperview]; }
@end
