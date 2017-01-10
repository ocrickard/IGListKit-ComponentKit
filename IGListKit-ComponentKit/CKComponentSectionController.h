//
//  CKComponentSectionController.h
//  IGListKit-ComponentKit
//
//  Created by Oliver Rickard on 1/9/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <IGListKit/IGListKit.h>
#import <ComponentKit/ComponentKit.h>

@interface CKComponentSectionItem : NSObject <NSCopying, IGListDiffable>

@property (nonatomic, copy, readonly) id<NSCopying, NSObject> identifier;
@property (nonatomic, copy, readonly) NSArray<id<IGListDiffable, NSCopying, NSObject>> *items;

- (instancetype)initWithIdentifier:(id<NSCopying, NSObject>)identifier
                             items:(NSArray<id<IGListDiffable, NSCopying, NSObject>> *)items;

@end

@interface CKComponentSectionController : IGListSectionController <IGListSectionType>

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange;

- (void)updateContext:(id<NSObject>)context
            sizeRange:(const CKSizeRange &)sizeRange
                 mode:(CKUpdateMode)mode;

@end
