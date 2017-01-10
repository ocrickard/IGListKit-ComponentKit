//
//  ViewController.m
//  IGListKit-ComponentKit
//
//  Created by Oliver Rickard on 1/9/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "ViewController.h"

#import <IGListKit/IGListAdapter.h>
#import <IGListKit/IGListAdapterUpdater.h>

#import <ComponentKit/CKLabelComponent.h>

#import "CKComponentSectionController.h"

@interface ViewController () <IGListAdapterDataSource, CKComponentProvider>

@end

@implementation ViewController
{
  IGListAdapter *_listAdapter;
  IGListCollectionView *_collectionView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.

  _collectionView = [[IGListCollectionView alloc] initWithFrame:self.view.bounds
                                           collectionViewLayout:[UICollectionViewFlowLayout new]];
  [self.view addSubview:_collectionView];

  _listAdapter = [[IGListAdapter alloc] initWithUpdater:[IGListAdapterUpdater new]
                                         viewController:self
                                       workingRangeSize:0];

  _listAdapter.dataSource = self;
  _listAdapter.collectionView = _collectionView;
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

#pragma mark - IGListAdapterDataSource

- (NSArray<id<IGListDiffable>> *)objectsForListAdapter:(IGListAdapter *)listAdapter
{
  return @[[[CKComponentSectionItem alloc] initWithIdentifier:@"item1"
                                                        items:@[@"Hello World", @"These cells are being rendered With ComponentKit", @"via IGListKit"]]];
}

- (IGListSectionController<IGListSectionType> *)listAdapter:(IGListAdapter *)listAdapter sectionControllerForObject:(id)object
{
  return [[CKComponentSectionController alloc]
          initWithComponentProvider:[self class]
          context:nil
          sizeRange:{
            {self.view.bounds.size.width, 0},
            {self.view.bounds.size.width, CGFLOAT_MAX}
          }];
}

- (UIView *)emptyViewForListAdapter:(IGListAdapter *)listAdapter
{
  return nil;
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(NSString *)model context:(id<NSObject>)context
{
  return
  [CKStackLayoutComponent
   newWithView:{}
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = 6
   }
   children:{
     {[CKInsetComponent
       newWithInsets:{
         .left = 10,
         .right = 10,
         .top = 10,
         .bottom = 10
       }
       component:
       [CKLabelComponent
        newWithLabelAttributes:{
          .string = model
        }
        viewAttributes:{}
        size:{}]]},
     {
       [CKRatioLayoutComponent
        newWithRatio:9.0/16.0 size:{
          .width = CKRelativeDimension::Percent(1)
        }
        component:
        [CKComponent
         newWithView:{
           [UIView class],
           {
             {@selector(setBackgroundColor:), [UIColor blueColor]},
           }
         }
         size:{}]]}
   }];
}

@end
