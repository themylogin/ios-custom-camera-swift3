//
//  OpenCVWrapper.h
//  CustomCamera
//
//  Created by themylogin on 10/03/2019.
//  Copyright © 2019 FAYA Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (UIImage *)cannyEdges:(UIImage *)image threshold:(int)threshold thickness:(int)thickness;

@end

NS_ASSUME_NONNULL_END
