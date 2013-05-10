# NSLayoutConstraint+ExpressionFormat

## Installation

## Contributing
Please feel free to [fork the code](https://github.com/enderlabs/NSLayoutConstraint-ExpressionFormat), and submit pull requests for any new features or fixes.

## Usage

Auto Layout uses a series of linear equations as constraints to determine the size and position of views. This category allows you to declare these equations in a straightforward, string-based syntax.

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