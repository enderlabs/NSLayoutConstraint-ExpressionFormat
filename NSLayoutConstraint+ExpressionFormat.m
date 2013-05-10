//
//  NSLayoutConstraint+ExpressionFormat.m
//  MetroKit
//
//  Created by Donald Hays on 2/25/13.
//  Copyright (c) 2013 Ender Labs. All rights reserved.
//

#import "NSLayoutConstraint+ExpressionFormat.h"

typedef enum {
    LCEFTokenTypeAttributeLeft,
    LCEFTokenTypeAttributeRight,
    LCEFTokenTypeAttributeTop,
    LCEFTokenTypeAttributeBottom,
    LCEFTokenTypeAttributeLeading,
    LCEFTokenTypeAttributeTrailing,
    LCEFTokenTypeAttributeWidth,
    LCEFTokenTypeAttributeHeight,
    LCEFTokenTypeAttributeCenterX,
    LCEFTokenTypeAttributeCenterY,
    LCEFTokenTypeAttributeBaseline,
    
    LCEFTokenTypeIdentifier,
    
    LCEFTokenTypeOpMultiply,
    LCEFTokenTypeOpSubtract,
    LCEFTokenTypeOpAdd,
    LCEFTokenTypeOpEqual,
    LCEFTokenTypeOpGreaterThanEqual,
    LCEFTokenTypeOpLessThanEqual,
    
    LCEFTokenTypeNumeral,
    LCEFTokenTypeDot,
    LCEFTokenTypeEOF
} LCEFTokenType;

#pragma mark -
#pragma mark LCEFToken
@interface LCEFToken : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSRange range;
@property (nonatomic) LCEFTokenType type;

+ (LCEFToken *)tokenWithText:(NSString *)theText range:(NSRange)theRange type:(LCEFTokenType)theType;
@end

@implementation LCEFToken
+ (LCEFToken *)tokenWithText:(NSString *)theText range:(NSRange)theRange type:(LCEFTokenType)theType
{
    LCEFToken *token = [[LCEFToken alloc] init];
    
    token.text = theText;
    token.range = theRange;
    token.type = theType;
    
    return token;
}
@end

#pragma mark -
#pragma mark LCEFLexer

#define kLCEFIdentifierRegex @"com.ender.lcef.identifier"
#define kLCEFNumeralRegex @"com.ender.lcef.numeral"

@interface LCEFLexer : NSObject
@property (nonatomic) NSUInteger head;
@property (nonatomic, copy) NSString *string;

@property (nonatomic, strong) LCEFToken *currentToken;
@property (nonatomic, strong) LCEFToken *nextToken;

- (void)advanceToNextToken;
- (LCEFToken *)peekAtNextToken;
@end

@implementation LCEFLexer
- (NSDictionary *)generateRegularExpressions
{
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    
    if([threadDictionary objectForKey:kLCEFIdentifierRegex] == nil) {
        [threadDictionary setObject:[NSRegularExpression regularExpressionWithPattern:@"[_a-zA-Z][_a-zA-Z0-9]*" options:0 error:nil] forKey:kLCEFIdentifierRegex];
    }
    
    if([threadDictionary objectForKey:kLCEFNumeralRegex] == nil) {
        [threadDictionary setObject:[NSRegularExpression regularExpressionWithPattern:@"[0-9][0-9]*(\\.[0-9]+)?" options:0 error:nil] forKey:kLCEFNumeralRegex];
    }
    
    return threadDictionary;
}

- (void)parseNextToken
{
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    while(self.head < self.string.length && [whitespaceCharacterSet characterIsMember:[self.string characterAtIndex:self.head]]) {
        self.head++;
    }
    
    if(self.head == self.string.length) {
        self.nextToken = [LCEFToken tokenWithText:@"" range:NSMakeRange(0, 0) type:LCEFTokenTypeEOF];
        
        return;
    }
    
    NSDictionary *regexes = [self generateRegularExpressions];
    
    // Lex Attributes and Identifiers
    NSRegularExpression *identifierRegex = [regexes objectForKey:kLCEFIdentifierRegex];
    NSTextCheckingResult *result = [identifierRegex firstMatchInString:self.string options:0 range:NSMakeRange(self.head, self.string.length - self.head)];
    if(result && result.range.location == self.head) {
        self.nextToken = [LCEFToken tokenWithText:[self.string substringWithRange:result.range] range:result.range type:LCEFTokenTypeIdentifier];
        
        if([self.nextToken.text isEqualToString:@"left"]) {
            self.nextToken.type = LCEFTokenTypeAttributeLeft;
        } else if([self.nextToken.text isEqualToString:@"right"]) {
            self.nextToken.type = LCEFTokenTypeAttributeRight;
        } else if([self.nextToken.text isEqualToString:@"top"]) {
            self.nextToken.type = LCEFTokenTypeAttributeTop;
        } else if([self.nextToken.text isEqualToString:@"bottom"]) {
            self.nextToken.type = LCEFTokenTypeAttributeBottom;
        } else if([self.nextToken.text isEqualToString:@"leading"]) {
            self.nextToken.type = LCEFTokenTypeAttributeLeading;
        } else if([self.nextToken.text isEqualToString:@"trailing"]) {
            self.nextToken.type = LCEFTokenTypeAttributeTrailing;
        } else if([self.nextToken.text isEqualToString:@"width"]) {
            self.nextToken.type = LCEFTokenTypeAttributeWidth;
        } else if([self.nextToken.text isEqualToString:@"height"]) {
            self.nextToken.type = LCEFTokenTypeAttributeHeight;
        } else if([self.nextToken.text isEqualToString:@"centerX"]) {
            self.nextToken.type = LCEFTokenTypeAttributeCenterX;
        } else if([self.nextToken.text isEqualToString:@"centerY"]) {
            self.nextToken.type = LCEFTokenTypeAttributeCenterY;
        } else if([self.nextToken.text isEqualToString:@"baseLine"]) {
            self.nextToken.type = LCEFTokenTypeAttributeBaseline;
        }
        
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Multiply
    if([self.string characterAtIndex:self.head] == '*') {
        self.nextToken = [LCEFToken tokenWithText:@"*" range:NSMakeRange(self.head, 1) type:LCEFTokenTypeOpMultiply];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Equals
    if([self.string characterAtIndex:self.head] == '=') {
        self.nextToken = [LCEFToken tokenWithText:@"=" range:NSMakeRange(self.head, 1) type:LCEFTokenTypeOpEqual];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Greater Than or Equal
    if([[self.string substringFromIndex:self.head] rangeOfString:@">="].location == 0) {
        self.nextToken = [LCEFToken tokenWithText:@">=" range:NSMakeRange(self.head, 2) type:LCEFTokenTypeOpGreaterThanEqual];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Less Than or Equal
    if([[self.string substringFromIndex:self.head] rangeOfString:@"<="].location == 0) {
        self.nextToken = [LCEFToken tokenWithText:@"<=" range:NSMakeRange(self.head, 2) type:LCEFTokenTypeOpLessThanEqual];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Subtracts
    if([self.string characterAtIndex:self.head] == '-') {
        self.nextToken = [LCEFToken tokenWithText:@"-" range:NSMakeRange(self.head, 1) type:LCEFTokenTypeOpSubtract];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Additions
    if([self.string characterAtIndex:self.head] == '+') {
        self.nextToken = [LCEFToken tokenWithText:@"+" range:NSMakeRange(self.head, 1) type:LCEFTokenTypeOpAdd];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Numerals
    NSRegularExpression *numeralRegex = [regexes objectForKey:kLCEFNumeralRegex];
    result = [numeralRegex firstMatchInString:self.string options:0 range:NSMakeRange(self.head, self.string.length - self.head)];
    if(result && result.range.location == self.head) {
        self.nextToken = [LCEFToken tokenWithText:[self.string substringWithRange:result.range] range:result.range type:LCEFTokenTypeNumeral];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Lex Dots
    if([self.string characterAtIndex:self.head] == '.') {
        self.nextToken = [LCEFToken tokenWithText:@"." range:NSMakeRange(self.head, 1) type:LCEFTokenTypeDot];
        self.head += self.nextToken.text.length;
        
        return;
    }
    
    // Failed to lex anything
    [NSException raise:NSGenericException format:@"Unrecognized character '%@' at position %u in string. Invalid expression format.", [self.string substringWithRange:NSMakeRange(self.head, 1)], self.head];
}

- (void)advanceToNextToken
{
    if(self.currentToken != nil && self.currentToken.type == LCEFTokenTypeEOF) {
        [NSException raise:NSGenericException format:@"Lexer attempted to read past the end of the string. This is a bug in the lexer."];
    }
    
    if(self.nextToken == nil) {
        [self peekAtNextToken];
    }
    
    if(self.nextToken == nil) {
        [NSException raise:NSGenericException format:@"Lexer failed to parse a token. This is a bug in the lexer."];
    }
    
    self.currentToken = self.nextToken;
    self.nextToken = nil;
}

- (LCEFToken *)peekAtNextToken
{
    if(self.nextToken == nil) {
        [self parseNextToken];
    }
    
    return self.nextToken;
}
@end

#pragma mark -
#pragma mark LCEFParser
@interface LCEFParser : NSObject
@property (nonatomic, strong) NSString *identifierOfView1;
@property (nonatomic) LCEFTokenType typeOfView1Attribute;

@property (nonatomic, copy) NSString *identifierOfView2;
@property (nonatomic) LCEFTokenType typeOfView2Attribute;

@property (nonatomic) LCEFTokenType typeOfRelation;

@property (nonatomic) BOOL hasMultiplyComponent;
@property (nonatomic) BOOL isMultiplyConstantNegated;
@property (nonatomic, copy) NSString *identifierOfMultiplyConstant;
@property (nonatomic) CGFloat numeralOfMultiplyConstant;

@property (nonatomic) BOOL hasAdditionComponent;
@property (nonatomic) LCEFTokenType operationOfAdditionComponent;
@property (nonatomic) BOOL isAdditionConstantNegated;
@property (nonatomic, copy) NSString *identifierOfAdditionConstant;
@property (nonatomic) CGFloat numeralOfAdditionConstant;

@property (nonatomic) BOOL matchingRightSide;

@property (nonatomic) BOOL matchingConstantForScaleExpression;

@property (nonatomic, strong) LCEFLexer *lexer;

- (void)parse;

- (void)matchExpression;
- (void)matchIdentifierAttributePair;
- (void)matchRelationOperator;
- (void)matchRightSubexpression;
- (void)matchScaleExpression;
- (void)matchAddExpression;
- (void)matchConstant;

- (BOOL)canMatchIdentifierAttributePair;
- (BOOL)canMatchScaleExpression;
- (BOOL)canMatchAddExpression;
@end

@implementation LCEFParser
- (void)parse
{
    [self.lexer advanceToNextToken];
    
    [self matchExpression];
}

- (void)matchExpression
{
    [self matchIdentifierAttributePair];
    [self matchRelationOperator];
    [self matchRightSubexpression];
    
    if(self.lexer.currentToken.type != LCEFTokenTypeEOF) {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected end of string.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
}

- (void)matchIdentifierAttributePair
{
    if(self.lexer.currentToken.type != LCEFTokenTypeIdentifier) {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected identifier.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
    
    LCEFToken *identifier = self.lexer.currentToken;
    
    [self.lexer advanceToNextToken];
    if(self.lexer.currentToken.type != LCEFTokenTypeDot) {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected '.'.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
    
    [self.lexer advanceToNextToken];
    if(self.lexer.currentToken.type != LCEFTokenTypeAttributeLeft &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeRight &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeTop &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeBottom &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeLeading &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeTrailing &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeWidth &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeHeight &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeCenterX &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeCenterY &&
       self.lexer.currentToken.type != LCEFTokenTypeAttributeBaseline)
    {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected attribute.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
    
    LCEFToken *attribute = self.lexer.currentToken;
    
    if(self.matchingRightSide) {
        self.identifierOfView2 = identifier.text;
        self.typeOfView2Attribute = attribute.type;
    } else {
        self.identifierOfView1 = identifier.text;
        self.typeOfView1Attribute = attribute.type;
    }
    
    [self.lexer advanceToNextToken];
}

- (void)matchRelationOperator
{
    if(self.lexer.currentToken.type != LCEFTokenTypeOpEqual &&
       self.lexer.currentToken.type != LCEFTokenTypeOpGreaterThanEqual &&
       self.lexer.currentToken.type != LCEFTokenTypeOpLessThanEqual)
    {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected '=', '>=', or '<='.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
    
    LCEFToken *operator = self.lexer.currentToken;
    self.typeOfRelation = operator.type;
    
    [self.lexer advanceToNextToken];
}

- (void)matchRightSubexpression
{
    self.matchingRightSide = YES;
    
    if([self canMatchIdentifierAttributePair]) {
        [self matchIdentifierAttributePair];
        
        if([self canMatchScaleExpression]) {
            self.hasMultiplyComponent = YES;
            [self matchScaleExpression];
        }
        
        if([self canMatchAddExpression]) {
            self.hasAdditionComponent = YES;
            [self matchAddExpression];
        }
    } else {
        self.operationOfAdditionComponent = LCEFTokenTypeOpAdd;
        self.hasAdditionComponent = YES;
        [self matchConstant];
    }
}

- (void)matchScaleExpression
{
    if(self.lexer.currentToken.type != LCEFTokenTypeOpMultiply) {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected '*'.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
    
    [self.lexer advanceToNextToken];
    self.matchingConstantForScaleExpression = YES;
    [self matchConstant];
    self.matchingConstantForScaleExpression = NO;
}

- (void)matchAddExpression
{
    if(self.lexer.currentToken.type != LCEFTokenTypeOpAdd && self.lexer.currentToken.type != LCEFTokenTypeOpSubtract) {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected '+' or '-'.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
    
    LCEFToken *operator = self.lexer.currentToken;
    self.operationOfAdditionComponent = operator.type;
    
    [self.lexer advanceToNextToken];
    [self matchConstant];
}

- (void)matchConstant
{
    if(self.lexer.currentToken.type == LCEFTokenTypeOpSubtract) {
        if(self.matchingConstantForScaleExpression) {
            self.isMultiplyConstantNegated = YES;
        } else {
            self.isAdditionConstantNegated = YES;
        }
        
        [self.lexer advanceToNextToken];
    }
    
    if(self.lexer.currentToken.type != LCEFTokenTypeIdentifier && self.lexer.currentToken.type != LCEFTokenTypeNumeral) {
        [NSException raise:NSGenericException format:@"Unexpected '%@' at %u. Expected identifier or numeral.", self.lexer.currentToken.text, self.lexer.currentToken.range.location];
    }
    
    LCEFToken *atom = self.lexer.currentToken;
    if(self.matchingConstantForScaleExpression) {
        if(atom.type == LCEFTokenTypeIdentifier) {
            self.identifierOfMultiplyConstant = atom.text;
        } else {
            self.numeralOfMultiplyConstant = atom.text.floatValue;
        }
    } else {
        if(atom.type == LCEFTokenTypeIdentifier) {
            self.identifierOfAdditionConstant = atom.text;
        } else {
            self.numeralOfAdditionConstant = atom.text.floatValue;
        }
    }
    
    [self.lexer advanceToNextToken];
}

- (BOOL)canMatchIdentifierAttributePair
{
    if(self.lexer.currentToken.type != LCEFTokenTypeIdentifier) {
        return NO;
    }
    
    return [self.lexer peekAtNextToken].type == LCEFTokenTypeDot;
}

- (BOOL)canMatchScaleExpression
{
    return self.lexer.currentToken.type == LCEFTokenTypeOpMultiply;
}

- (BOOL)canMatchAddExpression
{
    return self.lexer.currentToken.type == LCEFTokenTypeOpAdd || self.lexer.currentToken.type == LCEFTokenTypeOpSubtract;
}
@end

#pragma mark -
#pragma mark NSLayoutConstraint (ExpressionFormat)
@implementation NSLayoutConstraint (ExpressionFormat)
+ (NSLayoutAttribute)layoutAttributeForTokenType:(LCEFTokenType)type
{
    switch (type) {
        case LCEFTokenTypeAttributeLeft:
            return NSLayoutAttributeLeft;
        case LCEFTokenTypeAttributeRight:
            return NSLayoutAttributeRight;
        case LCEFTokenTypeAttributeTop:
            return NSLayoutAttributeTop;
        case LCEFTokenTypeAttributeBottom:
            return NSLayoutAttributeBottom;
        case LCEFTokenTypeAttributeLeading:
            return NSLayoutAttributeLeading;
        case LCEFTokenTypeAttributeTrailing:
            return NSLayoutAttributeTrailing;
        case LCEFTokenTypeAttributeWidth:
            return NSLayoutAttributeWidth;
        case LCEFTokenTypeAttributeHeight:
            return NSLayoutAttributeHeight;
        case LCEFTokenTypeAttributeCenterX:
            return NSLayoutAttributeCenterX;
        case LCEFTokenTypeAttributeCenterY:
            return NSLayoutAttributeCenterY;
        case LCEFTokenTypeAttributeBaseline:
            return NSLayoutAttributeBaseline;
        default:
            [NSException raise:NSGenericException format:@"No match for layout attribute. This is a bug in the parser."];
            break;
    }
    return NSLayoutAttributeLeft;
}

+ (NSLayoutConstraint *)constraintWithExpressionFormat:(NSString *)theFormat parameters:(NSDictionary *)theParameters
{
    LCEFLexer *lexer = [[LCEFLexer alloc] init];
    lexer.string = theFormat;
    
    LCEFParser *parser = [[LCEFParser alloc] init];
    parser.lexer = lexer;
    
    [parser parse];
    
    id view1 = nil;
    NSLayoutAttribute attribute1 = NSLayoutAttributeNotAnAttribute;
    NSLayoutRelation relation = NSLayoutRelationEqual;
    id view2 = nil;
    NSLayoutAttribute attribute2 = NSLayoutAttributeNotAnAttribute;
    CGFloat multiplier = 1.0f;
    CGFloat constant = 0.0f;
    
    view1 = [theParameters objectForKey:parser.identifierOfView1];
    if(view1 == nil) {
        [NSException raise:NSGenericException format:@"No view named %@ found in parameters.", parser.identifierOfView1];
    }
    
    attribute1 = [self layoutAttributeForTokenType:parser.typeOfView1Attribute];
    
    switch (parser.typeOfRelation) {
        case LCEFTokenTypeOpEqual:
            relation = NSLayoutRelationEqual;
            break;
        case LCEFTokenTypeOpGreaterThanEqual:
            relation = NSLayoutRelationGreaterThanOrEqual;
            break;
        case LCEFTokenTypeOpLessThanEqual:
            relation = NSLayoutRelationLessThanOrEqual;
            break;
        default:
            [NSException raise:NSGenericException format:@"No match for relation type. This is a bug in the parser."];
            break;
    }
    
    if(parser.identifierOfView2) {
        if([parser.identifierOfView2 isEqual:@"superview"]) {
            view2 = [view1 superview];
        } else {
            view2 = [theParameters objectForKey:parser.identifierOfView2];
        }
        
        if(view2 == nil) {
            [NSException raise:NSGenericException format:@"No view named %@ found in parameters.", parser.identifierOfView2];
        }
        
        attribute2 = [self layoutAttributeForTokenType:parser.typeOfView2Attribute];
    } else {
        if(attribute1 != NSLayoutAttributeWidth && attribute1 != NSLayoutAttributeHeight) {
            view2 = [view1 superview];
            attribute2 = attribute1;
            
            if(attribute1 == NSLayoutAttributeBaseline) {
                attribute2 = NSLayoutAttributeTop;
            }
        }
    }
    
    if(parser.hasMultiplyComponent) {
        multiplier = parser.numeralOfMultiplyConstant;
        if(parser.identifierOfMultiplyConstant) {
            NSNumber *number = [theParameters objectForKey:parser.identifierOfMultiplyConstant];
            if(number == nil) {
                [NSException raise:NSGenericException format:@"No value named %@ found in parameters.", parser.identifierOfMultiplyConstant];
            }
            
            multiplier = [number floatValue];
        }
        
        if(parser.isMultiplyConstantNegated) {
            multiplier *= -1;
        }
    }
    
    if(parser.hasAdditionComponent) {
        constant = parser.numeralOfAdditionConstant;
        if(parser.identifierOfAdditionConstant) {
            NSNumber *number = [theParameters objectForKey:parser.identifierOfAdditionConstant];
            if(number == nil) {
                [NSException raise:NSGenericException format:@"No value named %@ found in parameters.", parser.identifierOfAdditionConstant];
            }
            
            constant = [number floatValue];
        }
        
        if(parser.operationOfAdditionComponent == LCEFTokenTypeOpSubtract) {
            constant *= -1;
        }
        
        if(parser.isMultiplyConstantNegated) {
            constant *= -1;
        }
    }
    
    return [NSLayoutConstraint constraintWithItem:view1 attribute:attribute1 relatedBy:relation toItem:view2 attribute:attribute2 multiplier:multiplier constant:constant];
}
@end
