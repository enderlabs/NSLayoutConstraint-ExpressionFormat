# NSLayoutConstraint+ExpressionFormat

## Installation

## Contributing
Please feel free to [fork the code](https://github.com/enderlabs/NSLayoutConstraint-ExpressionFormat), and submit pull requests for any new features or fixes.

## Syntax

### Grammar

     ATTRIBUTE    = "left"
                  | "right"
                  | "top"
                  | "bottom"
                  | "leading"
                  | "trailing"
                  | "width"
                  | "height"
                  | "centerX"
                  | "centerY"
                  | "baseline" ;
     IDENTIFIER   = [_a-zA-Z][_a-zA-Z0-9]* ;
     NUMERAL      = [0-9]+("."[0-9]+)? ;
     MUL_OPERATOR = "*" ;
     EQ_OPERATOR  = "=" ;
     GTE_OPERATOR = ">=" ;
     LTE_OPERATOR = "<=" ;
     SUB_OPERATOR = "-" ;
     ADD_OPERATOR = "+" ;
     DOT          = "." ;
     EOF          = <end of file/string> ;

     expression              = identifierAttributePair relationOperator rightSubexpression EOF ;
     relationOperator        = EQ_OPERATOR
                             | GTE_OPERATOR
                             | LTE_OPERATOR ;
     rightSubexpression      = identifierAttributePair scaleExpression? addExpression?
                             | constant ;
     scaleExpression         = MUL_OPERATOR constant ;
     addExpression           = (ADD_OPERATOR | SUB_OPERATOR) constant ;
     constant                = SUB_OPERATOR? (IDENTIFIER | NUMERAL) ;
     identifierAttributePair = IDENTIFIER DOT ATTRIBUTE ;

### Example Strings

     view1.left = 10
     view1.width = superview.width
     view1.width = superview.width * 0.9
     view1.width = superview.width * myVar
     view1.width = view2.width - 20
     view1.width = view2.width * 0.9 + 5
     view1.trailing >= 20

### Invalid Strings

     view1 = view2                       // Must specify view.attribute, not just view
     view1.subview.left = 20             // Cannot follow dot paths of variables
     [view1 setLeft:20]                  // No. Just, no.
     view1.left = 20 + superview.left    // Constant must come at end of expression. Sorry :(
     view1.left + 20 = superview.left    // No really, the constant *must* come at end of expression.
     view1.left = 20 + 3                 // Don't do constant math
     view1.left = view2.width * (0.9 + 5)// Don't do parentheses

## Usage

Auto Layout uses a series of linear equations as constraints to determine the size and position of views. This category allows you to declare these equations in a straightforward, string-based syntax.

There are three key rules to keep in mind when using Auto Layout, including when using the expression format:

* You must create enough constraints to fully describe a view's position and size. This usually means 4 constraints per view (example: left, top, width, height). Some views (like labels) can self-determine size if you don't apply a constraint.
* Be sure to set `translatesAutoresizingMaskIntoConstraints` to `NO` on your views, otherwise your app will generate constraints automatically from the autoresizing mask, and broken constraints will happen.
* If you've put constraints on your views, don't adjust their frames manually. Let the constraint system handle all of it.

### Basic Example

You create expression-based constraints using `constraintWithExpressionFormat:parameters:`, a class method added to NSLayoutConstraint by this category.

     self.someView = [[UIView alloc] init];
     self.someView.translatesAutoresizingMaskIntoConstraints = NO;
     [view addSubview:self.someView];
     
     NSDictionary *parameters = @{ @"view" : self.someView };
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view.left = 10" parameters:parameters]];
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view.top = 10" parameters:parameters]];
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view.width = 200" parameters:parameters]];
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view.width = 44" parameters:parameters]];

Note the `parameters` dictionary, which exposes views to the expression processor.

### Variables in Parameter Dictionaries

In addition to putting views in the parameters dictionary, you can put NSNumber objects in.

     NSDictionary *parameters = @{ @"view" : self.someView, @"margin" : @10 };
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view.left = margin" parameters:parameters]];
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view.top = margin" parameters:parameters]];

### Multiple Views

You can reference multiple views within an expression.

     NSDictionary *parameters = @{ @"view1" : self.someView, @"view2" : self.someOtherView };
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view2.left = view1.right + 10"]];

### Superview

The expression format specially handles references to `superview`. If it encounters `superview`, it will use the superview of the view on the left side of the expression.

     NSDictionary *parameters = @{ @"view" : self.someView };
     [view addConstraint:[NSLayoutConstraint constraintWithExpressionFormat:@"view.centerX = superview.centerX" parameters:parameters]];