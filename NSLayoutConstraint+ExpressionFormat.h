//
//  NSLayoutConstraint+ExpressionFormat.h
//  MetroKit
//
//  Created by Donald Hays on 2/25/13.
//  Copyright (c) 2013 Ender Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSLayoutConstraint (ExpressionFormat)
+ (NSLayoutConstraint *)constraintWithExpressionFormat:(NSString *)theFormat parameters:(NSDictionary *)theParameters;
@end
