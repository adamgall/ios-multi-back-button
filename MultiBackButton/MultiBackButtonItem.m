//
//  MultiBackButtonItem.m
//
//  Anders Borum @palmin
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Anders Borum
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <objc/message.h>
#import "MultiBackButtonItem.h"

@interface MultiBackButtonView : UIButton <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate,
                                           UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate> {
    NSTimeInterval touchStart;
    CGPoint pointStart;
    BOOL significantMovement;
    
    NSIndexPath* hoverIndexPath; // the one selected because finger is above it
}

@property (nonatomic, strong) UIImageView* chevron;
//@property (nonatomic, strong) UILabel* label;
@property (nonatomic, strong) MultiBackButtonItem* item;

@property (nonatomic, weak) UIViewController* viewController;
@property (nonatomic, strong) UITableViewController* tableController;
@property (nonatomic, strong) NSArray* cells;

@end

@implementation MultiBackButtonView

#define BackgroundColor [UIColor colorWithWhite:244.0/255 alpha:1];

static NSString* titleForViewController(UIViewController* controller) {
    // make sure view is loaded
    [controller view];
    
    NSString* title = controller.multiBackButtonTitle;
    if(title == nil) {
        title = controller.navigationItem.title;
        if(title == nil) title = controller.title;
    }
    
    return title;
}

static UIImage* imageForController(UIViewController* controller) {
    // make sure view is loaded
    [controller view];
    
    return controller.multiBackButtonImage;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.accessibilityLabel = NSLocalizedString(@"Back", nil);
        
        UIImageView* chevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"back"]];
        [self addSubview:chevron];
        self.chevron = chevron;
        
        //UILabel* label = [[UILabel alloc] initWithFrame:self.bounds];
        //label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        //label.lineBreakMode = NSLineBreakByTruncatingTail;
        //[self addSubview: label];
        //self.label = label;
    }
    return self;
}

-(void)layoutSubviews {
    CGSize pSize = self.bounds.size;
    
    // image is to the left and vertically centered
    CGSize iSize = self.chevron.bounds.size;
    self.chevron.frame = CGRectMake(0, 0.5 * (pSize.height - iSize.height), iSize.width, iSize.height);
    
    // label is left of image and vertically centered
    
    //CGSize lSize = self.label.bounds.size;
    //CGFloat x = ceil(5.0 + iSize.width);
    //self.label.frame = CGRectMake(x, 0.5 * (pSize.height - lSize.height), pSize.width - x, lSize.height);
}

-(void)setTitle:(NSString*)title {
    //self.label.text = title;
    //self.label.textColor = self.tintColor;
    //[self.label sizeToFit];
    [self sizeToFit];
    [self setNeedsLayout];
}

-(UINavigationBar*)navigationBar {
    UIView* view = self;
    while (view != nil) {
        if([view isKindOfClass:[UINavigationBar class]]) {
            return (UINavigationBar*)view;
        }
        view = view.superview;
    }
    return nil;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.tableController = nil;
    self.cells = nil;
}


-(void)presentSelection {
    NSArray* viewControllers = self.viewController.navigationController.viewControllers;
    NSUInteger index = [viewControllers indexOfObject:self.viewController];
    if(index == NSNotFound) return;
    
    // make sure we have view controller with hierarchy
    if(self.tableController == nil) {
        NSMutableArray* cells = [NSMutableArray new];
        for(NSInteger k = index; k >= 0; --k) {
            UITableViewController* controller = [viewControllers objectAtIndex:k];
            UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text = titleForViewController(controller);
            cell.imageView.image = imageForController(controller);
            [cells addObject:cell];
        }
        
        // we add final cell if there is previous info for root controller
        UIViewController* root = [viewControllers firstObject];
        NSArray* previousInfo = [root previousInfo];
        if(previousInfo) {
            NSObject* perhapsImage = [previousInfo objectAtIndex:1];
            
            UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text = [previousInfo objectAtIndex:0];
            if([perhapsImage isKindOfClass:[UIImage class]]) {
                cell.imageView.image = (UIImage*)perhapsImage;
            }
            [cells addObject:cell];
        }
        
        self.cells = cells;
        
        self.tableController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        UITableView* tableView = self.tableController.tableView;
        tableView.backgroundColor = BackgroundColor;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.alwaysBounceVertical = NO;
        [tableView sizeToFit];
        CGRect f = tableView.frame;
        f.size.width = 290;
        tableView.frame = f;
        self.tableController.preferredContentSize = tableView.bounds.size;
                
        self.tableController.modalPresentationStyle = UIModalPresentationPopover;
        self.tableController.popoverPresentationController.delegate = self;
        self.tableController.popoverPresentationController.sourceView = self.chevron;
        self.tableController.popoverPresentationController.sourceRect = self.chevron.bounds;
        
        [self.viewController presentViewController:self.tableController animated:YES completion:nil];
    }
}

-(void)removeSelectionAnimated:(BOOL)animated completion:(void (^)(void))block {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(presentSelection) object:nil];

    if(self.tableController) {
        [self.viewController dismissViewControllerAnimated:animated completion:^{
            self.tableController = nil;
            self.cells = nil;
            if(block) block();
        }];
    } else {
        if(block) block();
    }
}

// which cell is below touch, nil if none
-(NSIndexPath*)IndexPathPoint:(CGPoint)pt {
    UITableView* tableView = self.tableController.tableView;
    CGPoint point = [self convertPoint:pt toView: tableView];
    NSIndexPath* indexPath = [tableView indexPathForRowAtPoint: point];
    return indexPath;
}

-(void)clearHoverSelection {
    if(hoverIndexPath) {
        UITableViewCell* cell = [self.tableController.tableView cellForRowAtIndexPath:hoverIndexPath];
        [cell setSelected:NO animated:NO];
        hoverIndexPath = nil;
    }
}

#pragma mark Touch handling

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    touchStart = [NSDate timeIntervalSinceReferenceDate];
    pointStart = [touch locationInView:self];
    significantMovement = NO;
    touchStart = [NSDate timeIntervalSinceReferenceDate];
    
    [self performSelector:@selector(presentSelection) withObject:nil afterDelay:0.3];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if(!significantMovement) {
        CGFloat dx = point.x - pointStart.x, dy = point.y - pointStart.y;
        CGFloat sqrdist = dx*dx + dy*dy;
        significantMovement = sqrdist >= 50 * 50;
        if(significantMovement) {
            [self presentSelection];
        }
    }
    
    // indicate selection when above cell
    NSIndexPath* indexPath = [self IndexPathPoint: point];
    if(indexPath) {
        if([indexPath isEqual: hoverIndexPath]) return;
        [self clearHoverSelection];
        hoverIndexPath = indexPath;
        
        UITableViewCell* cell = [self.tableController.tableView cellForRowAtIndexPath:indexPath];
        [cell setSelected:YES animated:NO];
    } else {
        [self clearHoverSelection];
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self removeSelectionAnimated:NO completion:nil];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    NSIndexPath* indexPath = [self IndexPathPoint: point];
    if(indexPath) {
        [self tableView:self.tableController.tableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    // if we have had much movement but no selection we just dismiss without going back
    if(significantMovement) {
        [self removeSelectionAnimated: YES completion:nil];
        return;
    }
    
    // if we touched more than a half second, we assume user wants to use popup
    NSTimeInterval secsSinceBegan = [NSDate timeIntervalSinceReferenceDate] - touchStart;
    if(secsSinceBegan >= 0.3) return;
    
    // if we end quick touch we do regular back
    [self removeSelectionAnimated:YES completion:^{
        [self.viewController.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.cells objectAtIndex:indexPath.row];
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self removeSelectionAnimated:YES completion:^{
        
        NSArray* viewControllers = self.viewController.navigationController.viewControllers;
        NSInteger index = [viewControllers indexOfObject:self.viewController];
        if(index != NSNotFound) {
            index -= indexPath.row;
            if(index < viewControllers.count) {
                UITableViewController* controller = [viewControllers objectAtIndex:index];
                [self.viewController.navigationController popToViewController:controller animated:YES];
            } else if(index == -1) {
                // this might be the previous Info, which we then act upon
                UITableViewController* root = [viewControllers firstObject];
                NSArray* previousInfo = [root previousInfo];
                void (^action)(void) = [previousInfo objectAtIndex:2];
                if(action) {
                    // we have action and we execute this when done popping
                    if(self.viewController == root) {
                        // this is right now when already at correct level
                        action();
                    } else {
                        // we use Core Animation to know when pop animation completes
                        [CATransaction begin];
                        [CATransaction setCompletionBlock: action];
                        [self.viewController.navigationController popToViewController:root animated:YES];
                        [CATransaction commit];
                    }
                }
            }
        }
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = BackgroundColor;
}

#pragma mark -

@end

@implementation MultiBackButtonItem

-(MultiBackButtonView*)view {
    return (MultiBackButtonView*)self.customView;
}

-(void)refreshTitle {
    NSString* title = nil;
    
    NSArray* viewControllers = self.view.viewController.navigationController.viewControllers;
    NSUInteger index = [viewControllers indexOfObject:self.view.viewController];
    if(index > 0 && index != NSNotFound) {
        UIViewController* before = [viewControllers objectAtIndex:index-1];
        title = titleForViewController(before);
    }
    
    MultiBackButtonView* view = (MultiBackButtonView*)self.customView;
    [view setTitle:title];
}

+(MultiBackButtonItem*)backButtonForController:(UIViewController*)controller {
    MultiBackButtonView* view = [[MultiBackButtonView alloc] initWithFrame:CGRectMake(0,0, 75, 45)];
    
    MultiBackButtonItem* backButton = [[MultiBackButtonItem alloc] initWithCustomView:view];
    backButton.width = view.frame.size.width;
    backButton.view.viewController = controller;
    view.item = backButton;
    [backButton refreshTitle];
    return backButton;
}

+(void)useForViewController:(UIViewController*)viewController {
    // stop early if we already are configured
    if([viewController.navigationItem.leftBarButtonItem isKindOfClass:[MultiBackButtonItem class]]) {
        return;
    }
    
    // we only set back-button if part of navigation stack and not at the root
    NSInteger index = [viewController.navigationController.viewControllers indexOfObject:viewController];
    if(index == NSNotFound) return; // this happens if there is nav-controller, but view-controller is not in stack,
                                    // which will perhaps never happen
    if(index == 0) return; // this happens both when there is no nav-controller or when at the root
    
    UIBarButtonItem* item = [MultiBackButtonItem backButtonForController: viewController];
    __weak MultiBackButtonView* weak_view = (MultiBackButtonView*)item.customView;
    
    viewController.navigationItem.leftBarButtonItem = item;
    viewController.navigationController.interactivePopGestureRecognizer.delegate = weak_view;
    viewController.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    viewController.navigationController.interactivePopGestureRecognizer.cancelsTouchesInView = YES;
}

@end

@implementation UIViewController (MultiBackButtonItem)

static char associationMultiBackButtonImage, associationMultiBackButtonTitle, associationPreviousInfo;

-(void)setMultiBackButtonImage:(UIImage *)multiBackButtonImage {
    objc_setAssociatedObject (self, &associationMultiBackButtonImage, multiBackButtonImage, OBJC_ASSOCIATION_RETAIN);
}

-(UIImage*)multiBackButtonImage {
    return objc_getAssociatedObject(self, &associationMultiBackButtonImage);
}

-(void)setMultiBackButtonTitle:(NSString *)multiBackButtonTitle {
    objc_setAssociatedObject (self, &associationMultiBackButtonTitle, multiBackButtonTitle, OBJC_ASSOCIATION_RETAIN);
}

-(NSString*)multiBackButtonTitle {
    return objc_getAssociatedObject(self, &associationMultiBackButtonTitle);
}

-(void)configureMultiBackButton {
    [MultiBackButtonItem useForViewController:self];
}

-(NSArray*)previousInfo {
    return objc_getAssociatedObject(self, &associationPreviousInfo);
}

-(void)configurePreviousTitle:(NSString*)title image:(UIImage*)image action:(void (^)(void))block {
    NSArray* info = @[title != nil ? title : nil,
                      image != nil ? image : [NSNull null],
                      [block copy]];
    objc_setAssociatedObject (self, &associationPreviousInfo, info, OBJC_ASSOCIATION_RETAIN);
}

@end
