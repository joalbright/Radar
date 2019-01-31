//
//  RadarView.m
//  Radar
//
//  Created by Jo Albright on 1/25/19.
//  Copyright © 2019 Roadie, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "RadarView.h"

@interface Ping: NSObject

@property (nonatomic) CGPoint point;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat alpha;

@end

@implementation Ping

- (instancetype)initWithPoint:(CGPoint)point
{
    self = [super init];
    if (self) {
        self.point = point;
        self.radius = 0;
    }
    return self;
}

- (void)setRadius:(CGFloat)radius {

    _radius = radius;
    _alpha = (40.0 - radius) / 40.0;

}

@end

@interface Pixel: NSObject

@property (nonatomic) CGPoint point;
@property (nonatomic) CGFloat alpha;

@end

@implementation Pixel

- (instancetype)initWithPoint:(CGPoint)point
{
    self = [super init];
    if (self) {
        self.point = point;
        self.alpha = 1;
    }
    return self;
}

@end

@interface RadarView ()

@property (nonatomic) CGFloat rotation;
@property (nonatomic) NSMutableArray *pixels;
@property (nonatomic) NSMutableArray *pings;

@end

@implementation RadarView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {

    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];

        _pixels = [@[] mutableCopy];
        _pings = [@[] mutableCopy];

    }
    return self;

}

- (void)startAnimation { [super startAnimation]; }

- (void)stopAnimation { [super stopAnimation]; }

- (NSColor *)colorWithAlpha:(CGFloat)alpha {

    return [NSColor colorWithWhite:1 alpha:alpha];
//    return [NSColor colorWithRed:0 green:0.7 blue:0.2 alpha:alpha];

}

- (CGPoint)pointAtRadius:(CGFloat)radius atRotation:(CGFloat)rotation {

    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    CGFloat radians = (M_PI * rotation) / 180;
    return CGPointMake(center.x + radius * cos(radians), center.y + radius * sin(radians));

}

- (CGPoint)pointAtRadius:(CGFloat)radius {

    return [self pointAtRadius:radius atRotation:self.rotation];

}

- (CGFloat)radius {

    return sqrt(pow(self.frame.size.height, 2) + pow(self.frame.size.width, 2));

}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];

    CGContextRef context = [NSGraphicsContext currentContext].CGContext;

    CGContextSetLineWidth(context, 2);
    CGContextSetLineCap(context, kCGLineCapRound);

    /// Radar Line

    CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);

    for (CGFloat i = 0; i < 30; i++) {

        [[self colorWithAlpha:1 / ((i / 2) + 1)] set];

        CGPoint end = [self pointAtRadius:self.radius atRotation:self.rotation + i * 0.1];

        CGContextMoveToPoint(context, center.x, center.y);
        CGContextAddLineToPoint(context, end.x, end.y);
        CGContextStrokePath(context);

    }

    /// Pixels

    for (Pixel *pixel in self.pixels) {

        [[self colorWithAlpha:pixel.alpha] set];

        CGContextMoveToPoint(context, pixel.point.x, pixel.point.y);
        CGContextAddLineToPoint(context, pixel.point.x, pixel.point.y);
        CGContextStrokePath(context);

    }

    /// Pings

    for (Ping *ping in self.pings) {

        [[self colorWithAlpha:ping.alpha] set];

        CGContextSetLineWidth(context, 4);

        CGContextMoveToPoint(context, ping.point.x, ping.point.y);
        CGContextAddLineToPoint(context, ping.point.x, ping.point.y);
        CGContextStrokePath(context);

        CGContextSetLineWidth(context, 2);

        CGContextStrokeEllipseInRect(context, CGRectMake(ping.point.x - ping.radius, ping.point.y - ping.radius, ping.radius * 2, ping.radius * 2));

    }

    /// Center

    CGContextSetLineWidth(context, 2);

    CGRect core = CGRectMake(center.x - 20, center.y - 20, 40, 40);

    [[NSColor blackColor] set];

    CGContextFillEllipseInRect(context, core);

    [[self colorWithAlpha:1] set];

    CGContextStrokeEllipseInRect(context, core);

    CGContextStrokeEllipseInRect(context, CGRectInset(core, 4, 4));

    [[NSColor blackColor] set];

    CGPoint remove = [self pointAtRadius:16 atRotation:self.rotation];

    CGContextMoveToPoint(context, remove.x, remove.y);
    CGContextAddLineToPoint(context, remove.x, remove.y);
    CGContextStrokePath(context);

    [[self colorWithAlpha:1] set];

    CGContextFillEllipseInRect(context, CGRectInset(core, 8, 8));

    [[NSColor blackColor] set];

    CGPoint notch = [self pointAtRadius:12 atRotation:self.rotation];

    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddLineToPoint(context, notch.x, notch.y);
    CGContextStrokePath(context);

}

- (void)animateOneFrame {

    self.rotation -= 1;

    int min = arc4random_uniform(200);
    int max = self.radius;

    for (int i = min; i < max; i++) {

        if (arc4random_uniform(max) % (max - i) / 50 == 0) {

            [self.pixels addObject:[[Pixel alloc] initWithPoint:[self pointAtRadius:i]]];

        }

    }

    for (Pixel *pixel in self.pixels.copy) {

        if (pixel.alpha < 0.1) {

            [self.pixels removeObject:pixel];

        } else {

            pixel.alpha -= (arc4random_uniform(60) + 1) / 1000.0;

        }

    }

    int rotation = self.rotation;

    if (rotation % (arc4random_uniform(4) + 1) == 0) {

        int radius = arc4random_uniform(self.radius - 200) + 100;

        [self.pings addObject:[[Ping alloc] initWithPoint:[self pointAtRadius:radius]]];

    }

    for (Ping *ping in self.pings.copy) {

        if (ping.alpha < 0.02) {

            [self.pings removeObject:ping];

        } else {

            ping.radius += 0.5;

        }

    }

    [self setNeedsDisplay:YES];
    return;

}

- (BOOL)hasConfigureSheet { return NO; }

- (NSWindow*)configureSheet { return nil; }

@end
