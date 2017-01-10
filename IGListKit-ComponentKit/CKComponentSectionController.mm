//
//  CKComponentSectionController.m
//  IGListKit-ComponentKit
//
//  Created by Oliver Rickard on 1/9/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "CKComponentSectionController.h"

#import <ComponentKit/CKTransactionalComponentDataSourceListener.h>
#import <ComponentKit/CKTransactionalComponentDataSourceState.h>
#import <ComponentKit/CKTransactionalComponentDataSourceAppliedChanges.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItem.h>
#import <ComponentKit/CKComponentDataSourceAttachController.h>

@interface CKComponentSectionControllerCell : UICollectionViewCell
@property (nonatomic, strong, readonly) CKComponentRootView *rootView;
@end

@implementation CKComponentSectionControllerCell

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    // Ideally we could simply cause the cell's existing contentView to be of type CKComponentRootView.
    // Alas the only way to do this is via private API (_contentViewClass) so we are forced to add a subview.
    _rootView = [[CKComponentRootView alloc] initWithFrame:CGRectZero];
    [[self contentView] addSubview:_rootView];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  const CGSize size = [[self contentView] bounds].size;
  [_rootView setFrame:CGRectMake(0, 0, size.width, size.height)];
}

@end

@implementation CKComponentSectionItem

- (instancetype)initWithIdentifier:(id<NSCopying, NSObject>)identifier
                             items:(NSArray<id<IGListDiffable>> *)items
{
  if (self = [super init]) {
    _identifier = [identifier copyWithZone:NULL];
    _items = [items copy];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  // Immutable
  return self;
}

- (NSUInteger)hash
{
  return [_identifier hash];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[CKComponentSectionItem class]]) {
    return NO;
  }

  CKComponentSectionItem *other = object;
  return (CKObjectIsEqual(_identifier, other.identifier)
          && CKObjectIsEqual(_items, other.items));
}

#pragma mark - IGListDiffable

- (id<NSObject>)diffIdentifier
{
  return _identifier;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object
{
  return [self isEqual:object];
}

@end

@interface CKComponentSectionController () <CKTransactionalComponentDataSourceListener>

@end

@implementation CKComponentSectionController
{
  Class<CKComponentProvider> _componentProvider;

  CKTransactionalComponentDataSource *_datasource;

  CKComponentSectionItem *_item;

  CKTransactionalComponentDataSourceState *_state;
  CKComponentDataSourceAttachController *_attachController;
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
{
  if (self = [super init]) {
    _attachController = [[CKComponentDataSourceAttachController alloc] init];

    _componentProvider = componentProvider;
    _datasource = [[CKTransactionalComponentDataSource alloc] initWithConfiguration:
                   [[CKTransactionalComponentDataSourceConfiguration alloc]
                    initWithComponentProvider:componentProvider
                    context:context
                    sizeRange:sizeRange]];
    [_datasource addListener:self];
    [_datasource
     applyChangeset:
     [[CKTransactionalComponentDataSourceChangeset alloc]
      initWithUpdatedItems:nil
      removedItems:nil
      removedSections:nil
      movedItems:nil
      insertedSections:[NSIndexSet indexSetWithIndex:0]
      insertedItems:nil]
     mode:CKUpdateModeSynchronous
     userInfo:nil];
  }
  return self;
}

- (void)updateContext:(id<NSObject>)context
            sizeRange:(const CKSizeRange &)sizeRange
                 mode:(CKUpdateMode)mode
{
  [_datasource
   updateConfiguration:
   [[CKTransactionalComponentDataSourceConfiguration alloc]
    initWithComponentProvider:_componentProvider
    context:context
    sizeRange:sizeRange]
   mode:mode
   userInfo:nil];
}

#pragma mark - CKTransactionalComponentDataSourceListener

- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes
{
  CKTransactionalComponentDataSourceState *state = dataSource.state;
  [self.collectionContext
   performBatchAnimated:NO
   updates:^{
     if (changes.movedIndexPaths.count > 0) {
       // There's no support for applying moved within a section to the collection context, so we just have to reload
       // the entire thing if something is moved. This should only happen rarely (I hope).
       [self.collectionContext reloadSectionController:self];
     } else {
       if (changes.updatedIndexPaths.count > 0) {
         NSMutableIndexSet *reloadedIndices = [NSMutableIndexSet indexSet];
         [changes.updatedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *path, BOOL *stop) {
           [reloadedIndices addIndex:path.row];
         }];
         [self.collectionContext reloadInSectionController:self
                                                 atIndexes:reloadedIndices];
       }

       if (changes.removedIndexPaths.count > 0) {
         NSMutableIndexSet *removedIndices = [NSMutableIndexSet indexSet];
         [changes.removedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *path, BOOL *stop) {
           [removedIndices addIndex:path.row];
         }];
         [self.collectionContext deleteInSectionController:self
                                                 atIndexes:removedIndices];
       }

       if (changes.insertedIndexPaths.count > 0) {
         NSMutableIndexSet *insertedIndices = [NSMutableIndexSet indexSet];
         [changes.insertedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *path, BOOL *stop) {
           [insertedIndices addIndex:path.row];
         }];
         [self.collectionContext insertInSectionController:self
                                                 atIndexes:insertedIndices];
       }
     }

     _state = state;
   }
   completion:^(BOOL finished) {

   }];
}

#pragma mark - IGListSectionType

- (NSInteger)numberOfItems
{
  return [_state numberOfObjectsInSection:0];
}

- (CGSize)sizeForItemAtIndex:(NSInteger)index
{
  return [[_state objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] layout].size;
}

- (UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index
{
  CKTransactionalComponentDataSourceItem *item = [_state objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];

  CKComponentSectionControllerCell *cell = (CKComponentSectionControllerCell *)[self.collectionContext
                                                                                dequeueReusableCellOfClass:
                                                                                [CKComponentSectionControllerCell class]
                                                                                forSectionController:self
                                                                                atIndex:index];
  
  [_attachController attachComponentLayout:item.layout
                       withScopeIdentifier:item.scopeRoot.globalIdentifier
                       withBoundsAnimation:item.boundsAnimation
                                    toView:cell.rootView];

  return cell;
}

- (void)didUpdateToObject:(CKComponentSectionItem *)item
{
  IGListIndexSetResult *result = IGListDiff(_item.items, item.items, IGListDiffEquality);
  NSMutableDictionary<NSIndexPath *, id<NSObject, NSCopying>> *updatedItems;
  NSMutableSet<NSIndexPath *> *removedItems;
  NSMutableDictionary<NSIndexPath *, id<NSObject, NSCopying>> *insertedItems;
  NSMutableDictionary<NSIndexPath *, NSIndexPath *> *movedItems;

  if (result.deletes.count > 0) {
    removedItems = [NSMutableSet set];
  }
  [result.deletes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
    [removedItems addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
  }];

  if (result.inserts.count > 0) {
    insertedItems = [NSMutableDictionary dictionary];
  }
  [result.inserts enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    insertedItems[[NSIndexPath indexPathForRow:idx inSection:0]] = item.items[idx];
  }];

  if (result.updates.count > 0) {
    updatedItems = [NSMutableDictionary dictionary];
  }
  [result.updates enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    updatedItems[[NSIndexPath indexPathForRow:idx inSection:0]] = item.items[idx];
  }];

  if (result.moves.count > 0) {
    movedItems = [NSMutableDictionary dictionary];
  }
  [result.moves enumerateObjectsUsingBlock:^(IGListMoveIndex *obj, NSUInteger idx, BOOL *stop) {
    movedItems[[NSIndexPath indexPathForRow:obj.from inSection:0]] = [NSIndexPath indexPathForRow:obj.to inSection:0];
  }];

  [_datasource
   applyChangeset:
   [[CKTransactionalComponentDataSourceChangeset alloc]
    initWithUpdatedItems:updatedItems
    removedItems:removedItems
    removedSections:nil
    movedItems:movedItems
    insertedSections:nil
    insertedItems:insertedItems]
   mode:CKUpdateModeAsynchronous
   userInfo:nil];
}

- (void)didSelectItemAtIndex:(NSInteger)index
{
  [self.collectionContext deselectItemAtIndex:index
                            sectionController:self
                                     animated:NO];
}

@end
