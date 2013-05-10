//
// NSLayoutConstraint+ExpressionFormat.h
// MetroKit
//
// Copyright 2013 Ender Labs. All rights reserved.
// Created by Donald Hays.
//

#import <UIKit/UIKit.h>

@interface NSLayoutConstraint (ExpressionFormat)
+ (NSLayoutConstraint *)constraintWithExpressionFormat:(NSString *)theFormat parameters:(NSDictionary *)theParameters;
@end
