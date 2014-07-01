//
//  DropitViewController.m
//  Dropit
//
//  Created by Ivan Sadikov on 30/06/14.
//  Copyright (c) 2014 Ivan Sadikov. All rights reserved.
//

#import "DropitViewController.h"
#import "DropitBehavior.h"
#import "BezierPathView.h"

#define BLOCK_WIDTH     40
#define BLOCK_HEIGHT    40

@interface DropitViewController () <UIDynamicAnimatorDelegate>
@property (weak, nonatomic) IBOutlet BezierPathView *gameView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) DropitBehavior *dropitBehavior;
@property (nonatomic, strong) UIAttachmentBehavior *attachment;
@property (nonatomic, strong) UIView *droppingView;
@end

@implementation DropitViewController

- (UIDynamicAnimator *)animator {
    if (!_animator) {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.gameView];
        _animator.delegate = self;
    }
    
    return _animator;
}

- (DropitBehavior *)dropitBehavior {
    if (!_dropitBehavior) {
        _dropitBehavior = [[DropitBehavior alloc] init];
        [self.animator addBehavior:_dropitBehavior];
    }
    
    return _dropitBehavior;
}

- (IBAction)drop:(UITapGestureRecognizer *)sender {
    [self dropBlock];
}
- (IBAction)move:(UIPanGestureRecognizer *)sender {
    
    CGPoint gesturePoint = [sender locationInView:self.gameView];
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self attachDroppingViewToPoint:gesturePoint];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        self.attachment.anchorPoint = gesturePoint;
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [self.animator removeBehavior:self.attachment];
        self.gameView.path = nil;
    }
}

- (void)attachDroppingViewToPoint:(CGPoint)anchorPoint {
    if (self.droppingView) {
        self.attachment = [[UIAttachmentBehavior alloc] initWithItem:self.droppingView attachedToAnchor:anchorPoint];
        UIView *droppingView = self.droppingView;
        __weak DropitViewController *weakSelf = self;
        self.attachment.action = ^{
            UIBezierPath *path = [[UIBezierPath alloc] init];
            [path moveToPoint:weakSelf.attachment.anchorPoint];
            [path addLineToPoint:droppingView.center];
            weakSelf.gameView.path = path;
        };
        self.droppingView = nil;
        [self.animator addBehavior:self.attachment];
    }
}

- (void)dropBlock {
    int x = (arc4random()%(int)self.gameView.bounds.size.width) / BLOCK_WIDTH;
    int y = self.gameView.bounds.origin.y;
    CGPoint blockOrigin = CGPointMake(x*BLOCK_WIDTH, y);
    CGSize blockSize = CGSizeMake(BLOCK_WIDTH, BLOCK_HEIGHT);
    
    CGRect blockFrame;
    blockFrame.origin = blockOrigin;
    blockFrame.size = blockSize;
    
    UIView *block = [[UIView alloc] initWithFrame:blockFrame];
    block.backgroundColor = [self randomColor];
    
    self.droppingView = block;
    [self.gameView addSubview:block];
    [self.dropitBehavior addItem:block];
}

- (UIColor *)randomColor {
    int x = arc4random()%5;
    switch (x) {
        case 0: return [UIColor greenColor];
        case 1: return [UIColor blueColor];
        case 2: return [UIColor redColor];
        case 3: return [UIColor purpleColor];
        case 4: return [UIColor orangeColor];
        case 5: return [UIColor yellowColor];
    }
    
    return [UIColor blackColor];
}

- (BOOL)removeCompletedRows {
    NSMutableArray *blocksToRemove = [NSMutableArray array];
    
    CGFloat x; // blocks in row
    CGFloat y; // height of lines of blocks
    for (y = self.gameView.bounds.size.height - BLOCK_HEIGHT/2; y > 0; y -= BLOCK_HEIGHT) {
        BOOL rowIsComplete = YES;
        NSMutableArray *dropsFound = [NSMutableArray array];
        
        for (x = BLOCK_WIDTH/2; x <= self.gameView.bounds.size.width - BLOCK_WIDTH/2; x += BLOCK_WIDTH) {
            UIView *hitView = [self.gameView hitTest:CGPointMake(x, y) withEvent:NULL];
            if ([hitView superview] == self.gameView) {
                [dropsFound addObject:hitView];
            } else {
                rowIsComplete = NO;
                break;
            }
        }
        if (![dropsFound count]) break;
        if (rowIsComplete) [blocksToRemove addObjectsFromArray:dropsFound];
    }
    
    if ([blocksToRemove count]) {
        for (UIView *view in blocksToRemove) {
            [self.dropitBehavior removeItem:view];
        }
        [self animateRemovingBlocks:blocksToRemove];
    }
    
    return NO;
}

- (void)animateRemovingBlocks:(NSArray *)blocksToRemove {
    [UIView animateWithDuration:1.0
                     animations:^{
                         for (UIView *item in blocksToRemove) {
                             int x = (arc4random()%(int)(self.gameView.bounds.size.width*5) - (int)self.gameView.bounds.size.width*2);
                             int y = self.gameView.bounds.size.height;
                             item.center = CGPointMake(x, -y);
                         }
                     }
                     completion:^(BOOL finished) {
                         [blocksToRemove makeObjectsPerformSelector:@selector(removeFromSuperview)];
                     }];
}

#pragma mark - UIDymanicAnimator Delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    [self removeCompletedRows];
}

@end
